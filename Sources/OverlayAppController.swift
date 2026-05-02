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
    private var lastMainScreen: NSScreen?

    init(keyboard: KeyboardDefinition = KeyboardRegistry.default) {
        self.model = OverlayViewModel(keyboard: keyboard)
        self.captureDataSource = Self.resolveCaptureSource()
        self.liveDataSource = captureDataSource != nil
            ? ZSAHIDDataSource(hidProfile: keyboard.hidProfile)
            : MockKeyboardDataSource()
    }

    private static func resolveCaptureSource() -> KeyboardDataSource? {
        guard let url = PreferencesStore.shared.layoutURL else { return nil }
        return apiSource(from: url)
    }

    private static func apiSource(from url: String) -> OryxAPIDataSource? {
        if let parsed = parseShareURL(url) {
            return OryxAPIDataSource(
                layoutHashId: parsed.hashId,
                geometry: parsed.geometry,
                revisionId: parsed.revisionId
            )
        }
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return OryxAPIDataSource(
            layoutHashId: trimmed,
            geometry: KeyboardRegistry.default.geometry.name.lowercased(),
            revisionId: "latest"
        )
    }

    private static func parseShareURL(_ url: String) -> (hashId: String, geometry: String, revisionId: String)? {
        let pattern = #"layouts/([^/]+)(?:/([^/]+))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)) else {
            return nil
        }

        guard let hashRange = Range(match.range(at: 1), in: url) else { return nil }
        let hashId = String(url[hashRange])

        let revisionId: String
        if let revRange = Range(match.range(at: 2), in: url) {
            revisionId = String(url[revRange])
        } else {
            revisionId = "latest"
        }

        let geometry = url.contains("/voyager") ? "voyager" :
                       url.contains("/moonlander") ? "moonlander" :
                       url.contains("/ergodox") ? "ergodox_ez" :
                       "voyager"

        guard hashId.count >= 3 else { return nil }
        return (hashId, geometry, revisionId)
    }

    func start() {
        let targetScreen = currentTargetScreen()
        lastMainScreen = targetScreen
        windowController = OverlayWindowController(model: model, screen: targetScreen)
        windowController?.showWindow()

        observeScreenChanges()

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

    // MARK: - Screen Following

    private func observeScreenChanges() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.repositionToFocusedScreenIfNeeded()
            }
        }
    }

    private func currentTargetScreen() -> NSScreen {
        if PreferencesStore.shared.followFocusedScreen {
            if let mainScreen = NSScreen.main {
                return mainScreen
            }
        }
        return NSScreen.main ?? fallbackScreen()
    }

    private func repositionToFocusedScreenIfNeeded() {
        guard PreferencesStore.shared.followFocusedScreen else { return }
        let targetScreen = currentTargetScreen()
        guard targetScreen != lastMainScreen else { return }
        lastMainScreen = targetScreen
        windowController?.reposition(on: targetScreen)
    }

    private func fallbackScreen() -> NSScreen {
        NSScreen.screens.first ?? NSScreen()
    }

    // MARK: - Window Control

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
        lastMainScreen = nil
        model.reset()

        captureDataSource = Self.resolveCaptureSource()
        liveDataSource = captureDataSource != nil
            ? ZSAHIDDataSource(hidProfile: KeyboardRegistry.default.hidProfile)
            : MockKeyboardDataSource()

        start()
    }
}

@MainActor
final class OverlayWindowController {
    private let window: NSWindow

    init(model: OverlayViewModel, screen: NSScreen) {
        let screenFrame = screen.visibleFrame
        let prefs = PreferencesStore.shared
        let contentSize = NSSize(
            width: min(DesignTokens.Layout.preferredHUDWidth * prefs.scaleMultiplier, max(DesignTokens.Layout.minHUDWidth * prefs.scaleMultiplier, screenFrame.width - 72)),
            height: min(DesignTokens.Layout.preferredHUDHeight * prefs.scaleMultiplier, max(DesignTokens.Layout.minHUDHeight * prefs.scaleMultiplier, screenFrame.height * 0.36))
        )
        let origin = Self.originFor(screenFrame: screenFrame, contentSize: contentSize, positionX: prefs.positionX, positionY: prefs.positionY)
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

    func reposition(on screen: NSScreen) {
        let screenFrame = screen.visibleFrame
        let contentSize = window.frame.size
        let prefs = PreferencesStore.shared
        let origin = Self.originFor(screenFrame: screenFrame, contentSize: contentSize, positionX: prefs.positionX, positionY: prefs.positionY)
        window.setFrameOrigin(origin)
    }

    private static func originFor(screenFrame: CGRect, contentSize: CGSize, positionX: Double, positionY: Double) -> CGPoint {
        let xRange = max(screenFrame.width - contentSize.width, 0)
        let yRange = max(screenFrame.height - contentSize.height, 0)
        return CGPoint(
            x: screenFrame.minX + xRange * positionX,
            y: screenFrame.minY + yRange * positionY
        )
    }

    func showWindow() {
        window.orderFrontRegardless()
    }

    func hideWindow() {
        window.orderOut(nil)
    }
}
