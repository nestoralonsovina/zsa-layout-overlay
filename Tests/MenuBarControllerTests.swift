import XCTest
@testable import ZSALayoutOverlay

@MainActor
final class MenuBarControllerTests: XCTestCase {

    // MARK: - Status Item Symbol

    func test_statusItemUsesKeyboardSymbol() {
        let appController = OverlayAppController(keyboard: KeyboardRegistry.default)
        let menuBarController = MenuBarController(appController: appController)

        let button = menuBarController.statusItemButton
        XCTAssertNotNil(button, "Status item should have a button")
        XCTAssertNotNil(button?.image, "Button should have an image set")
    }

    // MARK: - Menu Structure

    func test_menuHasFiveItemsIncludingSeparator() {
        let appController = OverlayAppController(keyboard: KeyboardRegistry.default)
        let menuBarController = MenuBarController(appController: appController)

        let menu = menuBarController.menu
        XCTAssertEqual(menu.items.count, 5, "Menu should have 5 items: Show/Hide, Preferences, Restart, separator, Quit")
    }

    func test_firstMenuItemIsShowHide() {
        let appController = OverlayAppController(keyboard: KeyboardRegistry.default)
        let menuBarController = MenuBarController(appController: appController)

        let firstItem = menuBarController.menu.items[0]
        XCTAssertEqual(firstItem.title, "Hide Overlay")
        XCTAssertNotNil(firstItem.action, "Show/Hide item should have an action")
        XCTAssert(firstItem.target is MenuBarController)
    }

    func test_secondMenuItemIsPreferences() {
        let appController = OverlayAppController(keyboard: KeyboardRegistry.default)
        let menuBarController = MenuBarController(appController: appController)

        let secondItem = menuBarController.menu.items[1]
        XCTAssertEqual(secondItem.title, "Preferences...")
        XCTAssertEqual(secondItem.keyEquivalent, ",")
        XCTAssertNotNil(secondItem.action)
        XCTAssert(secondItem.target is MenuBarController)
    }

    func test_thirdMenuItemIsRestart() {
        let appController = OverlayAppController(keyboard: KeyboardRegistry.default)
        let menuBarController = MenuBarController(appController: appController)

        let thirdItem = menuBarController.menu.items[2]
        XCTAssertEqual(thirdItem.title, "Restart")
        XCTAssertEqual(thirdItem.keyEquivalent, "r")
        XCTAssertNotNil(thirdItem.action)
        XCTAssert(thirdItem.target is MenuBarController)
    }

    func test_fourthMenuItemIsSeparator() {
        let appController = OverlayAppController(keyboard: KeyboardRegistry.default)
        let menuBarController = MenuBarController(appController: appController)

        let fourthItem = menuBarController.menu.items[3]
        XCTAssertTrue(fourthItem.isSeparatorItem, "Fourth item should be a separator")
    }

    func test_fifthMenuItemIsQuit() {
        let appController = OverlayAppController(keyboard: KeyboardRegistry.default)
        let menuBarController = MenuBarController(appController: appController)

        let fifthItem = menuBarController.menu.items[4]
        XCTAssertEqual(fifthItem.title, "Quit")
        XCTAssertEqual(fifthItem.keyEquivalent, "q")
        XCTAssertNotNil(fifthItem.action, "Quit item should have an action")
        XCTAssert(fifthItem.target is MenuBarController)
    }

    // MARK: - Toggle Overlay

    func test_toggleOverlayInitiallyHides() {
        let appController = OverlayAppController(keyboard: KeyboardRegistry.default)
        let menuBarController = MenuBarController(appController: appController)

        XCTAssertEqual(menuBarController.showHideItemTitle, "Hide Overlay")

        menuBarController.toggleOverlay()

        XCTAssertEqual(menuBarController.showHideItemTitle, "Show Overlay")
    }

    func test_toggleOverlayTogglesBackToShow() {
        let appController = OverlayAppController(keyboard: KeyboardRegistry.default)
        let menuBarController = MenuBarController(appController: appController)

        menuBarController.toggleOverlay()
        XCTAssertEqual(menuBarController.showHideItemTitle, "Show Overlay")

        menuBarController.toggleOverlay()
        XCTAssertEqual(menuBarController.showHideItemTitle, "Hide Overlay")
    }

    func test_toggleOverlayIsIdempotentOverMultipleCycles() {
        let appController = OverlayAppController(keyboard: KeyboardRegistry.default)
        let menuBarController = MenuBarController(appController: appController)

        for _ in 0..<4 {
            menuBarController.toggleOverlay()
        }
        XCTAssertEqual(menuBarController.showHideItemTitle, "Hide Overlay")
    }

    // MARK: - Restart

    func test_restartAppResetsVisibilityToHideOverlay() {
        let appController = OverlayAppController(keyboard: KeyboardRegistry.default)
        let menuBarController = MenuBarController(appController: appController)

        menuBarController.toggleOverlay()
        XCTAssertEqual(menuBarController.showHideItemTitle, "Show Overlay")

        menuBarController.restartApp()

        XCTAssertEqual(menuBarController.showHideItemTitle, "Hide Overlay")
    }

    func test_restartAppFromVisibleStateKeepsHideOverlayTitle() {
        let appController = OverlayAppController(keyboard: KeyboardRegistry.default)
        let menuBarController = MenuBarController(appController: appController)

        XCTAssertEqual(menuBarController.showHideItemTitle, "Hide Overlay")

        menuBarController.restartApp()

        XCTAssertEqual(menuBarController.showHideItemTitle, "Hide Overlay")
    }

    // MARK: - AppDelegate Integration

    func test_appDelegateCreatesMenuBarController() {
        let appDelegate = AppDelegate()
        XCTAssertNil(appDelegate.menuBarControllerForTest)

        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        XCTAssertNotNil(appDelegate.menuBarControllerForTest, "AppDelegate should retain MenuBarController after launch")
    }

    func test_appDelegateDoesNotTerminateAfterLastWindowClosed() {
        let appDelegate = AppDelegate()
        let shouldTerminate = appDelegate.applicationShouldTerminateAfterLastWindowClosed(NSApplication.shared)
        XCTAssertFalse(shouldTerminate, "App should NOT terminate after last window closed")
    }
}
