import Foundation

@MainActor
protocol KeyboardDataSource {
    func start(feeding model: OverlayViewModel) async
}

struct KeyboardLiveState {
    let sourceName: String
    let connectionState: String
    let activeLayerIndex: Int?
    let pressedKeyIndices: Set<Int>
    let statusText: String?
}
