import XCTest
@testable import ZSALayoutOverlay

@MainActor
final class MenuBarControllerTests: XCTestCase {

    func test_statusItemUsesKeyboardSymbol() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        XCTAssertNotNil(m.statusItemButton)
        XCTAssertNotNil(m.statusItemButton?.image)
    }

    func test_menuHasFiveItems() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        XCTAssertEqual(m.menu.items.count, 5)
    }

    func test_firstMenuItemIsShowHide() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        let item = m.menu.items[0]
        XCTAssertEqual(item.title, "Hide Overlay")
        XCTAssertNotNil(item.action)
    }

    func test_secondMenuItemIsPreferences() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        let item = m.menu.items[1]
        XCTAssertEqual(item.title, "Preferences...")
        XCTAssertEqual(item.keyEquivalent, ",")
    }

    func test_thirdMenuItemIsRestart() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        let item = m.menu.items[2]
        XCTAssertEqual(item.title, "Restart")
        XCTAssertEqual(item.keyEquivalent, "r")
    }

    func test_fourthMenuItemIsSeparator() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        XCTAssertTrue(m.menu.items[3].isSeparatorItem)
    }

    func test_fifthMenuItemIsQuit() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        let item = m.menu.items[4]
        XCTAssertEqual(item.title, "Quit")
        XCTAssertEqual(item.keyEquivalent, "q")
    }

    func test_toggleOverlayInitiallyHides() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        XCTAssertEqual(m.showHideItemTitle, "Hide Overlay")
        m.toggleOverlay()
        XCTAssertEqual(m.showHideItemTitle, "Show Overlay")
    }

    func test_restartAppResetsVisibility() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        m.toggleOverlay()
        m.restartApp()
        XCTAssertEqual(m.showHideItemTitle, "Hide Overlay")
    }

    func test_appDelegateCreatesMenuBarController() {
        let d = AppDelegate()
        d.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        XCTAssertNotNil(d.menuBarControllerForTest)
    }

    func test_appDelegateDoesNotTerminateAfterLastWindowClosed() {
        XCTAssertFalse(AppDelegate().applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared))
    }
}
