import Foundation

@MainActor
struct MockKeyboardDataSource: KeyboardDataSource {
    var onError: ((ErrorState) -> Void)?

    func start(feeding model: OverlayViewModel) async {
        let frames: [(Int, Set<Int>)] = [
            (0, [7]),
            (0, [8]),
            (1, [9, 34]),
            (1, [25]),
            (0, [37]),
            (1, [42, 43])
        ]

        var index = 0
        while true {
            let frame = frames[index % frames.count]
            model.applyLiveState(
                KeyboardLiveState(
                    sourceName: "mock",
                    connectionState: "animating sample input",
                    activeLayerIndex: frame.0,
                    pressedKeyIndices: frame.1,
                    statusText: "Mock feed is driving the overlay while the real ZSA source is absent."
                )
            )

            index += 1
            try? await Task.sleep(for: .milliseconds(800))
        }
    }
}
