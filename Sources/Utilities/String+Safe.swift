import Foundation

extension String {
    static func safeText(_ text: String) -> String {
        let filtered = text.unicodeScalars.filter { scalar in
            // Strip control characters (U+0000-U+001F, U+007F-U+009F)
            if scalar.value <= 0x001F { return false }
            if scalar.value >= 0x007F && scalar.value <= 0x009F { return false }
            // Strip Unicode variation selector
            if scalar.value == 0xFE0F { return false }
            return true
        }
        let result = String(String.UnicodeScalarView(filtered))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? "?" : result
    }
}
