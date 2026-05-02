import AppKit
import Combine
import UniformTypeIdentifiers

@MainActor
final class MenuBarController {
    private let appController: OverlayAppController
    private let statusItem: NSStatusItem
    private let showHideItem: NSMenuItem
    private var isOverlayVisible: Bool = true
    private let preferencesController = PreferencesWindowController()
    private var cancellables = Set<AnyCancellable>()

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

        let importItem = NSMenuItem(
            title: "Import Layout...",
            action: #selector(_importLayout),
            keyEquivalent: "i"
        )
        importItem.target = self

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
        menu.addItem(importItem)
        menu.addItem(preferencesItem)
        menu.addItem(restartItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        statusItem.menu = menu

        observePreferences()
    }

    private func observePreferences() {
        PreferencesStore.shared.objectWillChange
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.performRestart()
            }
            .store(in: &cancellables)
    }

    private func performRestart() {
        appController.restart()
        isOverlayVisible = true
        showHideItem.title = "Hide Overlay"
    }

    // MARK: - Import Layout

    @objc private func _importLayout() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "Import Oryx Layout"
        panel.message = "Select the .har file exported from Oryx"
        if let harType = UTType(filenameExtension: "har") {
            panel.allowedContentTypes = [harType]
        } else {
            panel.allowedContentTypes = [.init(filenameExtension: "har")!]
        }

        panel.begin { [weak self] result in
            guard result == .OK, let url = panel.url else { return }
            PreferencesStore.shared.harFilePath = url.path
        }
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
