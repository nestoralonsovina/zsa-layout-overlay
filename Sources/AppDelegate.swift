import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appController: OverlayAppController?
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = OverlayAppController()
        appController = controller
        controller.start()

        menuBarController = MenuBarController(appController: controller)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Test Helpers

    var menuBarControllerForTest: MenuBarController? { menuBarController }
}
