import CoreGraphics

struct VoyagerKeyboard: KeyboardDefinition {
    var geometry: KeyboardGeometry { VoyagerGeometry() }
    var hidProfile: HIDDeviceProfile? { VoyagerHIDProfile.profile }
}

private struct VoyagerGeometry: KeyboardGeometry {
    let name = "Voyager"

    private static let keyWidth: CGFloat = 66
    private static let keyHeight: CGFloat = 66
    private static let gap: CGFloat = 6
    private static let thumbTopY: CGFloat = 248
    private static let leftThumbX: CGFloat = 518
    private static let rightThumbX: CGFloat = 836

    private static func rect(_ x: CGFloat, _ y: CGFloat, w: CGFloat = keyWidth, h: CGFloat = keyHeight) -> CGRect {
        CGRect(x: x, y: y, width: w, height: h)
    }

    var keySpecs: [KeySpec] {
        Self.specs
    }

    private static let specs: [KeySpec] = [
        KeySpec(id: "L00", frame: rect(26, 32), rotation: 0),
        KeySpec(id: "L01", frame: rect(26 + 1 * (keyWidth + gap), 32), rotation: 0),
        KeySpec(id: "L02", frame: rect(26 + 2 * (keyWidth + gap), 32), rotation: 0),
        KeySpec(id: "L03", frame: rect(26 + 3 * (keyWidth + gap), 10), rotation: 0),
        KeySpec(id: "L04", frame: rect(26 + 4 * (keyWidth + gap), 24), rotation: 0),
        KeySpec(id: "L05", frame: rect(26 + 5 * (keyWidth + gap), 24), rotation: 0),

        KeySpec(id: "L10", frame: rect(26, 32 + 1 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L11", frame: rect(26 + 1 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L12", frame: rect(26 + 2 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L13", frame: rect(26 + 3 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L14", frame: rect(26 + 4 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L15", frame: rect(26 + 5 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),

        KeySpec(id: "L20", frame: rect(26, 32 + 2 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L21", frame: rect(26 + 1 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L22", frame: rect(26 + 2 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L23", frame: rect(26 + 3 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L24", frame: rect(26 + 4 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L25", frame: rect(26 + 5 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),

        KeySpec(id: "L30", frame: rect(26, 32 + 3 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L31", frame: rect(26 + 1 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L32", frame: rect(26 + 2 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L33", frame: rect(26 + 3 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L34", frame: rect(26 + 4 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "L35", frame: rect(26 + 5 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),

        KeySpec(id: "LT0", frame: rect(leftThumbX, thumbTopY), rotation: 0),
        KeySpec(id: "LT1", frame: rect(leftThumbX, thumbTopY + keyHeight + gap), rotation: 0),

        KeySpec(id: "R00", frame: rect(930, 24), rotation: 0),
        KeySpec(id: "R01", frame: rect(930 + 1 * (keyWidth + gap), 24), rotation: 0),
        KeySpec(id: "R02", frame: rect(930 + 2 * (keyWidth + gap), 12), rotation: 0),
        KeySpec(id: "R03", frame: rect(930 + 3 * (keyWidth + gap), 24), rotation: 0),
        KeySpec(id: "R04", frame: rect(930 + 4 * (keyWidth + gap), 24), rotation: 0),
        KeySpec(id: "R05", frame: rect(930 + 5 * (keyWidth + gap), 24), rotation: 0),

        KeySpec(id: "R10", frame: rect(930, 32 + 1 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R11", frame: rect(930 + 1 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R12", frame: rect(930 + 2 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R13", frame: rect(930 + 3 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R14", frame: rect(930 + 4 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R15", frame: rect(930 + 5 * (keyWidth + gap), 32 + 1 * (keyHeight + gap)), rotation: 0),

        KeySpec(id: "R20", frame: rect(930, 32 + 2 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R21", frame: rect(930 + 1 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R22", frame: rect(930 + 2 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R23", frame: rect(930 + 3 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R24", frame: rect(930 + 4 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R25", frame: rect(930 + 5 * (keyWidth + gap), 32 + 2 * (keyHeight + gap)), rotation: 0),

        KeySpec(id: "R30", frame: rect(930, 32 + 3 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R31", frame: rect(930 + 1 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R32", frame: rect(930 + 2 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R33", frame: rect(930 + 3 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R34", frame: rect(930 + 4 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),
        KeySpec(id: "R35", frame: rect(930 + 5 * (keyWidth + gap), 32 + 3 * (keyHeight + gap)), rotation: 0),

        KeySpec(id: "RT0", frame: rect(rightThumbX, thumbTopY + keyHeight + gap), rotation: 0),
        KeySpec(id: "RT1", frame: rect(rightThumbX, thumbTopY), rotation: 0)
    ]
}

private enum VoyagerHIDProfile {
    static let profile = HIDDeviceProfile(
        vendorID: 12951,
        productID: 6519,
        usagePage: 65376,
        usage: 97,
        keyMatrix: [
            [-1, 0, 1, 2, 3, 4, 5],
            [-1, 6, 7, 8, 9, 10, 11],
            [-1, 12, 13, 14, 15, 16, 17],
            [-1, 18, 19, 20, 21, 22],
            [-1, -1, -1, -1, 23],
            [24, 25],
            [26, 27, 28, 29, 30, 31],
            [32, 33, 34, 35, 36, 37],
            [38, 39, 40, 41, 42, 43],
            [-1, 45, 46, 47, 48, 49],
            [-1, -1, 44, -1, -1, -1, -1],
            [-1, -1, -1, -1, -1, 50, 51]
        ]
    )
}
