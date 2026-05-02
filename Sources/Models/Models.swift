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

struct OryxCapture {
    let layoutID: String
    let revisionID: String
    let geometry: String
    let layers: [ParsedLayer]
}

struct ParsedLayer: Hashable {
    let index: Int
    let title: String
    let keys: [ParsedKey]
}

struct ParsedKey: Hashable {
    let top: RenderedLabelStep?
    let bottom: RenderedLabelStep?
    let icon: String?
    let emoji: String?
    let styleClass: KeyVisualClass
    let glowColor: Color?
    let colorDot: Color?

    static let empty = ParsedKey(
        top: .init(label: "\u{2298}", tag: nil, glyph: nil, layer: nil, modifiers: nil),
        bottom: nil,
        icon: nil,
        emoji: nil,
        styleClass: .transparent,
        glowColor: nil,
        colorDot: nil
    )
}
