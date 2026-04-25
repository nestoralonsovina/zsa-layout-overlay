import SwiftUI

private enum LabelPosition {
    case top
    case bottom
}

struct KeycapCard: View {
    let key: RenderedKey
    private let keyFont = DesignTokens.Font.monoMedium
    private let sansBoldFont = DesignTokens.Font.headerBold

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.keycap, style: .continuous)
                .fill(key.styleClass.fillColor)
            if key.styleClass == .disabled {
                StripedFill()
                    .opacity(DesignTokens.Opacity.keycapDisabled)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.keycap, style: .continuous))
            }
            RoundedRectangle(cornerRadius: DesignTokens.Radius.keycap, style: .continuous)
                .strokeBorder(Color.black.opacity(DesignTokens.Opacity.keycapStroke), lineWidth: 1)
            if key.isPressed {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.keycap, style: .continuous)
                    .strokeBorder(Color(red: 0.23, green: 0.51, blue: 0.96), lineWidth: 5)
                    .padding(3)
            }
            if let colorDot = key.colorDot {
                Circle()
                    .fill(colorDot)
                    .frame(width: 8, height: 8)
                    .position(x: key.frame.width - 11, y: 11)
            }

            VStack(alignment: singleActionKey ? .center : .leading, spacing: DesignTokens.Spacing.keycapLabelGap) {
                renderStep(key.labels.top, position: .top, twoLabels: key.labels.bottom != nil)

                Spacer(minLength: 0)

                if let emoji = key.labels.emoji {
                    let fallback = String.safeText(emoji)
                    if !fallback.isEmpty {
                        Text(fallback)
                            .font(.custom(sansBoldFont, size: DesignTokens.FontSize.keyLabelXXS))
                            .foregroundStyle(textColor.opacity(DesignTokens.Opacity.keycapEmoji))
                    }
                }

                if let icon = key.labels.icon, !icon.isEmpty {
                    let display = displayIcon(icon)
                    Text(display)
                        .font(.custom(sansBoldFont, size: specialFontSize(for: display, emphasize: iconOnlyKey)))
                        .foregroundStyle(textColor.opacity(DesignTokens.Opacity.keycapText))
                        .frame(maxWidth: .infinity, alignment: iconOnlyKey ? .center : .leading)
                }

                renderStep(key.labels.bottom, position: .bottom, twoLabels: key.labels.bottom != nil)
            }
            .padding(DesignTokens.Spacing.keycapPadding)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: singleActionKey ? .center : .topLeading
            )
        }
        .shadow(color: key.glowColor ?? .clear, radius: 8, x: 0, y: 0)
        .opacity(key.styleClass == .transparent ? DesignTokens.Opacity.keycapTransparent : DesignTokens.Opacity.keycapBackground)
    }

    private var singleActionKey: Bool {
        key.labels.bottom == nil
    }

    private var iconOnlyKey: Bool {
        singleActionKey && key.labels.top == nil && (key.labels.icon?.isEmpty == false)
    }

    private func fontSize(for label: String, emphasize: Bool) -> CGFloat {
        switch label.count {
        case 0...2:
            return emphasize ? DesignTokens.FontSize.keyLabelXL : DesignTokens.FontSize.keyLabelL
        case 3...6:
            return emphasize ? DesignTokens.FontSize.keyLabelM : DesignTokens.FontSize.keyLabelS
        default:
            return emphasize ? DesignTokens.FontSize.keyLabelXS : DesignTokens.FontSize.keyLabelXXS
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

    private func specialFontSize(for text: String, emphasize: Bool) -> CGFloat {
        switch text.count {
        case 0...2:
            return emphasize ? DesignTokens.FontSize.keyLabelXL : DesignTokens.FontSize.keyGlyph
        case 3...6:
            return emphasize ? DesignTokens.FontSize.keyLabelM : DesignTokens.FontSize.keyGlyph
        default:
            return emphasize ? DesignTokens.FontSize.keyLabelS : DesignTokens.FontSize.keyGlyph
        }
    }

    private func shouldEmphasizeGlyph(_ step: RenderedLabelStep, twoLabels: Bool) -> Bool {
        !twoLabels && step.tag == nil && step.modifiers == nil && step.layer == nil
    }

    @ViewBuilder
    private func renderStep(_ step: RenderedLabelStep?, position: LabelPosition, twoLabels: Bool) -> some View {
        if let step {
            if let tag = step.tag, position == .top {
                Text(String.safeText(tag))
                    .font(.custom(keyFont, size: DesignTokens.FontSize.keyTag))
                    .foregroundStyle(textColor.opacity(DesignTokens.Opacity.keycapTag))
                    .frame(maxWidth: .infinity, alignment: textAlignment(for: step, twoLabels: twoLabels))
            }

            if let modifiers = step.modifiers, let glyph = step.glyph {
                Text(String.safeText(modifiers))
                    .font(.custom(keyFont, size: modifierFontSize(for: modifiers)))
                    .foregroundStyle(textColor.opacity(DesignTokens.Opacity.keycapModifier))
                    .frame(maxWidth: .infinity, alignment: textAlignment(for: step, twoLabels: twoLabels))
                Text(String.safeText(glyphDisplay(glyph, layer: step.layer)))
                    .font(.custom(sansBoldFont, size: DesignTokens.FontSize.keyGlyph))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: textAlignment(for: step, twoLabels: twoLabels))
            } else if let glyph = step.glyph {
                let display = String.safeText(glyphDisplay(glyph, layer: step.layer))
                let emphasize = shouldEmphasizeGlyph(step, twoLabels: twoLabels)
                Text(display)
                    .font(.custom(sansBoldFont, size: specialFontSize(for: display, emphasize: emphasize)))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: emphasize ? .center : textAlignment(for: step, twoLabels: twoLabels))
            } else if let modifiers = step.modifiers, !step.label.isEmpty {
                Text(String.safeText("\(modifiers)+\(step.label)"))
                    .font(.custom(keyFont, size: modifierFontSize(for: modifiers)))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: textAlignment(for: step, twoLabels: twoLabels))
                    .multilineTextAlignment(textAlignment(for: step, twoLabels: twoLabels) == .center ? .center : .leading)
                    .lineLimit(2)
            } else {
                Text(String.safeText(step.label))
                    .font(.custom(keyFont, size: fontSize(for: step.label, emphasize: shouldEmphasize(step, twoLabels: twoLabels))))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: textAlignment(for: step, twoLabels: twoLabels))
                    .multilineTextAlignment(textAlignment(for: step, twoLabels: twoLabels) == .center ? .center : .leading)
                    .lineLimit(2)
            }

            if let tag = step.tag, position == .bottom {
                Text(String.safeText(tag))
                    .font(.custom(keyFont, size: DesignTokens.FontSize.keyTag))
                    .foregroundStyle(textColor.opacity(DesignTokens.Opacity.keycapTag))
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
        if modifiers.count == 1 { return DesignTokens.FontSize.modifierLarge }
        if modifiers.count >= 5 { return DesignTokens.FontSize.modifierSmall }
        return DesignTokens.FontSize.modifierMedium
    }

}
