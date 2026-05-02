import Foundation
import ZSAHIDBridge

final class ZSAHIDDataSource: KeyboardDataSource, @unchecked Sendable {
    var onError: ((ErrorState) -> Void)?
    private let eventLoggingEnabled = false
    private let hidProfile: HIDDeviceProfile?

    private weak var model: OverlayViewModel?
    private typealias BridgeRef = UnsafeMutableRawPointer
    private var bridge: BridgeRef?
    private var activeLayerIndex = 0
    private var pressedKeyIndices: Set<Int> = []

    init(hidProfile: HIDDeviceProfile?) {
        self.hidProfile = hidProfile
    }

    @MainActor
    func start(feeding model: OverlayViewModel) async {
        self.model = model
        log("Starting hidapi live bridge")
        guard hidProfile != nil else {
            await setStatus(connectionState: "no hid profile", statusText: "No HID profile configured for this keyboard.")
            await reportError(.warning("No HID profile configured"))
            return
        }
        await setStatus(connectionState: "waiting for device", statusText: "Waiting for a ZSA device hidapi connection.")

        guard let bridge else {
            let opened = zsa_hid_bridge_open_first_voyager()
            guard let opened else {
                await setStatus(connectionState: "bridge init failed", statusText: "Failed to initialize hidapi bridge.")
                await reportError(.error("Failed to initialize hidapi bridge"))
                return
            }
            self.bridge = opened
            log("Opened hidapi bridge")
            if zsa_hid_bridge_write_command(opened, 0) < 0 {
                log("Handshake [0] failed: \(lastError(from: opened))")
            }
            if zsa_hid_bridge_write_command(opened, 1) < 0 {
                log("Handshake [1] failed: \(lastError(from: opened))")
            }
            logInitialFeatureReports(from: opened)
            await setStatus(connectionState: "device connected", statusText: "Device connected through hidapi. Listening for live reports.")
            await reportError(.none)
            await runReadLoop(using: opened)
            return
        }

        await runReadLoop(using: bridge)
    }

    private func runReadLoop(using bridge: BridgeRef) async {
        let bridgeAddress = UInt(bitPattern: bridge)
        let readTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await self.readLoop(usingBridgeAddress: bridgeAddress)
        }

        await withTaskCancellationHandler {
            await readTask.value
        } onCancel: {
            readTask.cancel()
        }
    }

    private func readLoop(usingBridgeAddress bridgeAddress: UInt) async {
        guard let bridge = UnsafeMutableRawPointer(bitPattern: bridgeAddress) else { return }

        while !Task.isCancelled {
            var buffer = Array(repeating: UInt8(0), count: 32)
            let count = buffer.withUnsafeMutableBufferPointer { pointer in
                zsa_hid_bridge_read_timeout(bridge, pointer.baseAddress, Int32(pointer.count), 10)
            }

            if count < 0 {
                let message = lastError(from: bridge)
                log("Read failed: \(message)")
                await setStatus(connectionState: "read failed", statusText: "hidapi read failed: \(message)")
                await reportError(.error("hidapi read failed: \(message)"))
                break
            }

            guard count > 0 else {
                await Task.yield()
                continue
            }

            await handle(report: Array(buffer.prefix(Int(count))))
        }
    }

    private func handle(report: [UInt8]) async {
        let payload = trimmedPayload(from: report)
        guard let opcode = payload.first else { return }
        let bytes = Array(payload.dropFirst())

        switch opcode {
        case 0:
            if let descriptor = String(bytes: bytes, encoding: .utf8) {
                log("Descriptor -> \(descriptor)")
                await setStatus(connectionState: "streaming live state", statusText: "Device connected. Layout descriptor \(descriptor).")
            }
        case 5:
            guard let layer = bytes.first else { return }
            let newLayer = Int(layer)
            guard newLayer != activeLayerIndex else { return }
            activeLayerIndex = newLayer
            if eventLoggingEnabled {
                log("Layer -> \(activeLayerIndex)")
            }
            await pushLiveState()
        case 6:
            guard let keyIndex = decodeKeyIndex(from: bytes) else {
                log("Key down payload undecoded: \(hexDump(report))")
                return
            }
            let changed = pressedKeyIndices.insert(keyIndex).inserted
            if eventLoggingEnabled {
                log("Key down -> physical index \(keyIndex)")
            }
            if changed {
                await pushLiveState()
            }
        case 7:
            guard let keyIndex = decodeKeyIndex(from: bytes) else {
                log("Key up payload undecoded: \(hexDump(report))")
                return
            }
            let changed = pressedKeyIndices.remove(keyIndex) != nil
            if eventLoggingEnabled {
                log("Key up -> physical index \(keyIndex)")
            }
            if changed {
                await pushLiveState()
            }
        default:
            if eventLoggingEnabled {
                log("Unhandled report -> \(hexDump(report))")
            }
        }
    }

    private func trimmedPayload(from report: [UInt8]) -> [UInt8] {
        if let end = report.firstIndex(of: 0xFE) {
            return Array(report.prefix(upTo: end))
        }
        return report
    }

    private func decodeKeyIndex(from bytes: [UInt8]) -> Int? {
        guard bytes.count >= 2 else { return nil }
        return matrixIndex(row: Int(bytes[1]), column: Int(bytes[0]))
    }

    private func matrixIndex(row: Int, column: Int) -> Int? {
        guard let profile = hidProfile else { return nil }
        guard row >= 0, row < profile.keyMatrix.count else { return nil }
        guard column >= 0, column < profile.keyMatrix[row].count else { return nil }
        let index = profile.keyMatrix[row][column]
        guard index >= 0, index < profile.physicalKeyCount else { return nil }
        return index
    }

    private func pushLiveState() async {
        let activeLayerIndex = activeLayerIndex
        let pressedKeyIndices = pressedKeyIndices
        let statusText = "Device connected. Layer \(activeLayerIndex) with \(pressedKeyIndices.count) pressed key(s)."

        await MainActor.run {
            model?.applyLiveState(
                KeyboardLiveState(
                    sourceName: "zsa-hidapi",
                    connectionState: "streaming live state",
                    activeLayerIndex: activeLayerIndex,
                    pressedKeyIndices: pressedKeyIndices,
                    statusText: statusText
                )
            )
        }
    }

    private func setStatus(connectionState: String, statusText: String) async {
        await MainActor.run {
            model?.applyStatus(sourceName: "zsa-hidapi", connectionState: connectionState, statusText: statusText)
        }
    }

    private func reportError(_ state: ErrorState) async {
        await MainActor.run {
            onError?(state)
        }
    }

    private func logInitialFeatureReports(from bridge: BridgeRef) {
        for reportID: UInt8 in 0...3 {
            var buffer = Array(repeating: UInt8(0), count: 33)
            let count = buffer.withUnsafeMutableBufferPointer { pointer in
                zsa_hid_bridge_get_feature_report(bridge, reportID, pointer.baseAddress, Int32(pointer.count))
            }
            guard count > 0 else { continue }
            log("Feature[\(reportID)] -> \(hexDump(Array(buffer.prefix(Int(count)))))"
            )
        }
    }

    private func lastError(from bridge: BridgeRef) -> String {
        guard let raw = zsa_hid_bridge_last_error(bridge) else {
            return "unknown error"
        }
        return String(cString: raw)
    }

    private func hexDump(_ bytes: [UInt8]) -> String {
        if bytes.isEmpty {
            return "<empty>"
        }
        return bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    private func log(_ message: String) {
        fputs("[ZSAHID] \(message)\n", stderr)
    }
}
