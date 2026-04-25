import CoreText
import Foundation

enum AppFonts {
    static let interMedium = "Inter-Medium"
    static let interSemiBold = "Inter-SemiBold"
    static let interBold = "Inter-Bold"
    static let jetBrainsMonoMedium = "JetBrainsMono-Medium"

    private static let bundledFonts = [
        "Inter-Medium.ttf",
        "Inter-SemiBold.ttf",
        "Inter-Bold.ttf",
        "JetBrainsMono-Medium.ttf"
    ]

    static func registerBundledFonts() {
        for fontFile in bundledFonts {
            guard let url = Bundle.module.url(forResource: fontFile, withExtension: nil) else {
                continue
            }

            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
