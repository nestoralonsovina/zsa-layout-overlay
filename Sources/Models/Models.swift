import Foundation
import SwiftUI

struct RenderedKeyboardLayout: Hashable {
    let name: String
    let activeLayerName: String
    let activeLayerIndex: Int
    let statusText: String
    let keys: [RenderedKey]

    var bounds: CGRect {
        keys.reduce(into: CGRect.null) { partial, key in
            partial = partial.union(key.frame)
        }
    }
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
            return Color.white.opacity(0.66)
        case .modifier:
            return Color(red: 0.86, green: 0.95, blue: 0.70).opacity(0.72)
        case .magic:
            return Color(red: 0.79, green: 0.88, blue: 0.98).opacity(0.72)
        case .macro:
            return Color(red: 0.89, green: 0.86, blue: 0.98).opacity(0.72)
        case .shine:
            return Color(red: 0.98, green: 0.91, blue: 0.62).opacity(0.74)
        case .custom:
            return Color(red: 0.98, green: 0.78, blue: 0.56).opacity(0.74)
        case .disabled:
            return Color.white.opacity(0.52)
        case .transparent:
            return Color.white.opacity(0.20)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .modifier, .magic, .macro, .shine, .custom:
            return Color.black.opacity(0.84)
        case .disabled, .transparent, .neutral:
            return Color.black.opacity(0.82)
        }
    }
}

enum OverlayLayouts {
    static let voyagerPhysicalKeyCount = VoyagerLayout.voyagerPhysicalKeyCount

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
            keys: VoyagerLayout.keySpecs.enumerated().map { index, spec in
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
            keys: VoyagerLayout.keySpecs.map { spec in
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
