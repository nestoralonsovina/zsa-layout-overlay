import Foundation
import SwiftUI

@MainActor
final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()

    private let defaults = UserDefaults.standard

    // MARK: - Window Position

    enum WindowPosition: String, CaseIterable, Identifiable {
        case bottomCenter = "bottom-center"
        case bottomLeft = "bottom-left"
        case bottomRight = "bottom-right"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .bottomCenter: return "Bottom Center"
            case .bottomLeft: return "Bottom Left"
            case .bottomRight: return "Bottom Right"
            }
        }
    }

    @Published var windowPosition: WindowPosition {
        didSet {
            defaults.set(windowPosition.rawValue, forKey: Keys.windowPosition)
        }
    }

    // MARK: - Appearance

    @Published var overlayOpacity: Double {
        didSet {
            defaults.set(overlayOpacity, forKey: Keys.overlayOpacity)
        }
    }

    @Published var keycapOpacity: Double {
        didSet {
            defaults.set(keycapOpacity, forKey: Keys.keycapOpacity)
        }
    }

    @Published var chromeFadeDelay: Double {
        didSet {
            defaults.set(chromeFadeDelay, forKey: Keys.chromeFadeDelay)
        }
    }

    @Published var scaleMultiplier: Double {
        didSet {
            defaults.set(scaleMultiplier, forKey: Keys.scaleMultiplier)
        }
    }

    // MARK: - HAR Path

    @Published var harFilePath: String? {
        didSet {
            if let path = harFilePath {
                defaults.set(path, forKey: Keys.harFilePath)
            } else {
                defaults.removeObject(forKey: Keys.harFilePath)
            }
        }
    }

    // MARK: - Init

    private init() {
        self.windowPosition = WindowPosition(
            rawValue: defaults.string(forKey: Keys.windowPosition) ?? "bottom-center"
        ) ?? .bottomCenter

        self.overlayOpacity = defaults.object(forKey: Keys.overlayOpacity) as? Double ?? 1.0
        self.keycapOpacity = defaults.object(forKey: Keys.keycapOpacity) as? Double ?? 1.0
        self.chromeFadeDelay = defaults.object(forKey: Keys.chromeFadeDelay) as? Double ?? 2.4
        self.scaleMultiplier = defaults.object(forKey: Keys.scaleMultiplier) as? Double ?? 1.0
        self.harFilePath = defaults.string(forKey: Keys.harFilePath)
    }

    func resetToDefaults() {
        windowPosition = .bottomCenter
        overlayOpacity = 1.0
        keycapOpacity = 1.0
        chromeFadeDelay = 2.4
        scaleMultiplier = 1.0
        harFilePath = nil
    }

    // MARK: - Keys

    private enum Keys {
        static let windowPosition = "windowPosition"
        static let overlayOpacity = "overlayOpacity"
        static let keycapOpacity = "keycapOpacity"
        static let chromeFadeDelay = "chromeFadeDelay"
        static let scaleMultiplier = "scaleMultiplier"
        static let harFilePath = "harFilePath"
    }
}
