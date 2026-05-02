import AppKit
import SwiftUI

@MainActor
final class OverlayAppController {
    private let model: OverlayViewModel
    private var keymappProbe = KeymappProbeDataSource()
    private var captureDataSource: KeyboardDataSource?
    private var liveDataSource: KeyboardDataSource
    private var windowController: OverlayWindowController?
    private var activeTask: Task<Void, Never>?

    init(keyboard: KeyboardDefinition = KeyboardRegistry.default) {
        self.model = OverlayViewModel(keyboard: keyboard)
        if let harPath = Self.resolvedHARPath() {
            captureDataSource = OryxHARDataSource(harPath: harPath)
            liveDataSource = ZSAHIDDataSource(hidProfile: keyboard.hidProfile)
        } else {
            captureDataSource = nil
            liveDataSource = MockKeyboardDataSource()
        }
    }

    private static func resolvedHARPath() -> String? {
        let environmentHARPath = ProcessInfo.processInfo.environment["ZSA_LAYOUT_HAR"]
        let bundleHARPath = Bundle.main.path(forResource: "typ.ing", ofType: "har")
        let sharedHARPath = "/Users/Shared/typ.ing.har"

        for candidate in [environmentHARPath, bundleHARPath, sharedHARPath] {
            guard let candidate else { continue }
            if FileManager.default.fileExists(atPath: candidate) {
                return candidate
            }
        }

        return nil
    }

    func start() {
        windowController = OverlayWindowController(model: model)
        windowController?.showWindow()

        activeTask = Task {
            keymappProbe.onError = { [weak model] state in
                model?.reportError(state)
            }
            captureDataSource?.onError = { [weak model] state in
                model?.reportError(state)
            }
            liveDataSource.onError = { [weak model] state in
                model?.reportError(state)
            }
            await keymappProbe.start(feeding: model)
            await captureDataSource?.start(feeding: model)
            await liveDataSource.start(feeding: model)
        }
    }

    func showWindow() {
        windowController?.showWindow()
    }

    func hideWindow() {
        windowController?.hideWindow()
    }

    func restart() {
        activeTask?.cancel()
        activeTask = nil
        windowController?.hideWindow()
        windowController = nil
        model.reset()

        if let harPath = Self.resolvedHARPath() {
            captureDataSource = OryxHARDataSource(harPath: harPath)
            liveDataSource = ZSAHIDDataSource(hidProfile: KeyboardRegistry.default.hidProfile)
        } else {
            captureDataSource = nil
            liveDataSource = MockKeyboardDataSource()
        }

        start()
    }
}

@MainActor
final class OverlayWindowController {
    private let window: NSWindow

    init(model: OverlayViewModel) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let contentSize = NSSize(
            width: min(DesignTokens.Layout.preferredHUDWidth, max(DesignTokens.Layout.minHUDWidth, screen.width - 72)),
            height: min(DesignTokens.Layout.preferredHUDHeight, max(DesignTokens.Layout.minHUDHeight, screen.height * 0.36))
        )
        let origin = CGPoint(
            x: screen.midX - (contentSize.width / 2),
            y: screen.minY + 2
        )
        let frame = NSRect(origin: origin, size: contentSize)

        let view = OverlayRootView(model: model)
        let hostingView = NSHostingView(rootView: view)

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.sharingType = .none
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isMovableByWindowBackground = false
        window.setContentSize(contentSize)
        window.orderFrontRegardless()

        self.window = window
    }

    func showWindow() {
        window.orderFrontRegardless()
    }

    func hideWindow() {
        window.orderOut(nil)
    }
}
