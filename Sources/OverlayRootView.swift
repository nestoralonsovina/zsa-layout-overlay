import SwiftUI

struct OverlayRootView: View {
    let model: OverlayViewModel
    @State private var chromeVisible = true
    private let headerFont = "Inter"
    private let keyFont = "JetBrains Mono"
    private let fullKeyboardSize = CGSize(width: 1420, height: 540)
    private let hudWidth: CGFloat = 700
    private let hudHeight: CGFloat = 250
    private let keyboardScale: CGFloat = 0.42
    private let chromeFadeDelay: Duration = .seconds(2)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 16) {
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
                .frame(width: fullKeyboardSize.width, height: fullKeyboardSize.height, alignment: .topLeading)
                .scaleEffect(keyboardScale, anchor: .topLeading)
            }
            .frame(
                width: fullKeyboardSize.width * keyboardScale,
                height: fullKeyboardSize.height * keyboardScale,
                alignment: .topLeading
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: hudWidth, height: hudHeight, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    Color.white.opacity(0.16)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                )
        )
        .overlay(alignment: .bottomLeading) {
            footer
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
        .task(id: chromeActivityToken) {
            await refreshChromeVisibility()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(model.layout.name)")
                .font(.custom(headerFont, size: 18).weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.82))
            Text("Layer \(model.layout.activeLayerIndex) • \(safeText(model.layout.activeLayerName))")
                .font(.custom(headerFont, size: 12).weight(.medium))
                .foregroundStyle(Color.black.opacity(0.5))
        }
        .opacity(chromeVisible ? 1 : 0)
        .offset(y: chromeVisible ? 0 : -6)
    }

    private var statusBadge: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(model.sourceName)
                .font(.custom(headerFont, size: 10).weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.75))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.28)))
            Text(model.connectionState)
                .font(.custom(headerFont, size: 10).weight(.medium))
                .foregroundStyle(Color.black.opacity(0.45))
        }
        .opacity(chromeVisible ? 1 : 0)
        .offset(y: chromeVisible ? 0 : -6)
    }

    private var footer: some View {
        Text(safeText(model.layout.statusText))
            .font(.custom(headerFont, size: 10).weight(.medium))
            .foregroundStyle(Color.black.opacity(0.34))
            .lineLimit(1)
            .opacity(chromeVisible ? 1 : 0)
            .offset(y: chromeVisible ? 0 : 4)
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
            withAnimation(.easeOut(duration: 0.18)) {
                chromeVisible = true
            }
        }

        if pressedKeyCount > 0 {
            return
        }

        try? await Task.sleep(for: chromeFadeDelay)

        if Task.isCancelled || pressedKeyCount > 0 {
            return
        }

        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.24)) {
                chromeVisible = false
            }
        }
    }

    private func safeText(_ text: String) -> String {
        let filtered = text.unicodeScalars.filter { scalar in
            !scalar.properties.isEmojiPresentation && !scalar.properties.isEmoji
        }
        let normalized = String(String.UnicodeScalarView(filtered))
            .replacingOccurrences(of: "\u{FE0F}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? "?" : normalized
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

struct KeycapCard: View {
    let key: RenderedKey
    private let keyFont = "JetBrains Mono"
    private let sansFont = "Inter"

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(key.styleClass.fillColor)
            if key.styleClass == .disabled {
                StripedFill()
                    .opacity(0.45)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
            if key.isPressed {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color(red: 0.23, green: 0.51, blue: 0.96), lineWidth: 5)
                    .padding(3)
            }
            if let colorDot = key.colorDot {
                Circle()
                    .fill(colorDot)
                    .frame(width: 8, height: 8)
                    .position(x: key.frame.width - 11, y: 11)
            }

            VStack(alignment: singleActionKey ? .center : .leading, spacing: 4) {
                renderStep(key.labels.top, position: .top, twoLabels: key.labels.bottom != nil)

                Spacer(minLength: 0)

                if let emoji = key.labels.emoji {
                    let fallback = safeText(emoji)
                    if !fallback.isEmpty {
                        Text(fallback)
                            .font(.custom(sansFont, size: 12).weight(.bold))
                            .foregroundStyle(textColor.opacity(0.7))
                    }
                }

                if let icon = key.labels.icon, !icon.isEmpty {
                    Text(displayIcon(icon))
                        .font(.custom(sansFont, size: 13).weight(.bold))
                        .foregroundStyle(textColor.opacity(0.82))
                }

                renderStep(key.labels.bottom, position: .bottom, twoLabels: key.labels.bottom != nil)
            }
            .padding(6)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: singleActionKey ? .center : .topLeading
            )
        }
        .shadow(color: key.glowColor ?? .clear, radius: 8, x: 0, y: 0)
        .opacity(key.styleClass == .transparent ? 0.2 : 0.92)
    }

    private var singleActionKey: Bool {
        key.labels.bottom == nil
    }

    private func fontSize(for label: String, emphasize: Bool) -> CGFloat {
        switch label.count {
        case 0...2:
            return emphasize ? 26 : 21
        case 3...6:
            return emphasize ? 19 : 15
        default:
            return emphasize ? 14 : 12
        }
    }

    private var textColor: Color {
        key.styleClass.foregroundColor
    }

    private func shouldEmphasize(_ step: RenderedLabelStep, twoLabels: Bool) -> Bool {
        !twoLabels && step.tag == nil && step.glyph == nil && step.modifiers == nil
    }

    private func textAlignment(for step: RenderedLabelStep, twoLabels: Bool) -> Alignment {
        shouldEmphasize(step, twoLabels: twoLabels) ? .center : .leading
    }

    @ViewBuilder
    private func renderStep(_ step: RenderedLabelStep?, position: LabelPosition, twoLabels: Bool) -> some View {
        if let step {
            if let tag = step.tag, position == .top {
                Text(safeText(tag))
                    .font(.custom(keyFont, size: 7.5).weight(.medium))
                    .foregroundStyle(textColor.opacity(0.58))
                    .frame(maxWidth: .infinity, alignment: textAlignment(for: step, twoLabels: twoLabels))
            }

            if let modifiers = step.modifiers, let glyph = step.glyph {
                Text(safeText(modifiers))
                    .font(.custom(keyFont, size: modifierFontSize(for: modifiers)).weight(.medium))
                    .foregroundStyle(textColor.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: textAlignment(for: step, twoLabels: twoLabels))
                Text(safeText(glyphDisplay(glyph, layer: step.layer)))
                    .font(.custom(sansFont, size: 13).weight(.bold))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: textAlignment(for: step, twoLabels: twoLabels))
            } else if let glyph = step.glyph {
                Text(safeText(glyphDisplay(glyph, layer: step.layer)))
                    .font(.custom(sansFont, size: 13).weight(.bold))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: textAlignment(for: step, twoLabels: twoLabels))
            } else if let modifiers = step.modifiers, !step.label.isEmpty {
                Text(safeText("\(modifiers)+\(step.label)"))
                    .font(.custom(keyFont, size: modifierFontSize(for: modifiers)).weight(.medium))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: textAlignment(for: step, twoLabels: twoLabels))
                    .multilineTextAlignment(textAlignment(for: step, twoLabels: twoLabels) == .center ? .center : .leading)
                    .lineLimit(2)
            } else {
                Text(safeText(step.label))
                    .font(.custom(keyFont, size: fontSize(for: step.label, emphasize: shouldEmphasize(step, twoLabels: twoLabels))).weight(.medium))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: textAlignment(for: step, twoLabels: twoLabels))
                    .multilineTextAlignment(textAlignment(for: step, twoLabels: twoLabels) == .center ? .center : .leading)
                    .lineLimit(2)
            }

            if let tag = step.tag, position == .bottom {
                Text(safeText(tag))
                    .font(.custom(keyFont, size: 7.5).weight(.medium))
                    .foregroundStyle(textColor.opacity(0.58))
                    .frame(maxWidth: .infinity, alignment: textAlignment(for: step, twoLabels: twoLabels))
            }
        }
    }

    private func displayIcon(_ icon: String) -> String {
        switch icon {
        case "enter":
            return "↩"
        case "space":
            return "␠"
        case "option_left":
            return "⌥"
        case "option_right":
            return "⌥"
        case "command_left":
            return "⌘"
        case "command_right":
            return "⌘"
        case "control_left":
            return "⌃"
        case "control_right":
            return "⌃"
        case "shift_left":
            return "⇧"
        case "shift_right":
            return "⇧"
        case "backspace":
            return "⌫"
        case "delete_forward":
            return "⌦"
        case "escape":
            return "⎋"
        case "tab":
            return "⇥"
        case "caps_lock":
            return "⇪"
        case "arrow_left":
            return "←"
        case "arrow_right":
            return "→"
        case "arrow_up":
            return "↑"
        case "arrow_down":
            return "↓"
        case "layer_tap":
            return "▣"
        default:
            return icon
        }
    }

    private func glyphDisplay(_ glyph: String, layer: Int?) -> String {
        var base = displayIcon(glyph)
        if let layer {
            base += " \(layer)"
        }
        return base
    }

    private func modifierFontSize(for modifiers: String) -> CGFloat {
        if modifiers.count == 1 { return 18 }
        if modifiers.count >= 5 { return 10 }
        return 13
    }

    private func safeText(_ text: String) -> String {
        let filtered = text.unicodeScalars.filter { scalar in
            !scalar.properties.isEmojiPresentation && !scalar.properties.isEmoji
        }
        return String(String.UnicodeScalarView(filtered))
            .replacingOccurrences(of: "\u{FE0F}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum LabelPosition {
    case top
    case bottom
}

struct StripedFill: View {
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let stripeColor = Color.gray.opacity(0.22)
                let step: CGFloat = 10
                for x in stride(from: -size.height, to: size.width + size.height, by: step) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: size.height))
                    path.addLine(to: CGPoint(x: x + size.height, y: 0))
                    context.stroke(path, with: .color(stripeColor), lineWidth: 4)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
