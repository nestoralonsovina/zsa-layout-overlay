# ZSA Layout Overlay

A macOS overlay that renders a live keyboard layout above all applications without intercepting clicks.

## Features

- **Live key press visualization** via HID connection to ZSA keyboards
- **Oryx layout import** from HAR capture files
- **Extensible keyboard support** — add new layouts by defining geometry and HID profile
- **Customizable appearance** — opacity, scale, position, and chrome fade delay via Preferences
- **Menu bar control** — show/hide, restart, and preferences from the status bar

## Requirements

- macOS 14.0+
- Swift 6.2 toolchain
- [hidapi](https://github.com/libusb/hidapi) (for building from source)

## Installation

### Prebuilt App Bundle

Run the export script to build a self-contained `.app` bundle:

```bash
./Scripts/export-app.sh /path/to/output
```

The script:
- Builds the release binary
- Bundles `libhidapi.0.dylib` for distribution
- Packages any available `typ.ing.har` layout file
- Generates `Info.plist` with version from the latest git tag

Copy the resulting `Voyager Overlay.app` to `/Applications` or run it from anywhere.

### Build from Source

```bash
# Install hidapi (required for HID bridge)
brew install hidapi

# Build
swift build

# Run
swift run zsa-layout-overlay

# Run tests
swift test
```

## Configuration

### Layout Import

The app needs an Oryx layout HAR file to render your keymap. You can provide it via:

1. **Preferences window** (recommended): Click the menu bar icon → Preferences → Choose HAR file
2. **Bundle it with the app**: Place `typ.ing.har` next to the executable before exporting
3. **Environment variable**: `ZSA_LAYOUT_HAR=/path/to/layout.har swift run`
4. **Shared location**: `/Users/Shared/typ.ing.har`

To capture a HAR file from Oryx:
- Open Safari/Chrome DevTools → Network tab
- Load your layout on [oryx.zsa.io](https://oryx.zsa.io)
- Right-click → Save all as HAR

### Preferences

Access via the menu bar icon or `Cmd + ,`:

- **Window Position**: Bottom Center, Bottom Left, Bottom Right
- **Scale**: Resize the overlay (50%–150%)
- **Overlay Opacity**: Transparency of the entire HUD
- **Keycap Opacity**: Transparency of individual keys
- **Chrome Fade Delay**: How long the header/footer stay visible after key activity

## Architecture

```
┌─────────────────────────────────────┐
│         OverlayWindowController      │
│  (borderless, click-through, HUD)   │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│         OverlayViewModel            │
│  (state: layout, layer, pressed)    │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│      KeyboardLayoutRenderer         │
│  (renders any KeyboardDefinition)   │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│      KeyboardDataSource (protocol)  │
│  ├─ ZSAHIDDataSource (live HID)    │
│  ├─ OryxHARDataSource (layout)     │
│  └─ MockKeyboardDataSource (demo)  │
└─────────────────────────────────────┘
```

## Extending to Other Keyboards

See [CONTRIBUTING.md](CONTRIBUTING.md) for a step-by-step guide to adding new keyboard layouts.

## Data Sources

| Source | Purpose | Status |
|--------|---------|--------|
| `ZSAHIDDataSource` | Live key presses from HID | Working for Voyager |
| `OryxHARDataSource` | Parse Oryx layout from HAR | Working |
| `MockKeyboardDataSource` | Demo animation without hardware | Working |
| `KeymappProbeDataSource` | Detect Keymapp socket presence | Detection only |

## License

MIT
