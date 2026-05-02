import Foundation
import SwiftUI

@MainActor
final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()

    private let defaults = UserDefaults.standard

    // MARK: - Window Position

    @Published var positionX: Double {
        didSet { defaults.set(positionX, forKey: Keys.positionX) }
    }

    @Published var positionY: Double {
        didSet { defaults.set(positionY, forKey: Keys.positionY) }
    }

    /// When true, overlay follows whichever screen has the active app
    @Published var followFocusedScreen: Bool {
        didSet { defaults.set(followFocusedScreen, forKey: Keys.followFocusedScreen) }
    }

    // MARK: - Appearance

    @Published var overlayOpacity: Double {
        didSet { defaults.set(overlayOpacity, forKey: Keys.overlayOpacity) }
    }

    @Published var keycapOpacity: Double {
        didSet { defaults.set(keycapOpacity, forKey: Keys.keycapOpacity) }
    }

    @Published var chromeFadeDelay: Double {
        didSet { defaults.set(chromeFadeDelay, forKey: Keys.chromeFadeDelay) }
    }

    @Published var scaleMultiplier: Double {
        didSet { defaults.set(scaleMultiplier, forKey: Keys.scaleMultiplier) }
    }

    // MARK: - Layout Source

    /// Oryx share URL or layout hash ID
    @Published var layoutURL: String? {
        didSet {
            if let url = layoutURL {
                defaults.set(url, forKey: Keys.layoutURL)
            } else {
                defaults.removeObject(forKey: Keys.layoutURL)
            }
        }
    }

    // MARK: - HAR Path

    // MARK: - Init

    private init() {
        self.positionX = defaults.object(forKey: Keys.positionX) as? Double ?? 0.5
        self.positionY = defaults.object(forKey: Keys.positionY) as? Double ?? 0.0
        self.followFocusedScreen = defaults.object(forKey: Keys.followFocusedScreen) as? Bool ?? true
        self.overlayOpacity = defaults.object(forKey: Keys.overlayOpacity) as? Double ?? 1.0
        self.keycapOpacity = defaults.object(forKey: Keys.keycapOpacity) as? Double ?? 1.0
        self.chromeFadeDelay = defaults.object(forKey: Keys.chromeFadeDelay) as? Double ?? 2.4
        self.scaleMultiplier = defaults.object(forKey: Keys.scaleMultiplier) as? Double ?? 1.0
        self.layoutURL = defaults.string(forKey: Keys.layoutURL)
    }

    func resetToDefaults() {
        positionX = 0.5
        positionY = 0.0
        followFocusedScreen = true
        overlayOpacity = 1.0
        keycapOpacity = 1.0
        chromeFadeDelay = 2.4
        scaleMultiplier = 1.0
        layoutURL = nil
    }

    // MARK: - Keys

    private enum Keys {
        static let positionX = "positionX"
        static let positionY = "positionY"
        static let followFocusedScreen = "followFocusedScreen"
        static let overlayOpacity = "overlayOpacity"
        static let keycapOpacity = "keycapOpacity"
        static let chromeFadeDelay = "chromeFadeDelay"
        static let scaleMultiplier = "scaleMultiplier"
        static let layoutURL = "layoutURL"
    }
}
