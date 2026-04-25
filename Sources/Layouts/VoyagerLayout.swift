import CoreGraphics

enum VoyagerLayout {
    static let keyWidth: CGFloat = 66
    static let keyHeight: CGFloat = 66
    static let gap: CGFloat = 6

    static var voyagerPhysicalKeyCount: Int { keySpecs.count }

    static func rect(_ x: CGFloat, _ y: CGFloat, w: CGFloat = keyWidth, h: CGFloat = keyHeight) -> CGRect {
        CGRect(x: x, y: y, width: w, height: h)
    }

    struct KeySpec {
        let id: String
        let frame: CGRect
        let rotation: Double
    }

    static let keySpecs: [KeySpec] = [
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

        KeySpec(id: "LT0", frame: rect(520, 355), rotation: -30),
        KeySpec(id: "LT1", frame: rect(566, 406), rotation: 28),

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

        KeySpec(id: "RT0", frame: rect(878, 408), rotation: -28),
        KeySpec(id: "RT1", frame: rect(825, 356), rotation: 28)
    ]
}
