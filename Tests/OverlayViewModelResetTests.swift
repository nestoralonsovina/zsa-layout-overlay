import XCTest
@testable import ZSALayoutOverlay

@MainActor
final class OverlayViewModelResetTests: XCTestCase {

    func test_resetClearsActiveErrors() {
        let model = OverlayViewModel(keyboard: KeyboardRegistry.default)
        model.reportError(.warning("Test warning"))
        XCTAssertEqual(model.activeErrors.count, 1)

        model.reset()

        XCTAssertEqual(model.activeErrors.count, 0)
    }

    func test_resetProducesFallbackLayout() {
        let model = OverlayViewModel(keyboard: KeyboardRegistry.default)
        model.reset()

        XCTAssertEqual(model.layout.activeLayerName, "Fallback")
        XCTAssertEqual(model.layout.name, "Voyager")
        XCTAssertEqual(model.layout.activeLayerIndex, 0)
    }

    func test_resetSetsStatusTextToRestarting() {
        let model = OverlayViewModel(keyboard: KeyboardRegistry.default)
        model.reset()

        XCTAssertEqual(model.layout.statusText, "Restarting...")
    }

    func test_resetYieldsAllKeysUnpressed() {
        let model = OverlayViewModel(keyboard: KeyboardRegistry.default)
        model.reset()

        let pressedKeys = model.layout.keys.filter { $0.isPressed }
        XCTAssertEqual(pressedKeys.count, 0)
    }

    func test_resetYieldsTransparentKeys() {
        let model = OverlayViewModel(keyboard: KeyboardRegistry.default)
        model.reset()

        let nonTransparentKeys = model.layout.keys.filter { $0.styleClass != .transparent }
        XCTAssertEqual(nonTransparentKeys.count, 0)
    }

    func test_resetIsIdempotent() {
        let model = OverlayViewModel(keyboard: KeyboardRegistry.default)
        model.reset()
        let firstLayout = model.layout

        model.reset()
        let secondLayout = model.layout

        XCTAssertEqual(firstLayout.activeLayerName, secondLayout.activeLayerName)
        XCTAssertEqual(firstLayout.statusText, secondLayout.statusText)
        XCTAssertEqual(firstLayout.keys.count, secondLayout.keys.count)
    }

    func test_resetClearsStateAfterApplyCapture() {
        let model = OverlayViewModel(keyboard: KeyboardRegistry.default)
        model.reportError(.error("Test error"))
        model.reportError(.warning("Another warning"))
        XCTAssertEqual(model.activeErrors.count, 2)

        model.reset()

        XCTAssertEqual(model.activeErrors.count, 0)
        XCTAssertEqual(model.layout.activeLayerName, "Fallback")
        XCTAssertEqual(model.layout.statusText, "Restarting...")
    }
}

@MainActor
final class OverlayWindowControllerTests: XCTestCase {

    func test_hideWindowMethodExists() {
        let model = OverlayViewModel(keyboard: KeyboardRegistry.default)
        let mainScreen = NSScreen.main ?? NSScreen.screens.first!
        let controller = OverlayWindowController(model: model, screen: mainScreen)

        XCTAssertNotNil(controller)
        controller.hideWindow()
    }
}

@MainActor
final class OverlayAppControllerLifecycleTests: XCTestCase {

    func test_restartMethodExistsAndCompiles() {
        let controller = OverlayAppController(keyboard: KeyboardRegistry.default)

        XCTAssertNotNil(controller)
        controller.restart()
    }
}
