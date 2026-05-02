import CoreGraphics

struct KeySpec: Hashable {
    let id: String
    let frame: CGRect
    let rotation: Double
}

protocol KeyboardGeometry {
    var name: String { get }
    var keySpecs: [KeySpec] { get }
}

struct HIDDeviceProfile {
    let vendorID: Int
    let productID: Int
    let usagePage: Int
    let usage: Int
    let keyMatrix: [[Int]]

    var physicalKeyCount: Int {
        keyMatrix.flatMap { $0 }.filter { $0 >= 0 }.count
    }
}

protocol KeyboardDefinition {
    var geometry: KeyboardGeometry { get }
    var hidProfile: HIDDeviceProfile? { get }
}

@MainActor
enum KeyboardRegistry {
    static let all: [KeyboardDefinition] = [
        VoyagerKeyboard()
    ]

    static func find(byName name: String) -> KeyboardDefinition? {
        all.first { $0.geometry.name == name }
    }

    static var `default`: KeyboardDefinition { all[0] }
}
