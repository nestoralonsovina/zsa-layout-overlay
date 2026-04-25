import AppKit
import SwiftUI

@MainActor
final class OverlayAppController {
    private let model = OverlayViewModel()
    private let keymappProbe = KeymappProbeDataSource()
    private let captureDataSource: KeyboardDataSource?
    private let liveDataSource: KeyboardDataSource
    private var windowController: OverlayWindowController?

    init() {
        if let harPath = Self.resolvedHARPath() {
            captureDataSource = OryxHARDataSource(harPath: harPath)
            liveDataSource = ZSAHIDDataSource()
        } else {
            captureDataSource = nil
            liveDataSource = MockKeyboardDataSource()
        }
    }

    private static func resolvedHARPath() -> String? {
        let environmentHARPath = ProcessInfo.processInfo.environment["ZSA_LAYOUT_HAR"]
        let bundleHARPath = Bundle.main.path(forResource: "typ.ing", ofType: "har")
        let sharedHARPath = "/Users/Shared/typ.ing.har"
        let userDownloadsHARPath = NSHomeDirectory() + "/Downloads/typ.ing.har"

        for candidate in [environmentHARPath, bundleHARPath, sharedHARPath, userDownloadsHARPath] {
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

        Task {
            await keymappProbe.start(feeding: model)
            await captureDataSource?.start(feeding: model)
            await liveDataSource.start(feeding: model)
        }
    }
}

@MainActor
final class OverlayWindowController {
    private let window: NSWindow
    private let contentSize = NSSize(width: 700, height: 250)

    init(model: OverlayViewModel) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = CGPoint(
            x: screen.midX - (contentSize.width / 2),
            y: screen.minY + 18
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
}
