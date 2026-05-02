import XCTest
@testable import ZSALayoutOverlay

@MainActor
final class MenuBarControllerTests: XCTestCase {

    func test_statusItemUsesKeyboardSymbol() {
        let app = OverlayAppController(keyboard: KeyboardRegistry.default)
        let m = MenuBarController(appController: app)
        XCTAssertNotNil(m.statusItemButton)
        XCTAssertNotNil(m.statusItemButton?.image)
    }

    func test_menuHasSixItemsIncludingSeparator() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        XCTAssertEqual(m.menu.items.count, 6)
    }

    func test_firstMenuItemIsShowHide() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        let item = m.menu.items[0]
        XCTAssertEqual(item.title, "Hide Overlay")
        XCTAssertNotNil(item.action)
        XCTAssert(item.target is MenuBarController)
    }

    func test_secondMenuItemIsImportLayout() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        let item = m.menu.items[1]
        XCTAssertEqual(item.title, "Import Layout...")
        XCTAssertEqual(item.keyEquivalent, "i")
        XCTAssertNotNil(item.action)
    }

    func test_thirdMenuItemIsPreferences() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        let item = m.menu.items[2]
        XCTAssertEqual(item.title, "Preferences...")
        XCTAssertEqual(item.keyEquivalent, ",")
        XCTAssertNotNil(item.action)
    }

    func test_fourthMenuItemIsRestart() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        let item = m.menu.items[3]
        XCTAssertEqual(item.title, "Restart")
        XCTAssertEqual(item.keyEquivalent, "r")
        XCTAssertNotNil(item.action)
    }

    func test_fifthMenuItemIsSeparator() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        XCTAssertTrue(m.menu.items[4].isSeparatorItem)
    }

    func test_sixthMenuItemIsQuit() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        let item = m.menu.items[5]
        XCTAssertEqual(item.title, "Quit")
        XCTAssertEqual(item.keyEquivalent, "q")
        XCTAssertNotNil(item.action)
    }

    func test_toggleOverlayInitiallyHides() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        XCTAssertEqual(m.showHideItemTitle, "Hide Overlay")
        m.toggleOverlay()
        XCTAssertEqual(m.showHideItemTitle, "Show Overlay")
    }

    func test_toggleOverlayTogglesBackToShow() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        m.toggleOverlay()
        XCTAssertEqual(m.showHideItemTitle, "Show Overlay")
        m.toggleOverlay()
        XCTAssertEqual(m.showHideItemTitle, "Hide Overlay")
    }

    func test_toggleOverlayIsIdempotentOverMultipleCycles() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        for _ in 0..<4 { m.toggleOverlay() }
        XCTAssertEqual(m.showHideItemTitle, "Hide Overlay")
    }

    func test_restartAppResetsVisibilityToHideOverlay() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
        m.toggleOverlay()
        m.restartApp()
        XCTAssertEqual(m.showHideItemTitle, "Hide Overlay")
    }

    func test_restartAppFromVisibleStateKeepsHideOverlayTitle() {
        let m = MenuBarController(appController: OverlayAppController(keyboard: KeyboardRegistry.default))
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
