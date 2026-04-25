import Foundation
import ZSAHIDBridge

final class ZSAHIDDataSource: KeyboardDataSource, @unchecked Sendable {
    var onError: ((ErrorState) -> Void)?
    private let eventLoggingEnabled = false
    private let voyagerMatrix: [[Int]] = [
        [-1, 0, 1, 2, 3, 4, 5],
        [-1, 6, 7, 8, 9, 10, 11],
        [-1, 12, 13, 14, 15, 16, 17],
        [-1, 18, 19, 20, 21, 22],
        [-1, -1, -1, -1, 23],
        [24, 25],
        [26, 27, 28, 29, 30, 31],
        [32, 33, 34, 35, 36, 37],
        [38, 39, 40, 41, 42, 43],
        [-1, 45, 46, 47, 48, 49],
        [-1, -1, 44, -1, -1, -1, -1],
        [-1, -1, -1, -1, -1, 50, 51]
    ]

    private weak var model: OverlayViewModel?
    private typealias BridgeRef = UnsafeMutableRawPointer
    private var bridge: BridgeRef?
    private var activeLayerIndex = 0
    private var pressedKeyIndices: Set<Int> = []

    @MainActor
    func start(feeding model: OverlayViewModel) async {
        self.model = model
        log("Starting hidapi live bridge")
        await setStatus(connectionState: "waiting for voyager", statusText: "Waiting for a ZSA Voyager hidapi connection.")

        guard let bridge else {
            let opened = zsa_hid_bridge_open_first_voyager()
            guard let opened else {
                await setStatus(connectionState: "bridge init failed", statusText: "Failed to initialize hidapi bridge.")
                await reportError(.error("Failed to initialize hidapi bridge"))
                return
            }
            self.bridge = opened
            log("Opened Voyager hidapi bridge")
            if zsa_hid_bridge_write_command(opened, 0) < 0 {
                log("Handshake [0] failed: \(lastError(from: opened))")
            }
            if zsa_hid_bridge_write_command(opened, 1) < 0 {
                log("Handshake [1] failed: \(lastError(from: opened))")
            }
            logInitialFeatureReports(from: opened)
            await setStatus(connectionState: "voyager connected", statusText: "Voyager connected through hidapi. Listening for live reports.")
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
                await setStatus(connectionState: "streaming live state", statusText: "Voyager connected. Layout descriptor \(descriptor).")
            }
        case 5:
            guard let layer = bytes.first else { return }
            activeLayerIndex = Int(layer)
            if eventLoggingEnabled {
                log("Layer -> \(activeLayerIndex)")
            }
            await pushLiveState()
        case 6:
            guard let keyIndex = decodeKeyIndex(from: bytes) else {
                log("Key down payload undecoded: \(hexDump(report))")
                return
            }
            pressedKeyIndices.insert(keyIndex)
            if eventLoggingEnabled {
                log("Key down -> physical index \(keyIndex)")
            }
            await pushLiveState()
        case 7:
            guard let keyIndex = decodeKeyIndex(from: bytes) else {
                log("Key up payload undecoded: \(hexDump(report))")
                return
            }
            pressedKeyIndices.remove(keyIndex)
            if eventLoggingEnabled {
                log("Key up -> physical index \(keyIndex)")
            }
            await pushLiveState()
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
        guard row >= 0, row < voyagerMatrix.count else { return nil }
        guard column >= 0, column < voyagerMatrix[row].count else { return nil }
        let index = voyagerMatrix[row][column]
        guard index >= 0, index < OverlayLayouts.voyagerPhysicalKeyCount else { return nil }
        return index
    }

    private func pushLiveState() async {
        let activeLayerIndex = activeLayerIndex
        let pressedKeyIndices = pressedKeyIndices
        let statusText = "Voyager connected. Layer \(activeLayerIndex) with \(pressedKeyIndices.count) pressed key(s)."

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
            log("Feature[\(reportID)] -> \(hexDump(Array(buffer.prefix(Int(count)))))")
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
