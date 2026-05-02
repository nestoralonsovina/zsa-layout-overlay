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
    private var downloadsTask: Task<Void, Never>?
    private var lastMainScreen: NSScreen?
    private var knownHARFiles = Set<String>()

    init(keyboard: KeyboardDefinition = KeyboardRegistry.default) {
        self.model = OverlayViewModel(keyboard: keyboard)
        self.captureDataSource = Self.resolveCaptureSource()
        if Self.resolvedHARPath() != nil || PreferencesStore.shared.layoutURL != nil {
            liveDataSource = ZSAHIDDataSource(hidProfile: keyboard.hidProfile)
        } else {
            liveDataSource = MockKeyboardDataSource()
        }
    }

    private static func resolveCaptureSource() -> KeyboardDataSource? {
        if let url = PreferencesStore.shared.layoutURL, let source = apiSource(from: url) {
            return source
        }
        if let harPath = resolvedHARPath() {
            return OryxHARDataSource(harPath: harPath)
        }
        return nil
    }

    private static func apiSource(from url: String) -> OryxAPIDataSource? {
        // Parse share URL: https://configure.zsa.io/voyager/layouts/LmpYy/latest
        if let parsed = parseShareURL(url) {
            return OryxAPIDataSource(
                layoutHashId: parsed.hashId,
                geometry: parsed.geometry,
                revisionId: parsed.revisionId
            )
        }
        // Treat as raw hash ID
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return OryxAPIDataSource(
            layoutHashId: trimmed,
            geometry: KeyboardRegistry.default.geometry.name.lowercased(),
            revisionId: "latest"
        )
    }

    private static func parseShareURL(_ url: String) -> (hashId: String, geometry: String, revisionId: String)? {
        // Match: .../layouts/{hashId}/{revisionId}
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

        // Extract geometry from URL path like /voyager/layouts/...
        let geometry = url.contains("/voyager") ? "voyager" :
                       url.contains("/moonlander") ? "moonlander" :
                       url.contains("/ergodox") ? "ergodox_ez" :
                       "voyager"

        guard hashId.count >= 3 else { return nil }
        return (hashId, geometry, revisionId)
    }

    private static func resolvedHARPath() -> String? {
        let prefs = PreferencesStore.shared
        let environmentHARPath = ProcessInfo.processInfo.environment["ZSA_LAYOUT_HAR"]
        let bundleHARPath = Bundle.main.path(forResource: "typ.ing", ofType: "har")
        let sharedHARPath = "/Users/Shared/typ.ing.har"

        for candidate in [prefs.harFilePath, environmentHARPath, bundleHARPath, sharedHARPath] {
            guard let candidate else { continue }
            if FileManager.default.fileExists(atPath: candidate) {
                return candidate
            }
        }

        return nil
    }

    func start() {
        let targetScreen = currentTargetScreen()
        lastMainScreen = targetScreen
        windowController = OverlayWindowController(model: model, screen: targetScreen)
        windowController?.showWindow()

        observeScreenChanges()
        startDownloadsWatcher()

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

    // MARK: - HAR Auto-Detection

    private func startDownloadsWatcher() {
        let downloadsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads")

        downloadsTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let harFiles = try? FileManager.default
                    .contentsOfDirectory(atPath: downloadsURL.path)
                    .filter({ $0.hasSuffix(".har") })
                else { continue }

                let fullPaths = Set(harFiles.map { downloadsURL.appendingPathComponent($0).path })
                let newFiles = fullPaths.subtracting(self?.knownHARFiles ?? [])
                self?.knownHARFiles = fullPaths

                if let newestPath = newFiles.first {
                    // Pick the most recently added (by filename, not reliable; just take any new one)
                    let prefs = PreferencesStore.shared
                    if prefs.harFilePath != newestPath {
                        prefs.harFilePath = newestPath
                    }
                }

                try? await Task.sleep(for: .seconds(10))
            }
        }
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
        downloadsTask?.cancel()
        downloadsTask = nil
        windowController?.hideWindow()
        windowController = nil
        lastMainScreen = nil
        model.reset()

        captureDataSource = Self.resolveCaptureSource()
        if captureDataSource != nil {
            liveDataSource = ZSAHIDDataSource(hidProfile: KeyboardRegistry.default.hidProfile)
        } else {
            liveDataSource = MockKeyboardDataSource()
        }

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
