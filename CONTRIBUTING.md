# Contributing

Thank you for considering a contribution. This project is intentionally small—adding a new keyboard layout should take less than 100 lines of Swift.

## Adding a New Keyboard Layout

To add support for a new ZSA keyboard (or any keyboard that speaks the same HID protocol), you need to define two things:

1. **Geometry** — where the keys are drawn on screen
2. **HID Profile** — how the keyboard's raw HID reports map to those keys

### Step-by-step

1. Create `Sources/Keyboards/YourKeyboard.swift`
2. Conform to `KeyboardDefinition`
3. Register it in `KeyboardRegistry.all`

### Example: Minimal Keyboard Definition

```swift
import CoreGraphics

struct CorneKeyboard: KeyboardDefinition {
    var geometry: KeyboardGeometry { CorneGeometry() }
    var hidProfile: HIDDeviceProfile? { CorneHIDProfile.profile }
}

private struct CorneGeometry: KeyboardGeometry {
    let name = "Corne"

    var keySpecs: [KeySpec] {
        [
            KeySpec(id: "L00", frame: CGRect(x: 26, y: 32, width: 66, height: 66), rotation: 0),
            // ... one per physical key
        ]
    }
}

private enum CorneHIDProfile {
    static let profile = HIDDeviceProfile(
        vendorID: 12951,
        productID: 0,      // replace with actual product ID
        usagePage: 65376,
        usage: 97,
        keyMatrix: [
            // row 0: [col0, col1, col2, ...] -> physical key index, or -1 for no key
            [-1, 0, 1, 2, 3, 4, 5],
            // ... one row per matrix row
        ]
    )
}
```

### Geometry tips

- Use `CGRect(x, y, width, height)` for each key
- Coordinates are in a virtual canvas; the overlay scales to fit the screen
- Keep `width` and `height` consistent for uniform keys
- `rotation` is in degrees; most keys are `0`

### HID Profile tips

- `vendorID` and `productID` come from `System Information.app > USB` or `ioreg -p IOUSB`
- `usagePage` and `usage` filter the HID interface; for ZSA keyboards these are usually `65376` and `97`
- `keyMatrix` maps `(row, column)` from the HID report to the `physical key index` that matches the order of `keySpecs`

The physical key index for `keySpecs[0]` is `0`, `keySpecs[1]` is `1`, etc. The matrix uses `-1` for positions that have no physical key.

### Finding your keyboard's matrix

The easiest way is to log raw HID reports and press keys one at a time. Enable `eventLoggingEnabled` in `ZSAHIDDataSource`, or use the `zsa-hid-probe` executable target to read raw bytes.

### Register the keyboard

In `Sources/Keyboards/KeyboardDefinition.swift`, add your keyboard to the registry:

```swift
enum KeyboardRegistry {
    static let all: [KeyboardDefinition] = [
        VoyagerKeyboard(),
        CorneKeyboard(),   // <-- add here
    ]
    // ...
}
```

No other files need to change. The renderer, data sources, and window management are all keyboard-agnostic.

## Code Style

- Follow Swift 6 strict concurrency where possible
- Mark UI-facing types with `@MainActor`
- No force-unwrapping without a comment explaining why it's safe
- Keep methods small; extract domain logic into pure functions

## Questions?

Open an issue with the `question` label.
