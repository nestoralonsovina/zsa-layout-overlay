import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appController: OverlayAppController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        appController = OverlayAppController()
        appController?.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
