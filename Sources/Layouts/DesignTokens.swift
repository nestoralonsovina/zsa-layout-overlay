import CoreGraphics
import SwiftUI

enum DesignTokens {
    // MARK: - Font Families
    enum Font {
        static let header = "Inter"
        static let mono = "JetBrains Mono"
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
        static let keyboardCanvasWidth: CGFloat = 1420
        static let keyboardCanvasHeight: CGFloat = 540
        static let hudWidth: CGFloat = 700
        static let hudHeight: CGFloat = 250
        static let keyboardScale: CGFloat = 0.42
    }

    // MARK: - Radii
    enum Radius {
        static let hudPanel: CGFloat = 20
        static let keyboardClip: CGFloat = 16
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
        static let hudVertical: CGFloat = 12
        static let badgeHorizontal: CGFloat = 8
        static let badgeVertical: CGFloat = 4
    }

    // MARK: - Animation
    enum Animation {
        static let chromeShow: Double = 0.18
        static let chromeHide: Double = 0.24
        static let chromeFadeDelay: Double = 2.0
    }

    // MARK: - Opacity
    enum Opacity {
        // HUD chrome background
        static let chromeBackground: Double = 0.16
        static let chromeBorder: Double = 0.22
        // Text
        static let headerPrimary: Double = 0.82
        static let headerSecondary: Double = 0.50
        static let badgeLabel: Double = 0.75
        static let badgeBackground: Double = 0.28
        static let statusSecondary: Double = 0.45
        static let footerLabel: Double = 0.34
        // Keycaps
        static let keycapStroke: Double = 0.12
        static let keycapEmoji: Double = 0.70
        static let keycapText: Double = 0.82
        static let keycapTag: Double = 0.58
        static let keycapModifier: Double = 0.80
        static let keycapDisabled: Double = 0.45
        static let keycapTransparent: Double = 0.20
        static let keycapBackground: Double = 0.92
        // Error banner
        static let errorBackground: Double = 0.85
        static let errorText: Double = 0.90
        static let errorDismissIcon: Double = 0.45
    }

    // MARK: - Shadows
    enum Shadow {
        static let hudRadius: CGFloat = 18
        static let hudY: CGFloat = 8
        static let hudOpacity: Double = 0.08
    }
}
