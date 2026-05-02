import Foundation
import SwiftUI

enum KeyboardLayoutRenderer {
    static func render(
        definition: KeyboardDefinition,
        capture: OryxCapture,
        activeLayerIndex: Int,
        pressedKeyIndices: Set<Int>,
        statusText: String
    ) -> RenderedKeyboardLayout {
        let layer = resolvedLayer(in: capture, activeLayerIndex: activeLayerIndex)
        let specs = definition.geometry.keySpecs

        return RenderedKeyboardLayout(
            name: definition.geometry.name,
            activeLayerName: layer.title,
            activeLayerIndex: layer.index,
            statusText: statusText,
            keys: specs.enumerated().map { index, spec in
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

    static func fallback(
        definition: KeyboardDefinition,
        statusText: String
    ) -> RenderedKeyboardLayout {
        let specs = definition.geometry.keySpecs
        return RenderedKeyboardLayout(
            name: definition.geometry.name,
            activeLayerName: "Fallback",
            activeLayerIndex: 0,
            statusText: statusText,
            keys: specs.map { spec in
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
