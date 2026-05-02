import CoreGraphics
import SwiftUI

enum DesignTokens {
    // MARK: - Font Families
    enum Font {
        static let headerMedium = AppFonts.interMedium
        static let headerSemibold = AppFonts.interSemiBold
        static let headerBold = AppFonts.interBold
        static let monoMedium = AppFonts.jetBrainsMonoMedium
        static let system = "system"
    }

    // MARK: - Font Sizes
    enum FontSize {
        // HUD chrome
        static let hudTitle: CGFloat = 18
        static let hudSubtitle: CGFloat = 12
        static let hudCaption: CGFloat = 10
        // Error banner
        static let errorMessage: CGFloat = 11
        static let errorDismiss: CGFloat = 14
        // Key labels
        static let keyLabelXL: CGFloat = 26
        static let keyLabelL: CGFloat = 21
        static let keyLabelM: CGFloat = 19
        static let keyLabelS: CGFloat = 15
        static let keyLabelXS: CGFloat = 14
        static let keyLabelXXS: CGFloat = 12
        static let keyTag: CGFloat = 7.5
        static let keyGlyph: CGFloat = 13
        // Modifier sizes
        static let modifierLarge: CGFloat = 18
        static let modifierMedium: CGFloat = 13
        static let modifierSmall: CGFloat = 10
    }

    // MARK: - Layout
    enum Layout {
        static let minHUDWidth: CGFloat = 760
        static let preferredHUDWidth: CGFloat = 920
        static let minHUDHeight: CGFloat = 290
        static let preferredHUDHeight: CGFloat = 330
        static let maxKeyboardScale: CGFloat = 0.62
        static let minKeyboardScale: CGFloat = 0.38
        static let keyboardHorizontalInset: CGFloat = 18
        static let keyboardVerticalInset: CGFloat = 14
        static let chromeReservedHeight: CGFloat = 74
    }

    // MARK: - Radii
    enum Radius {
        static let hudPanel: CGFloat = 24
        static let keyboardClip: CGFloat = 18
        static let keycap: CGFloat = 9
        static let errorBanner: CGFloat = 8
    }

    // MARK: - Spacing
    enum Spacing {
        static let hudVStack: CGFloat = 10
        static let hudHStack: CGFloat = 16
        static let headerLeading: CGFloat = 2
        static let keycapLabelGap: CGFloat = 4
        static let keycapPadding: CGFloat = 6
        static let errorBannerHStack: CGFloat = 8
        static let errorBannerHorizontal: CGFloat = 10
        static let errorBannerVertical: CGFloat = 6
        static let hudVertical: CGFloat = 16
        static let badgeHorizontal: CGFloat = 10
        static let badgeVertical: CGFloat = 5
    }

    // MARK: - Animation
    enum Animation {
        static let chromeShow: Double = 0.18
        static let chromeHide: Double = 0.24
        static let chromeFadeDelay: Double = 2.4
    }

    // MARK: - Opacity
    enum Opacity {
        // HUD chrome background
        static let chromeMaterialTint: Double = 0.14
        static let chromeBackground: Double = 0.26
        static let chromeBorder: Double = 0.32
        // Text
        static let headerPrimary: Double = 0.96
        static let headerSecondary: Double = 0.72
        static let badgeLabel: Double = 0.90
        static let badgeBackground: Double = 0.50
        static let statusSecondary: Double = 0.68
        static let footerLabel: Double = 0.62
        // Keycaps
        static let keycapStroke: Double = 0.18
        static let keycapEmoji: Double = 0.70
        static let keycapText: Double = 0.90
        static let keycapTag: Double = 0.62
        static let keycapModifier: Double = 0.86
        static let keycapDisabled: Double = 0.45
        static let keycapTransparent: Double = 0.34
        static let keycapBackground: Double = 0.97
        // Error banner
        static let errorBackground: Double = 0.85
        static let errorText: Double = 0.90
        static let errorDismissIcon: Double = 0.45
    }

    // MARK: - Shadows
    enum Shadow {
        static let hudRadius: CGFloat = 28
        static let hudY: CGFloat = 12
        static let hudOpacity: Double = 0.14
    }
}
