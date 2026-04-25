import SwiftUI

struct OverlayRootView: View {
    let model: OverlayViewModel
    @State private var chromeVisible = true

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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.hudVStack) {
            if model.activeErrors.contains(where: { $0.isActive }) {
                errorBanner
            }

            HStack(alignment: .top, spacing: DesignTokens.Spacing.hudHStack) {
                header
                Spacer(minLength: 0)
                statusBadge
            }

            ZStack(alignment: .topLeading) {
                Color.clear
                ZStack(alignment: .topLeading) {
                    ForEach(model.layout.keys) { key in
                        PositionedKeyView(key: key)
                    }
                }
                .frame(
                    width: DesignTokens.Layout.keyboardCanvasWidth,
                    height: DesignTokens.Layout.keyboardCanvasHeight,
                    alignment: .topLeading
                )
                .scaleEffect(DesignTokens.Layout.keyboardScale, anchor: .topLeading)
            }
            .frame(
                width: DesignTokens.Layout.keyboardCanvasWidth * DesignTokens.Layout.keyboardScale,
                height: DesignTokens.Layout.keyboardCanvasHeight * DesignTokens.Layout.keyboardScale,
                alignment: .topLeading
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.keyboardClip, style: .continuous))
        }
        .padding(.horizontal, DesignTokens.Spacing.hudHStack)
        .padding(.vertical, DesignTokens.Spacing.hudVertical)
        .frame(
            width: DesignTokens.Layout.hudWidth,
            height: DesignTokens.Layout.hudHeight,
            alignment: .topLeading
        )
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.hudPanel, style: .continuous)
                .fill(
                    Color.white.opacity(DesignTokens.Opacity.chromeBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.hudPanel, style: .continuous)
                        .strokeBorder(Color.white.opacity(DesignTokens.Opacity.chromeBorder), lineWidth: 1)
                )
        )
        .overlay(alignment: .bottomLeading) {
            footer
                .padding(.horizontal, DesignTokens.Spacing.hudHStack)
                .padding(.bottom, DesignTokens.Spacing.hudVStack)
        }
        .compositingGroup()
        .shadow(
            color: .black.opacity(DesignTokens.Shadow.hudOpacity),
            radius: DesignTokens.Shadow.hudRadius,
            x: 0,
            y: DesignTokens.Shadow.hudY
        )
        .task(id: chromeActivityToken) {
            await refreshChromeVisibility()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.headerLeading) {
            Text("\(model.layout.name)")
                .font(.custom(DesignTokens.Font.headerSemibold, size: DesignTokens.FontSize.hudTitle))
                .foregroundStyle(Color.black.opacity(DesignTokens.Opacity.headerPrimary))
            Text("Layer \(model.layout.activeLayerIndex) • \(String.safeText(model.layout.activeLayerName))")
                .font(.custom(DesignTokens.Font.headerMedium, size: DesignTokens.FontSize.hudSubtitle))
                .foregroundStyle(Color.black.opacity(DesignTokens.Opacity.headerSecondary))
        }
        .opacity(chromeVisible ? 1 : 0)
        .offset(y: chromeVisible ? 0 : -6)
        .animation(.easeInOut(duration: DesignTokens.Animation.chromeShow), value: chromeVisible)
    }

    private var statusBadge: some View {
        VStack(alignment: .trailing, spacing: DesignTokens.Spacing.headerLeading) {
            Text(model.sourceName)
                .font(.custom(DesignTokens.Font.headerSemibold, size: DesignTokens.FontSize.hudCaption))
                .foregroundStyle(Color.black.opacity(DesignTokens.Opacity.badgeLabel))
                .padding(.horizontal, DesignTokens.Spacing.badgeHorizontal)
                .padding(.vertical, DesignTokens.Spacing.badgeVertical)
                .background(Capsule().fill(Color.white.opacity(DesignTokens.Opacity.badgeBackground)))
            Text(model.connectionState)
                .font(.custom(DesignTokens.Font.headerMedium, size: DesignTokens.FontSize.hudCaption))
                .foregroundStyle(Color.black.opacity(DesignTokens.Opacity.statusSecondary))
        }
        .opacity(chromeVisible ? 1 : 0)
        .offset(y: chromeVisible ? 0 : -6)
        .animation(.easeInOut(duration: DesignTokens.Animation.chromeShow), value: chromeVisible)
    }

    private var footer: some View {
        Text(String.safeText(model.layout.statusText))
            .font(.custom(DesignTokens.Font.headerMedium, size: DesignTokens.FontSize.hudCaption))
            .foregroundStyle(Color.black.opacity(DesignTokens.Opacity.footerLabel))
            .lineLimit(1)
            .opacity(chromeVisible ? 1 : 0)
            .offset(y: chromeVisible ? 0 : 4)
            .animation(.easeInOut(duration: DesignTokens.Animation.chromeShow), value: chromeVisible)
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

        try? await Task.sleep(for: .seconds(DesignTokens.Animation.chromeFadeDelay))

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

    var body: some View {
        KeycapCard(key: key)
            .frame(width: key.frame.width, height: key.frame.height)
            .rotationEffect(.degrees(key.rotation))
            .position(
                x: key.frame.minX + key.frame.width / 2,
                y: key.frame.minY + key.frame.height / 2
            )
    }
}
