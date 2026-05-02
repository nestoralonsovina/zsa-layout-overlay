import Foundation
import Observation

@MainActor
@Observable
final class OverlayViewModel {
    var layout: RenderedKeyboardLayout
    var sourceName: String = "boot"
    var connectionState: String = "initializing"
    private var capture: OryxCapture?
    private var activeLayerIndex: Int = 0
    private var pressedKeyIndices: Set<Int> = []
    private var statusText: String = "Starting overlay"
    var activeErrors: [ErrorState] = []
    private let keyboard: KeyboardDefinition

    init(keyboard: KeyboardDefinition) {
        self.keyboard = keyboard
        let initialStatus = "Starting overlay"
        self.statusText = initialStatus
        self.layout = KeyboardLayoutRenderer.fallback(definition: keyboard, statusText: initialStatus)
    }

    func reportError(_ state: ErrorState) {
        if case .none = state {
            activeErrors.removeAll()
            return
        }
        activeErrors.removeAll { existing in
            switch (existing, state) {
            case (.warning, .warning), (.error, .error): return true
            default: return false
            }
        }
        activeErrors.append(state)
    }

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
        let layerChanged = state.activeLayerIndex.map { $0 != self.activeLayerIndex } ?? false
        let keysChanged = state.pressedKeyIndices != self.pressedKeyIndices

        sourceName = state.sourceName
        connectionState = state.connectionState
        if let activeLayerIndex = state.activeLayerIndex {
            self.activeLayerIndex = activeLayerIndex
        }
        pressedKeyIndices = state.pressedKeyIndices
        if let statusText = state.statusText {
            self.statusText = statusText
        }

        if layerChanged || keysChanged {
            rerender()
        }
    }

    func applyStatus(sourceName: String, connectionState: String, statusText: String) {
        self.sourceName = sourceName
        self.connectionState = connectionState
        self.statusText = statusText
    }

    func reset() {
        capture = nil
        activeLayerIndex = 0
        pressedKeyIndices.removeAll()
        activeErrors.removeAll()
        statusText = "Restarting..."
        rerender()
    }

    private func rerender() {
        guard let capture else {
            layout = KeyboardLayoutRenderer.fallback(definition: keyboard, statusText: statusText)
            return
        }

        layout = KeyboardLayoutRenderer.render(
            definition: keyboard,
            capture: capture,
            activeLayerIndex: activeLayerIndex,
            pressedKeyIndices: pressedKeyIndices,
            statusText: statusText
        )
    }
}
