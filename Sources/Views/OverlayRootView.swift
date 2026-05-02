import SwiftUI

private struct OverlayMetrics {
    let keyboardScale: CGFloat
    let keyboardSize: CGSize
    let keyboardOffset: CGSize
}

struct OverlayRootView: View {
    let model: OverlayViewModel
    @State private var chromeVisible = true
    @StateObject private var prefs = PreferencesStore.shared

    private var activeError: ErrorState {
        if let errorCase = model.activeErrors.first(where: { if case .error = $0 { return true }; return false }) {
            return errorCase
        }
        return model.activeErrors.first(where: { $0.isActive }) ?? .none
    }

    private var errorBanner: some View {
        let backgroundColor: Color = {
            if case .warning = activeError { return Color.yellow.opacity(DesignTokens.Opacity.errorBackground) }
            return Color.red.opacity(DesignTokens.Opacity.errorBackground)
        }()

        return HStack(spacing: DesignTokens.Spacing.errorBannerHStack) {
            Text(activeError.message)
                .font(.custom(DesignTokens.Font.headerMedium, size: DesignTokens.FontSize.errorMessage))
                .foregroundStyle(Color.black.opacity(DesignTokens.Opacity.errorText))
                .lineLimit(2)

            Spacer(minLength: 0)

            Button {
                model.reportError(.none)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: DesignTokens.FontSize.errorDismiss))
                    .foregroundStyle(Color.black.opacity(DesignTokens.Opacity.errorDismissIcon))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.Spacing.errorBannerHorizontal)
        .padding(.vertical, DesignTokens.Spacing.errorBannerVertical)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.errorBanner, style: .continuous)
                .fill(backgroundColor)
        )
    }

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
        .opacity(prefs.overlayOpacity)
        .task(id: chromeActivityToken) {
            await refreshChromeVisibility()
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
        let keyboardScale = min(
            DesignTokens.Layout.maxKeyboardScale,
            max(DesignTokens.Layout.minKeyboardScale, min(widthScale, heightScale))
        )

        return OverlayMetrics(
            keyboardScale: keyboardScale,
            keyboardSize: CGSize(width: bounds.width * keyboardScale, height: bounds.height * keyboardScale),
            keyboardOffset: CGSize(width: -bounds.minX, height: -bounds.minY)
        )
    }

    private var header: some View {
        chromeAnimation(
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.headerLeading) {
                Text(model.layout.name)
                    .font(.custom(DesignTokens.Font.headerSemibold, size: DesignTokens.FontSize.hudTitle))
                    .foregroundStyle(chromeTextColor(DesignTokens.Opacity.headerPrimary))
                Text("Layer \(model.layout.activeLayerIndex) • \(String.safeText(model.layout.activeLayerName))")
                    .font(.custom(DesignTokens.Font.headerMedium, size: DesignTokens.FontSize.hudSubtitle))
                    .foregroundStyle(chromeTextColor(DesignTokens.Opacity.headerSecondary))
            }
        )
    }

    private var statusBadge: some View {
        chromeAnimation(
            VStack(alignment: .trailing, spacing: DesignTokens.Spacing.headerLeading) {
                Text(model.sourceName)
                    .font(.custom(DesignTokens.Font.headerSemibold, size: DesignTokens.FontSize.hudCaption))
                    .foregroundStyle(chromeTextColor(DesignTokens.Opacity.badgeLabel))
                    .padding(.horizontal, DesignTokens.Spacing.badgeHorizontal)
                    .padding(.vertical, DesignTokens.Spacing.badgeVertical)
                    .background(Capsule().fill(Color.white.opacity(DesignTokens.Opacity.badgeBackground)))
                Text(model.connectionState)
                    .font(.custom(DesignTokens.Font.headerMedium, size: DesignTokens.FontSize.hudCaption))
                    .foregroundStyle(chromeTextColor(DesignTokens.Opacity.statusSecondary))
            }
        )
    }

    private var footer: some View {
        footerAnimation(
            Text(String.safeText(model.layout.statusText))
                .font(.custom(DesignTokens.Font.headerMedium, size: DesignTokens.FontSize.hudCaption))
                .foregroundStyle(chromeTextColor(DesignTokens.Opacity.footerLabel))
                .lineLimit(1)
        )
    }

    private func chromeAnimation<V: View>(_ view: V) -> some View {
        view
            .opacity(chromeVisible ? 1 : 0)
            .offset(y: chromeVisible ? 0 : -6)
            .animation(.easeInOut(duration: DesignTokens.Animation.chromeShow), value: chromeVisible)
    }

    private func footerAnimation<V: View>(_ view: V) -> some View {
        view
            .opacity(chromeVisible ? 1 : 0)
            .offset(y: chromeVisible ? 0 : 4)
            .animation(.easeInOut(duration: DesignTokens.Animation.chromeShow), value: chromeVisible)
    }

    private func chromeTextColor(_ opacity: Double) -> Color {
        Color.black.opacity(opacity)
    }

    private var pressedKeyCount: Int {
        model.layout.keys.reduce(into: 0) { count, key in
            if key.isPressed {
                count += 1
            }
        }
    }

    private var chromeActivityToken: String {
        "\(model.layout.activeLayerIndex):\(pressedKeyCount)"
    }

    private func refreshChromeVisibility() async {
        await MainActor.run {
            withAnimation(.easeOut(duration: DesignTokens.Animation.chromeShow)) {
                chromeVisible = true
            }
        }

        if pressedKeyCount > 0 {
            return
        }

        try? await Task.sleep(for: .seconds(prefs.chromeFadeDelay))

        if Task.isCancelled || pressedKeyCount > 0 {
            return
        }

        await MainActor.run {
            withAnimation(.easeInOut(duration: DesignTokens.Animation.chromeHide)) {
                chromeVisible = false
            }
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
