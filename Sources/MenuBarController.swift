import AppKit

@MainActor
final class MenuBarController {
    private let appController: OverlayAppController
    private let statusItem: NSStatusItem
    private let showHideItem: NSMenuItem
    private var isOverlayVisible = true
    private let preferencesController = PreferencesWindowController()
    private var visualApplyWorkItem: DispatchWorkItem?
    private var layoutReloadWorkItem: DispatchWorkItem?

    init(appController: OverlayAppController) {
        self.appController = appController

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "keyboard",
                accessibilityDescription: "ZSA Layout Overlay"
            )
        }

        showHideItem = NSMenuItem(
            title: "Hide Overlay",
            action: #selector(_toggleOverlay),
            keyEquivalent: ""
        )
        showHideItem.target = self

        let preferencesItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(_showPreferences),
            keyEquivalent: ","
        )
        preferencesItem.target = self

        let restartItem = NSMenuItem(
            title: "Restart",
            action: #selector(_restartApp),
            keyEquivalent: "r"
        )
        restartItem.target = self

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self

        let menu = NSMenu()
        menu.addItem(showHideItem)
        menu.addItem(preferencesItem)
        menu.addItem(restartItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        statusItem.menu = menu

        setupPreferencesObserver()
    }

    private func setupPreferencesObserver() {
        PreferencesStore.shared.onVisualChange = { [weak self] in
            guard let self else { return }
            visualApplyWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.appController.applyVisualPreferences()
            }
            visualApplyWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
        }

        PreferencesStore.shared.onLayoutChange = { [weak self] in
            guard let self else { return }
            layoutReloadWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.appController.reloadCaptureSource()
            }
            layoutReloadWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        }
    }

    private func performRestart() {
        appController.restart()
        isOverlayVisible = true
        showHideItem.title = "Hide Overlay"
    }

    @objc private func _toggleOverlay() {
        if isOverlayVisible {
            appController.hideWindow()
            showHideItem.title = "Show Overlay"
        } else {
            appController.showWindow()
            showHideItem.title = "Hide Overlay"
        }
        isOverlayVisible.toggle()
    }

    @objc private func _showPreferences() {
        preferencesController.show()
    }

    @objc private func _restartApp() {
        performRestart()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Test Helpers

    var statusItemButton: NSStatusBarButton? { statusItem.button }
    var menu: NSMenu { statusItem.menu! }
    var showHideItemTitle: String { showHideItem.title }

    func toggleOverlay() {
        _toggleOverlay()
    }

    func restartApp() {
        _restartApp()
    }
}
