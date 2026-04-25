import Foundation
import SwiftUI

@MainActor
struct OryxHARDataSource: KeyboardDataSource {
    var onError: ((ErrorState) -> Void)?
    let harPath: String

    func start(feeding model: OverlayViewModel) async {
        do {
            let capture = try OryxHARLoader.load(from: harPath)
            fputs(
                "OryxHARDataSource loaded layout \(capture.layoutID) revision \(capture.revisionID) geometry \(capture.geometry) with \(capture.layers.count) layers: \(capture.layers.map { $0.title }.joined(separator: ", "))\n",
                stderr
            )
            model.applyCapture(
                capture,
                sourceName: "oryx-har",
                connectionState: "captured layout ready",
                statusText: "Loaded \(capture.layers.count) layers from HAR for layout \(capture.layoutID) revision \(capture.revisionID)."
            )
        } catch {
            fputs("OryxHARDataSource error: \(debugDescription(for: error))\n", stderr)
            model.applyStatus(
                sourceName: "oryx-har",
                connectionState: "capture parse failed",
                statusText: "Failed to parse HAR: \(debugDescription(for: error))"
            )
        }
    }

    func debugDescription(for error: Error) -> String {
        if let loaderError = error as? OryxHARLoader.LoaderError {
            return loaderError.localizedDescription
        }
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                return "missing key '\(key.stringValue)' at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .typeMismatch(let type, let context):
                return "type mismatch for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let type, let context):
                return "missing value for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .dataCorrupted(let context):
                return "corrupt data at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): \(context.debugDescription)"
            @unknown default:
                return String(describing: decodingError)
            }
        }
        return error.localizedDescription
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
        top: .init(label: "⊘", tag: nil, glyph: nil, layer: nil, modifiers: nil),
        bottom: nil,
        icon: nil,
        emoji: nil,
        styleClass: .transparent,
        glowColor: nil,
        colorDot: nil
    )
}

enum OryxHARLoader {
    static func load(from path: String) throws -> OryxCapture {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let har = try JSONDecoder().decode(HARFile.self, from: data)

        guard let metadataEntry = har.log.entries.first(where: { $0.request.url.contains("configure.zsa.io/metadata.json") }) else {
            throw LoaderError.metadataMissing
        }
        guard let graphqlEntry = har.log.entries.first(where: { $0.request.url.contains("oryx.zsa.io/graphql") }) else {
            throw LoaderError.graphqlMissing
        }

        guard let metadataContent = metadataEntry.response.content else {
            throw LoaderError.metadataContentMissing
        }
        guard let graphqlContent = graphqlEntry.response.content else {
            throw LoaderError.graphqlContentMissing
        }

        let metadata = try decodeJSON(MetadataResponse.self, from: metadataContent)
        guard let requestBody = graphqlEntry.request.postData?.text else {
            throw LoaderError.graphqlRequestMissing
        }
        let request = try JSONDecoder().decode(GraphQLRequest.self, from: Data(requestBody.utf8))
        let response = try decodeJSON(GraphQLResponse.self, from: graphqlContent)

        let categoryCatalog: [Int: String] = Dictionary(uniqueKeysWithValues: metadata.categories.map { ($0.id, $0.code) })
        let keyCatalog: [String: MetadataKey] = Dictionary(uniqueKeysWithValues: metadata.keys.map { key in
            let enriched = MetadataKey(
                keyCategoryId: key.keyCategoryId,
                code: key.code,
                label: key.label,
                glyph: key.glyph,
                tag: key.tag,
                os: key.os,
                category: key.keyCategoryId.flatMap { categoryCatalog[$0] }
            )
            return (key.code, enriched)
        })
        let layers = response.data.layout.revision.layers.enumerated().map { index, layer in
            ParsedLayer(
                index: layer.position ?? index,
                title: layer.title?.isEmpty == false ? layer.title! : "Layer \(index)",
                keys: layer.keys.map { parseKey($0, keyCatalog: keyCatalog) }
            )
        }

        return OryxCapture(
            layoutID: request.variables.layoutId,
            revisionID: request.variables.revisionId,
            geometry: request.variables.geometry ?? response.data.layout.geometry,
            layers: layers
        )
    }

    private static func parseKey(_ key: LayoutKey, keyCatalog: [String: MetadataKey]) -> ParsedKey {
        let styleClass = classify(key: key, keyCatalog: keyCatalog)
        let labels = buildLabels(for: key, keyCatalog: keyCatalog)

        return ParsedKey(
            top: labels.top,
            bottom: labels.bottom,
            icon: key.icon,
            emoji: key.emoji,
            styleClass: styleClass,
            glowColor: color(from: key.glowColor),
            colorDot: color(from: key.tap?.color)
        )
    }

    private static func buildLabels(for key: LayoutKey, keyCatalog: [String: MetadataKey]) -> (top: RenderedLabelStep?, bottom: RenderedLabelStep?) {
        if let customLabel = key.customLabel, !customLabel.isEmpty {
            return (.init(label: customLabel, tag: nil, glyph: nil, layer: nil, modifiers: nil), nil)
        }

        var top: RenderedLabelStep?
        var bottom: RenderedLabelStep?

        for (slot, action) in [("tap", key.tap), ("hold", key.hold), ("doubleTap", key.doubleTap), ("tapHold", key.tapHold)] {
            guard let action else { continue }
            let step = makeStep(for: slot, action: action, keyCatalog: keyCatalog)
            if top == nil {
                top = step
            } else if bottom == nil {
                bottom = step
            }
        }

        return (top, bottom)
    }

    private static func makeStep(for slot: String, action: KeyAction, keyCatalog: [String: MetadataKey]) -> RenderedLabelStep {
        let normalizedCode = action.code.map(normalizedMetadataCode)
        let metadata = normalizedCode.flatMap { keyCatalog[$0] } ?? action.code.flatMap { keyCatalog[$0] }
        let metadataOverride = macMetadataOverride(for: metadata)
        let rawTag = slot == "hold" && action.code == "TO" ? "hold" : (metadataOverride?.tag ?? metadata?.tag)
        let tag = displayTag(rawTag, slot: slot)
        let modifiers = formatModifiers(action.modifiers)
        let label = metadataOverride?.label ?? metadata?.label ?? normalizedCode ?? action.code ?? ""
        let glyph = metadataOverride?.glyph ?? metadata?.glyph

        return RenderedLabelStep(
            label: label,
            tag: tag,
            glyph: glyph,
            layer: action.layer,
            modifiers: modifiers
        )
    }

    private static func classify(key: LayoutKey, keyCatalog: [String: MetadataKey]) -> KeyVisualClass {
        let tapCode = key.tap?.code

        if tapCode == "KC_NO" || tapCode == "KC_TRANSPARENT" {
            return .transparent
        }
        let isMacro = key.tap?.macro != nil
        let isMagic = isDualRole(key) || [key.tap, key.hold, key.doubleTap, key.tapHold].compactMap(\.?.code).contains { isMagicCode($0) }
        let categories = [key.tap, key.hold, key.doubleTap, key.tapHold]
            .compactMap { $0?.code }
            .compactMap { keyCatalog[$0]?.category }

        if isMagic {
            return .magic
        }
        if categories.contains("modifier") {
            return .modifier
        }
        if isMacro {
            return .macro
        }
        if categories.contains("shine") {
            return .shine
        }
        if key.customLabel != nil {
            return .custom
        }
        return .neutral
    }

    private static func isDualRole(_ key: LayoutKey) -> Bool {
        let tapOnly = key.tap != nil && key.hold == nil && key.doubleTap == nil && key.tapHold == nil
        let holdOnly = key.tap == nil && key.hold != nil && key.doubleTap == nil && key.tapHold == nil
        return !tapOnly && !holdOnly && (key.hold != nil || key.doubleTap != nil || key.tapHold != nil)
    }

    private static func isMagicCode(_ code: String) -> Bool {
        [
            "KC_POWER", "KC_PWR", "KC_SYSTEM_POWER", "RESET", "QK_BOOT", "EEP_RST", "EE_CLR",
            "KC_CAPSLOCK", "DYN_REC_START1", "DM_REC1", "DYN_REC_START2", "DM_REC2", "DYN_REC_STOP",
            "DM_RSTP", "DYN_MACRO_PLAY1", "DM_PLY1", "DYN_MACRO_PLAY2", "DM_PLY2", "LM",
            "LOWER_OSL", "LOWER_TG", "LOWER", "MO", "OSL", "RAISE_OSL", "RAISE_TG", "RAISE",
            "TG", "TO", "TT", "KC_SLASH", "KC_ESCAPE", "KC_NO"
        ].contains(code)
    }

    private static func normalizedMetadataCode(_ code: String) -> String {
        metadataCodeAliases[code] ?? code
    }

    private static func displayTag(_ rawTag: String?, slot: String) -> String? {
        guard let rawTag else { return nil }
        if rawTag == "tap/hold" {
            switch slot {
            case "hold", "tapHold":
                return "pressed"
            default:
                return "normal"
            }
        }
        return rawTag
    }

    private static func macMetadataOverride(for metadata: MetadataKey?) -> MetadataKeyOverride? {
        metadata?.os?.osx ?? metadata?.os?.macos
    }

    private static func formatModifiers(_ modifiers: KeyModifiers?) -> String? {
        guard let modifiers else { return nil }
        let active = modifiers.activeKeys
        guard !active.isEmpty else { return nil }

        let size: ModifierLabelSize
        if active.count == 2 {
            size = .medium
        } else if active.count > 2 {
            size = .short
        } else {
            size = .long
        }

        let labels = active.compactMap { modifierAbbreviations[$0]?[size] }
        return labels.isEmpty ? nil : labels.joined(separator: "+")
    }

    private static func color(from raw: String?) -> Color? {
        guard let raw, raw.hasPrefix("#") else { return nil }
        let hex = String(raw.dropFirst())
        guard hex.count == 6, let value = Int(hex, radix: 16) else {
            return nil
        }
        let r = Double((value >> 16) & 0xff) / 255.0
        let g = Double((value >> 8) & 0xff) / 255.0
        let b = Double(value & 0xff) / 255.0
        return Color(red: r, green: g, blue: b)
    }

    private static func decodeJSON<T: Decodable>(_ type: T.Type, from content: HARContent) throws -> T {
        let rawData: Data
        if content.encoding == "base64" {
            guard let text = content.text, let decoded = Data(base64Encoded: text) else {
                throw LoaderError.invalidBase64
            }
            rawData = decoded
        } else {
            rawData = Data((content.text ?? "").utf8)
        }
        return try JSONDecoder().decode(T.self, from: rawData)
    }

    enum LoaderError: Error {
        case metadataMissing
        case metadataContentMissing
        case graphqlMissing
        case graphqlContentMissing
        case graphqlRequestMissing
        case invalidBase64
    }
}

extension OryxHARLoader.LoaderError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .metadataMissing:
            return "metadata.json entry not found in HAR"
        case .metadataContentMissing:
            return "metadata.json response had no content body"
        case .graphqlMissing:
            return "oryx GraphQL entry not found in HAR"
        case .graphqlContentMissing:
            return "oryx GraphQL response had no content body"
        case .graphqlRequestMissing:
            return "oryx GraphQL request body missing from HAR"
        case .invalidBase64:
            return "HAR response body claimed base64 encoding but could not be decoded"
        }
    }
}

private struct HARFile: Decodable {
    let log: HARLog
}

private struct HARLog: Decodable {
    let entries: [HAREntry]
}

private struct HAREntry: Decodable {
    let request: HARRequest
    let response: HARResponse
}

private struct HARRequest: Decodable {
    let url: String
    let postData: HARPostData?
}

private struct HARPostData: Decodable {
    let text: String
}

private struct HARResponse: Decodable {
    let content: HARContent?
}

private struct HARContent: Decodable {
    let text: String?
    let encoding: String?
}

private struct MetadataResponse: Decodable {
    let keys: [MetadataKey]
    let categories: [MetadataCategory]
}

private struct MetadataKey: Decodable {
    let keyCategoryId: Int?
    let code: String
    let label: String?
    let glyph: String?
    let tag: String?
    let os: MetadataOS?
    let category: String?

    enum CodingKeys: String, CodingKey {
        case keyCategoryId = "key_category_id"
        case code
        case label
        case glyph
        case tag
        case os
        case category
    }
}

private struct MetadataOS: Decodable {
    let osx: MetadataKeyOverride?
    let macos: MetadataKeyOverride?
    let win: MetadataKeyOverride?
    let linux: MetadataKeyOverride?
    let others: MetadataKeyOverride?
}

private struct MetadataKeyOverride: Decodable {
    let label: String?
    let glyph: String?
    let tag: String?
}

private struct MetadataCategory: Decodable {
    let id: Int
    let code: String
}

private struct GraphQLRequest: Decodable {
    let variables: Variables

    struct Variables: Decodable {
        let layoutId: String
        let revisionId: String
        let geometry: String?
    }
}

private struct GraphQLResponse: Decodable {
    let data: DataNode

    struct DataNode: Decodable {
        let layout: LayoutNode
    }

    struct LayoutNode: Decodable {
        let geometry: String
        let revision: RevisionNode
    }

    struct RevisionNode: Decodable {
        let layers: [LayerNode]
    }

    struct LayerNode: Decodable {
        let keys: [LayoutKey]
        let position: Int?
        let title: String?
    }
}

private struct LayoutKey: Decodable {
    let tap: KeyAction?
    let hold: KeyAction?
    let icon: String?
    let emoji: String?
    let tapHold: KeyAction?
    let doubleTap: KeyAction?
    let glowColor: String?
    let customLabel: String?
}

private struct KeyAction: Decodable {
    let code: String?
    let layer: Int?
    let color: String?
    let macro: String?
    let modifiers: KeyModifiers?
}

private struct KeyModifiers: Decodable {
    let leftAlt: Bool?
    let leftCtrl: Bool?
    let leftGui: Bool?
    let leftShift: Bool?
    let rightAlt: Bool?
    let rightCtrl: Bool?
    let rightGui: Bool?
    let rightShift: Bool?

    var activeKeys: [String] {
        [
            ("leftAlt", leftAlt),
            ("leftCtrl", leftCtrl),
            ("leftGui", leftGui),
            ("leftShift", leftShift),
            ("rightAlt", rightAlt),
            ("rightCtrl", rightCtrl),
            ("rightGui", rightGui),
            ("rightShift", rightShift)
        ].compactMap { $0.1 == true ? $0.0 : nil }
    }
}

private enum ModifierLabelSize {
    case short
    case medium
    case long
}

private let modifierAbbreviations: [String: [ModifierLabelSize: String]] = [
    "leftAlt": [.short: "O", .medium: "OPT", .long: "Opt"],
    "rightAlt": [.short: "O", .medium: "OPT", .long: "Opt"],
    "leftCtrl": [.short: "C", .medium: "CTL", .long: "Ctrl"],
    "rightCtrl": [.short: "C", .medium: "CTL", .long: "Ctrl"],
    "leftGui": [.short: "C", .medium: "Cmd", .long: "Command"],
    "rightGui": [.short: "C", .medium: "Cmd", .long: "Command"],
    "leftShift": [.short: "S", .medium: "SFT", .long: "Shift"],
    "rightShift": [.short: "S", .medium: "SFT", .long: "Shift"]
]

private let metadataCodeAliases: [String: String] = [
    "KC_LEFT_CTRL": "KC_LCTRL",
    "KC_RIGHT_CTRL": "KC_RCTRL",
    "KC_LEFT_SHIFT": "KC_LSHIFT",
    "KC_RIGHT_SHIFT": "KC_RSHIFT",
    "KC_LEFT_GUI": "KC_LGUI",
    "KC_RIGHT_GUI": "KC_RGUI",
    "KC_LEFT_ALT": "KC_LALT",
    "KC_RIGHT_ALT": "KC_RALT",
    "KC_SCLN": "KC_SCOLON",
    "KC_BSPC": "KC_BSPACE",
    "KC_ENT": "KC_ENTER",
    "KC_PGUP": "KC_PAGE_UP",
    "KC_PGDN": "KC_PAGE_DOWN",
    "KC_DEL": "KC_DELETE",
    "KC_INS": "KC_INSERT",
    "KC_QUOT": "KC_QUOTE",
    "KC_GRV": "KC_GRAVE"
]
