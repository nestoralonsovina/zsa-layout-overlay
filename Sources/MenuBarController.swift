import AppKit

@MainActor
final class MenuBarController {
    private let appController: OverlayAppController
    private let statusItem: NSStatusItem
    private let showHideItem: NSMenuItem
    private var isOverlayVisible: Bool = true
    private let preferencesController = PreferencesWindowController()

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
        appController.restart()
        isOverlayVisible = true
        showHideItem.title = "Hide Overlay"
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Test Helpers

    var statusItemButton: NSStatusBarButton? { statusItem.button }
    var menu: NSMenu { statusItem.menu! }
    var showHideItemTitle: String { showHideItem.title }

    // Exposed for test invocation of private @objc methods
    func toggleOverlay() {
        _toggleOverlay()
    }

    func restartApp() {
        _restartApp()
    }
}
