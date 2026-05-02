import SwiftUI

private struct OverlayMetrics {
    let keyboardScale: CGFloat
    let keyboardSize: CGSize
    let keyboardOffset: CGSize
}

struct OverlayRootView: View {
    let model: OverlayViewModel
    @State private var overlayVisible = true
    @State private var hasEverReceivedInput = false
    @State private var prefs = PreferencesStore.shared

    var body: some View {
        GeometryReader { proxy in
            let metrics = overlayMetrics(in: proxy.size)

            ZStack(alignment: .topLeading) {
                ForEach(model.layout.keys) { key in
                    PositionedKeyView(key: key, opacity: prefs.keycapOpacity)
                }
            }
            .frame(width: model.layout.bounds.width, height: model.layout.bounds.height, alignment: .topLeading)
            .offset(metrics.keyboardOffset)
            .scaleEffect(metrics.keyboardScale, anchor: .topLeading)
            .frame(width: metrics.keyboardSize.width, height: metrics.keyboardSize.height, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, DesignTokens.Layout.keyboardVerticalInset)
        }
        .opacity(prefs.overlayOpacity * (overlayVisible ? 1 : 0))
        .animation(.easeInOut(duration: DesignTokens.Animation.chromeShow), value: overlayVisible)
        .task(id: overlayActivityToken) {
            await refreshOverlayVisibility()
        }
    }

    private func overlayMetrics(in size: CGSize) -> OverlayMetrics {
        let bounds = model.layout.bounds
        let availableWidth = max(
            size.width - (DesignTokens.Spacing.hudHStack * 2) - (DesignTokens.Layout.keyboardHorizontalInset * 2),
            1
        )
        let availableHeight = max(
            size.height - DesignTokens.Layout.chromeReservedHeight - (DesignTokens.Layout.keyboardVerticalInset * 2),
            1
        )

        let widthScale = availableWidth / max(bounds.width, 1)
        let heightScale = availableHeight / max(bounds.height, 1)
        let keyboardScale = min(widthScale, heightScale)

        return OverlayMetrics(
            keyboardScale: keyboardScale,
            keyboardSize: CGSize(width: bounds.width * keyboardScale, height: bounds.height * keyboardScale),
            keyboardOffset: CGSize(width: -bounds.minX, height: -bounds.minY)
        )
    }

    private var pressedKeyCount: Int {
        model.layout.keys.reduce(into: 0) { count, key in
            if key.isPressed {
                count += 1
            }
        }
    }

    private var overlayActivityToken: String {
        "\(model.layout.activeLayerIndex):\(pressedKeyCount)"
    }

    private func refreshOverlayVisibility() async {
        if pressedKeyCount > 0 {
            withAnimation(.easeOut(duration: DesignTokens.Animation.chromeShow)) {
                overlayVisible = true
                hasEverReceivedInput = true
            }
            return
        }

        if !hasEverReceivedInput {
            return
        }

        try? await Task.sleep(for: .seconds(prefs.chromeFadeDelay))

        if Task.isCancelled || pressedKeyCount > 0 {
            return
        }

        withAnimation(.easeInOut(duration: DesignTokens.Animation.chromeHide)) {
            overlayVisible = false
        }
    }
}

struct PositionedKeyView: View {
    let key: RenderedKey
    let opacity: Double

    var body: some View {
        KeycapCard(key: key)
            .frame(width: key.frame.width, height: key.frame.height)
            .rotationEffect(.degrees(key.rotation))
            .position(
                x: key.frame.minX + key.frame.width / 2,
                y: key.frame.minY + key.frame.height / 2
            )
            .opacity(opacity)
    }
}
