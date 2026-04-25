import Foundation
import SwiftUI

struct RenderedKeyboardLayout: Hashable {
    let name: String
    let activeLayerName: String
    let activeLayerIndex: Int
    let statusText: String
    let keys: [RenderedKey]
}

struct RenderedKey: Identifiable, Hashable {
    let id: String
    let frame: CGRect
    let rotation: Double
    let styleClass: KeyVisualClass
    let labels: RenderedKeyLabels
    let isPressed: Bool
    let glowColor: Color?
    let colorDot: Color?
}

struct RenderedKeyLabels: Hashable {
    let top: RenderedLabelStep?
    let bottom: RenderedLabelStep?
    let icon: String?
    let emoji: String?
}

struct RenderedLabelStep: Hashable {
    let label: String
    let tag: String?
    let glyph: String?
    let layer: Int?
    let modifiers: String?
}

enum KeyVisualClass: String, Hashable {
    case neutral
    case modifier
    case magic
    case macro
    case shine
    case custom
    case disabled
    case transparent

    var fillColor: Color {
        switch self {
        case .neutral:
            return Color.white.opacity(0.72)
        case .modifier:
            return Color(red: 0.85, green: 0.96, blue: 0.62)
        case .magic:
            return Color(red: 0.75, green: 0.86, blue: 0.98)
        case .macro:
            return Color(red: 0.87, green: 0.84, blue: 0.99)
        case .shine:
            return Color(red: 0.99, green: 0.90, blue: 0.54)
        case .custom:
            return Color(red: 0.99, green: 0.73, blue: 0.45)
        case .disabled:
            return Color.white.opacity(0.68)
        case .transparent:
            return Color.white.opacity(0.42)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .modifier, .magic, .macro, .shine, .custom:
            return Color.black.opacity(0.72)
        case .disabled, .transparent, .neutral:
            return Color.primary.opacity(0.82)
        }
    }
}

enum OverlayLayouts {
    static let voyagerPhysicalKeyCount = keySpecs.count

    static func voyager(
        capture: OryxCapture,
        activeLayerIndex: Int,
        pressedKeyIndices: Set<Int>,
        statusText: String
    ) -> RenderedKeyboardLayout {
        let layer = resolvedLayer(in: capture, activeLayerIndex: activeLayerIndex)

        return RenderedKeyboardLayout(
            name: "Voyager",
            activeLayerName: layer.title,
            activeLayerIndex: layer.index,
            statusText: statusText,
            keys: keySpecs.enumerated().map { index, spec in
                let content = index < layer.keys.count ? layer.keys[index] : .empty
                return RenderedKey(
                    id: spec.id,
                    frame: spec.frame,
                    rotation: spec.rotation,
                    styleClass: content.styleClass,
                    labels: .init(
                        top: content.top,
                        bottom: content.bottom,
                        icon: content.icon,
                        emoji: content.emoji
                    ),
                    isPressed: pressedKeyIndices.contains(index),
                    glowColor: content.glowColor,
                    colorDot: content.colorDot
                )
            }
        )
    }

    static func voyagerFallback(statusText: String) -> RenderedKeyboardLayout {
        RenderedKeyboardLayout(
            name: "Voyager",
            activeLayerName: "Fallback",
            activeLayerIndex: 0,
            statusText: statusText,
            keys: keySpecs.map { spec in
                RenderedKey(
                    id: spec.id,
                    frame: spec.frame,
                    rotation: spec.rotation,
                    styleClass: .transparent,
                    labels: .init(
                        top: ParsedKey.empty.top,
                        bottom: ParsedKey.empty.bottom,
                        icon: ParsedKey.empty.icon,
                        emoji: ParsedKey.empty.emoji
                    ),
                    isPressed: false,
                    glowColor: nil,
                    colorDot: nil
                )
            }
        )
    }

    private static func resolvedLayer(in capture: OryxCapture, activeLayerIndex: Int) -> ParsedLayer {
        if let exact = capture.layers.first(where: { $0.index == activeLayerIndex }) {
            return exact
        }
        let fallbackIndex = min(max(activeLayerIndex, 0), max(capture.layers.count - 1, 0))
        return capture.layers[fallbackIndex]
    }
}

private struct KeySpec {
    let id: String
    let frame: CGRect
    let rotation: Double
}

private let keyWidth: CGFloat = 66
private let keyHeight: CGFloat = 66
private let gap: CGFloat = 6

private func rect(_ x: CGFloat, _ y: CGFloat, w: CGFloat = keyWidth, h: CGFloat = keyHeight) -> CGRect {
    CGRect(x: x, y: y, width: w, height: h)
}

private let keySpecs: [KeySpec] = [
    KeySpec(id: "L00", frame: rect(26, 32), rotation: 0),
    KeySpec(id: "L01", frame: rect(26 + 1 * (keyWidth + gap), 32), rotation: 0),
    KeySpec(id: "L02", frame: rect(26 + 2 * (keyWidth + gap), 32), rotation: 0),
    KeySpec(id: "L03", frame: rect(26 + 3 * (keyWidth + gap), 10), rotation: 0),
    KeySpec(id: "L04", frame: rect(26 + 4 * (keyWidth + gap), 24), rotation: 0),
    KeySpec(id: "L05", frame: rect(26 + 5 * (keyWidth + gap), 24), rotation: 0),

    KeySpec(id: "L10", frame: rect(26, 32 + 1 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L11", frame: rect(26 + 1 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L12", frame: rect(26 + 2 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L13", frame: rect(26 + 3 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L14", frame: rect(26 + 4 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L15", frame: rect(26 + 5 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),

    KeySpec(id: "L20", frame: rect(26, 32 + 2 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L21", frame: rect(26 + 1 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L22", frame: rect(26 + 2 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L23", frame: rect(26 + 3 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L24", frame: rect(26 + 4 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L25", frame: rect(26 + 5 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),

    KeySpec(id: "L30", frame: rect(26, 32 + 3 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L31", frame: rect(26 + 1 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L32", frame: rect(26 + 2 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L33", frame: rect(26 + 3 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L34", frame: rect(26 + 4 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "L35", frame: rect(26 + 5 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),

    KeySpec(id: "LT0", frame: rect(520, 355), rotation: -30),
    KeySpec(id: "LT1", frame: rect(566, 406), rotation: 28),

    KeySpec(id: "R00", frame: rect(930, 24), rotation: 0),
    KeySpec(id: "R01", frame: rect(930 + 1 * (keyWidth + gap), 24), rotation: 0),
    KeySpec(id: "R02", frame: rect(930 + 2 * (keyWidth + gap), 12), rotation: 0),
    KeySpec(id: "R03", frame: rect(930 + 3 * (keyWidth + gap), 24), rotation: 0),
    KeySpec(id: "R04", frame: rect(930 + 4 * (keyWidth + gap), 24), rotation: 0),
    KeySpec(id: "R05", frame: rect(930 + 5 * (keyWidth + gap), 24), rotation: 0),

    KeySpec(id: "R10", frame: rect(930, 32 + 1 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R11", frame: rect(930 + 1 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R12", frame: rect(930 + 2 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R13", frame: rect(930 + 3 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R14", frame: rect(930 + 4 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R15", frame: rect(930 + 5 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),

    KeySpec(id: "R20", frame: rect(930, 32 + 2 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R21", frame: rect(930 + 1 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R22", frame: rect(930 + 2 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R23", frame: rect(930 + 3 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R24", frame: rect(930 + 4 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R25", frame: rect(930 + 5 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),

    KeySpec(id: "R30", frame: rect(930, 32 + 3 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R31", frame: rect(930 + 1 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R32", frame: rect(930 + 2 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R33", frame: rect(930 + 3 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R34", frame: rect(930 + 4 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
    KeySpec(id: "R35", frame: rect(930 + 5 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),

    KeySpec(id: "RT0", frame: rect(878, 408), rotation: -28),
    KeySpec(id: "RT1", frame: rect(825, 356), rotation: 28)
]
