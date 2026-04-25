import Foundation
import Observation

@MainActor
@Observable
final class OverlayViewModel {
    var layout: RenderedKeyboardLayout = OverlayLayouts.voyagerFallback(statusText: "Starting overlay")
    var sourceName: String = "boot"
    var connectionState: String = "initializing"
    private var capture: OryxCapture?
    private var activeLayerIndex: Int = 0
    private var pressedKeyIndices: Set<Int> = []
    private var statusText: String = "Starting overlay"

    func applyCapture(
        _ capture: OryxCapture,
        sourceName: String,
        connectionState: String,
        statusText: String
    ) {
        self.capture = capture
        self.sourceName = sourceName
        self.connectionState = connectionState
        self.statusText = statusText
        rerender()
    }

    func applyLiveState(_ state: KeyboardLiveState) {
        sourceName = state.sourceName
        connectionState = state.connectionState
        if let activeLayerIndex = state.activeLayerIndex {
            self.activeLayerIndex = activeLayerIndex
        }
        pressedKeyIndices = state.pressedKeyIndices
        if let statusText = state.statusText {
            self.statusText = statusText
        }
        rerender()
    }

    func applyStatus(sourceName: String, connectionState: String, statusText: String) {
        self.sourceName = sourceName
        self.connectionState = connectionState
        self.statusText = statusText
        rerender()
    }

    private func rerender() {
        guard let capture else {
            layout = OverlayLayouts.voyagerFallback(statusText: statusText)
            return
        }

        layout = OverlayLayouts.voyager(
            capture: capture,
            activeLayerIndex: activeLayerIndex,
            pressedKeyIndices: pressedKeyIndices,
            statusText: statusText
        )
    }
}
