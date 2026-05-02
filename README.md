# ZSA Layout Overlay

A macOS overlay that renders a live keyboard layout above all applications without intercepting clicks.

## Features

- **Live key press visualization** via HID connection to ZSA keyboards
- **Direct layout loading from Oryx** — paste your share URL, no file export needed
- **Extensible keyboard support** — add new layouts by defining geometry and HID profile
- **Customizable appearance** — opacity, scale, position, and fade delay via Preferences
- **Auto-follows focused screen** — overlay moves to whichever display has the active app
- **Menu bar control** — show/hide, restart, and preferences from the status bar

## Requirements

- macOS 14.0+
- Swift 6.2 toolchain
- [hidapi](https://github.com/libusb/hidapi) (for building from source)

## Installation

### Prebuilt App Bundle

```bash
./Scripts/export-app.sh /path/to/output
```

The script builds the release binary, bundles hidapi, and generates Info.plist.

### Build from Source

```bash
brew install hidapi
swift build
swift run zsa-layout-overlay
```

## Configuration

### Layout Loading

1. Open your layout on [oryx.zsa.io](https://oryx.zsa.io)
2. Click **Share** and copy the link
3. Paste it into Preferences → Layout Source (or menu bar → Preferences...)
4. The app fetches your layout and metadata directly from ZSA's API

The share URL looks like: `https://configure.zsa.io/voyager/layouts/LmpYy/latest`

You can also paste just the layout ID (e.g. `LmpYy`).

### Preferences

Access via `Cmd + ,` or the menu bar icon:

- **Follow focused screen** — overlay follows the active app across displays
- **X / Y position** — percentage-based placement (0% = left/bottom)
- **Scale** — resize the overlay (50%–150%)
- **Overlay / Keys opacity** — transparency controls
- **Fade delay** — how long before overlay fades after keyboard inactivity

## Architecture

```
OverlayWindowController  (borderless, click-through HUD)
    OverlayViewModel      (state: layout, layer, pressed keys)
        KeyboardLayoutRenderer  (renders any KeyboardDefinition)
            KeyboardDataSource  (protocol)
                ├─ OryxAPIDataSource   (fetches from oryx.zsa.io)
                ├─ ZSAHIDDataSource    (live key presses)
                └─ MockKeyboardDataSource (demo without hardware)
```

## Data Sources

| Source | Purpose |
|--------|---------|
| `OryxAPIDataSource` | Fetch layout from ZSA GraphQL API |
| `ZSAHIDDataSource` | Live key presses from HID |
| `MockKeyboardDataSource` | Demo animation without hardware |
| `KeymappProbeDataSource` | Detect Keymapp socket presence |

## Extending to Other Keyboards

See [CONTRIBUTING.md](CONTRIBUTING.md) for adding new keyboard layouts.

## License

MIT
