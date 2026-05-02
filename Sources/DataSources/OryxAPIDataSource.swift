import Foundation
import SwiftUI

@MainActor
struct OryxAPIDataSource: KeyboardDataSource {
    var onError: ((ErrorState) -> Void)?
    let layoutHashId: String
    let geometry: String
    let revisionId: String

    func start(feeding model: OverlayViewModel) async {
        do {
            async let metadata = OryxAPIClient.fetchMetadata()
            async let layout = OryxAPIClient.fetchLayout(hashId: layoutHashId, geometry: geometry, revisionId: revisionId)

            let (resolvedMetadata, resolvedLayout) = try await (metadata, layout)
            let capture = try OryxAPIClient.buildCapture(from: resolvedLayout, metadata: resolvedMetadata, geometry: geometry)

            fputs(
                "OryxAPIDataSource loaded layout \(capture.layoutID) with \(capture.layers.count) layers: \(capture.layers.map { $0.title }.joined(separator: ", "))\n",
                stderr
            )
            model.applyCapture(
                capture,
                sourceName: "oryx-api",
                connectionState: "layout loaded",
                statusText: "Loaded \(capture.layers.count) layers for layout \(capture.layoutID)."
            )
        } catch {
            fputs("OryxAPIDataSource error: \(error)\n", stderr)
            model.applyStatus(
                sourceName: "oryx-api",
                connectionState: "load failed",
                statusText: "Failed to load layout: \(error.localizedDescription)"
            )
            onError?(.error("Failed to load layout from Oryx: \(error.localizedDescription)"))
        }
    }
}

// MARK: - API Client

enum OryxAPIClient {
    private static let graphqlURL = URL(string: "https://oryx.zsa.io/graphql")!
    private static let metadataURL = URL(string: "https://configure.zsa.io/metadata.json")!

    fileprivate static func fetchMetadata() async throws -> APIMetadata {
        let (data, _) = try await URLSession.shared.data(from: metadataURL)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(APIMetadata.self, from: data)
    }

    fileprivate static func fetchLayout(hashId: String, geometry: String, revisionId: String) async throws -> APILayoutResponse {
        let query = """
        query getLayout($hashId: String!, $revisionId: String!, $geometry: String) {
          layout(hashId: $hashId, geometry: $geometry, revisionId: $revisionId) {
            hashId geometry title
            revision { layers { position title keys } }
          }
        }
        """

        let body: [String: Any] = [
            "query": query,
            "variables": ["hashId": hashId, "geometry": geometry, "revisionId": revisionId]
        ]

        var request = URLRequest(url: graphqlURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(APILayoutResponse.self, from: data)
    }

    fileprivate static func buildCapture(from response: APILayoutResponse, metadata: APIMetadata, geometry: String) throws -> OryxCapture {
        guard let layout = response.data?.layout else {
            throw LoadError.missingLayout
        }

        let categoryCatalog: [Int: String] = Dictionary(uniqueKeysWithValues: metadata.categories.map { ($0.id, $0.code) })
        let keyCatalog = buildKeyCatalog(from: metadata.keys, categoryCatalog: categoryCatalog)

        let layers = layout.revision.layers.enumerated().map { index, layer in
            ParsedLayer(
                index: layer.position ?? index,
                title: layer.title?.isEmpty == false ? layer.title! : "Layer \(index)",
                keys: layer.keys.map { parseKey($0, keyCatalog: keyCatalog) }
            )
        }

        return OryxCapture(
            layoutID: layout.hashId,
            revisionID: layout.hashId,
            geometry: geometry,
            layers: layers
        )
    }

    // MARK: - Private Helpers

    private enum LoadError: Error { case missingLayout }

    private static func buildKeyCatalog(from keys: [APIKeyMetadata], categoryCatalog: [Int: String]) -> [String: APIKeyMetadata] {
        var result: [String: APIKeyMetadata] = [:]
        for var key in keys {
            key.category = key.keyCategoryId.flatMap { categoryCatalog[$0] }
            result[key.code] = key
        }
        return result
    }

    private static func parseKey(_ raw: APIKey, keyCatalog: [String: APIKeyMetadata]) -> ParsedKey {
        let styleClass = classify(key: raw, keyCatalog: keyCatalog)
        let labels = buildLabels(for: raw, keyCatalog: keyCatalog)
        return ParsedKey(
            top: labels.top, bottom: labels.bottom,
            icon: raw.icon, emoji: raw.emoji,
            styleClass: styleClass,
            glowColor: color(from: raw.glowColor),
            colorDot: color(from: raw.tap?.color)
        )
    }

    private static func classify(key: APIKey, keyCatalog: [String: APIKeyMetadata]) -> KeyVisualClass {
        let tapCode = key.tap?.code
        if tapCode == "KC_NO" || tapCode == "KC_TRANSPARENT" { return .transparent }
        let isMacro = key.tap?.macro != nil
        let isMagic = isDualRole(key) || [key.tap, key.hold, key.doubleTap, key.tapHold]
            .compactMap(\.?.code).contains { isMagicCode($0) }
        let categories = [key.tap, key.hold, key.doubleTap, key.tapHold]
            .compactMap { $0?.code }
            .compactMap { keyCatalog[$0]?.category }

        if isMagic { return .magic }
        if category(in: categories) == "modifier" { return .modifier }
        if isMacro { return .macro }
        if category(in: categories) == "shine" { return .shine }
        if key.customLabel != nil { return .custom }
        return .neutral
    }

    private static func category(in list: [String]) -> String? { list.first }

    private static func isDualRole(_ key: APIKey) -> Bool {
        let tapOnly = key.tap != nil && key.hold == nil && key.doubleTap == nil && key.tapHold == nil
        let holdOnly = key.tap == nil && key.hold != nil && key.doubleTap == nil && key.tapHold == nil
        return !tapOnly && !holdOnly && (key.hold != nil || key.doubleTap != nil || key.tapHold != nil)
    }

    private static func buildLabels(for key: APIKey, keyCatalog: [String: APIKeyMetadata]) -> (top: RenderedLabelStep?, bottom: RenderedLabelStep?) {
        if let customLabel = key.customLabel, !customLabel.isEmpty {
            return (.init(label: customLabel, tag: nil, glyph: nil, layer: nil, modifiers: nil), nil)
        }
        var top: RenderedLabelStep?
        var bottom: RenderedLabelStep?
        for (slot, action) in [("tap", key.tap), ("hold", key.hold), ("doubleTap", key.doubleTap), ("tapHold", key.tapHold)] {
            guard let action else { continue }
            let step = makeStep(for: slot, action: action, keyCatalog: keyCatalog)
            if top == nil { top = step }
            else if bottom == nil { bottom = step }
        }
        return (top, bottom)
    }

    private static func makeStep(for slot: String, action: APIKeyAction, keyCatalog: [String: APIKeyMetadata]) -> RenderedLabelStep {
        let normalizedCode = action.code.map(normalizedMetadataCode)
        let meta = normalizedCode.flatMap { keyCatalog[$0] } ?? action.code.flatMap { keyCatalog[$0] }
        let metaOverride = macMetadataOverride(for: meta)
        let rawTag = slot == "hold" && action.code == "TO" ? "hold" : (metaOverride?.tag ?? meta?.tag)
        let tag = displayTag(rawTag, slot: slot)
        let modifiers = formatModifiers(action.modifiers)
        let label = metaOverride?.label ?? meta?.label ?? normalizedCode ?? action.code ?? ""
        let glyph = metaOverride?.glyph ?? meta?.glyph
        return RenderedLabelStep(label: label, tag: tag, glyph: glyph, layer: action.layer, modifiers: modifiers)
    }

    private static func displayTag(_ rawTag: String?, slot: String) -> String? {
        guard let rawTag else { return nil }
        if rawTag == "tap/hold" {
            return slot == "hold" || slot == "tapHold" ? "pressed" : "normal"
        }
        return rawTag
    }

    private static func macMetadataOverride(for key: APIKeyMetadata?) -> OSOverride? {
        key?.os?.osx ?? key?.os?.macos
    }

    private static func formatModifiers(_ modifiers: APIKeyModifiers?) -> String? {
        guard let modifiers else { return nil }
        let active = modifiers.activeKeys
        guard !active.isEmpty else { return nil }
        let size: LabelSize
        if active.count == 2 { size = .medium }
        else if active.count > 2 { size = .short }
        else { size = .long }
        let labels = active.compactMap { abbrev[$0]?[size] }
        return labels.isEmpty ? nil : labels.joined(separator: "+")
    }

    private static func color(from raw: String?) -> Color? {
        guard let raw, raw.hasPrefix("#"), raw.count == 7,
              let value = Int(raw.dropFirst(), radix: 16) else { return nil }
        return Color(
            red: Double((value >> 16) & 0xff) / 255,
            green: Double((value >> 8) & 0xff) / 255,
            blue: Double(value & 0xff) / 255
        )
    }

    private static func isMagicCode(_ code: String) -> Bool {
        ["KC_POWER","KC_PWR","KC_SYSTEM_POWER","RESET","QK_BOOT","EEP_RST","EE_CLR",
         "KC_CAPSLOCK","DYN_REC_START1","DM_REC1","DYN_REC_START2","DM_REC2","DYN_REC_STOP",
         "DM_RSTP","DYN_MACRO_PLAY1","DM_PLY1","DYN_MACRO_PLAY2","DM_PLY2","LM",
         "LOWER_OSL","LOWER_TG","LOWER","MO","OSL","RAISE_OSL","RAISE_TG","RAISE",
         "TG","TO","TT","KC_SLASH","KC_ESCAPE","KC_NO"].contains(code)
    }

    private static func normalizedMetadataCode(_ code: String) -> String { aliases[code] ?? code }

    private enum LabelSize { case short, medium, long }

    private static let abbrev: [String: [LabelSize: String]] = [
        "leftAlt": [.short:"O", .medium:"OPT", .long:"Opt"],
        "rightAlt": [.short:"O", .medium:"OPT", .long:"Opt"],
        "leftCtrl": [.short:"C", .medium:"CTL", .long:"Ctrl"],
        "rightCtrl": [.short:"C", .medium:"CTL", .long:"Ctrl"],
        "leftGui": [.short:"C", .medium:"Cmd", .long:"Command"],
        "rightGui": [.short:"C", .medium:"Cmd", .long:"Command"],
        "leftShift": [.short:"S", .medium:"SFT", .long:"Shift"],
        "rightShift": [.short:"S", .medium:"SFT", .long:"Shift"]
    ]

    private static let aliases: [String: String] = [
        "KC_LEFT_CTRL":"KC_LCTRL","KC_RIGHT_CTRL":"KC_RCTRL",
        "KC_LEFT_SHIFT":"KC_LSHIFT","KC_RIGHT_SHIFT":"KC_RSHIFT",
        "KC_LEFT_GUI":"KC_LGUI","KC_RIGHT_GUI":"KC_RGUI",
        "KC_LEFT_ALT":"KC_LALT","KC_RIGHT_ALT":"KC_RALT",
        "KC_SCLN":"KC_SCOLON","KC_BSPC":"KC_BSPACE",
        "KC_ENT":"KC_ENTER","KC_PGUP":"KC_PAGE_UP",
        "KC_PGDN":"KC_PAGE_DOWN","KC_DEL":"KC_DELETE",
        "KC_INS":"KC_INSERT","KC_QUOT":"KC_QUOTE",
        "KC_GRV":"KC_GRAVE","KC_LBRC":"KC_LBRACKET",
        "KC_RBRC":"KC_RBRACKET","KC_BSLS":"KC_BSLASH"
    ]
}

// MARK: - API Models

fileprivate struct APIMetadata: Decodable {
    let keys: [APIKeyMetadata]
    let categories: [APICategory]
}

fileprivate struct APIKeyMetadata: Decodable {
    let keyCategoryId: Int?
    let code: String
    let label: String?
    let glyph: String?
    let tag: String?
    let os: APIOS?
    var category: String?
}

fileprivate struct APIOS: Decodable {
    let osx: OSOverride?
    let macos: OSOverride?
    let win: OSOverride?
    let linux: OSOverride?
    let others: OSOverride?
}

fileprivate struct OSOverride: Decodable {
    let label: String?
    let glyph: String?
    let tag: String?
}

fileprivate struct APICategory: Decodable {
    let id: Int
    let code: String
}

fileprivate struct APILayoutResponse: Decodable {
    let data: DataNode?
    struct DataNode: Decodable {
        let layout: LayoutNode?
    }
    struct LayoutNode: Decodable {
        let hashId: String
        let geometry: String?
        let title: String?
        let revision: RevisionNode
    }
    struct RevisionNode: Decodable {
        let layers: [LayerNode]
    }
    struct LayerNode: Decodable {
        let keys: [APIKey]
        let position: Int?
        let title: String?
    }
}

fileprivate struct APIKey: Decodable {
    let tap: APIKeyAction?
    let hold: APIKeyAction?
    let icon: String?
    let emoji: String?
    let tapHold: APIKeyAction?
    let doubleTap: APIKeyAction?
    let glowColor: String?
    let customLabel: String?
}

fileprivate struct APIKeyAction: Decodable {
    let code: String?
    let layer: Int?
    let color: String?
    let macro: String?
    let modifiers: APIKeyModifiers?
}

fileprivate struct APIKeyModifiers: Decodable {
    let leftAlt: Bool?
    let leftCtrl: Bool?
    let leftGui: Bool?
    let leftShift: Bool?
    let rightAlt: Bool?
    let rightCtrl: Bool?
    let rightGui: Bool?
    let rightShift: Bool?

    var activeKeys: [String] {
        [("leftAlt",leftAlt),("leftCtrl",leftCtrl),("leftGui",leftGui),("leftShift",leftShift),
         ("rightAlt",rightAlt),("rightCtrl",rightCtrl),("rightGui",rightGui),("rightShift",rightShift)]
            .compactMap { $0.1 == true ? $0.0 : nil }
    }
}
