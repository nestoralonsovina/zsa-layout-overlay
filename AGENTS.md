# AGENTS.md

Instructions for AI coding agents working on this repository.

## Project

A macOS menu bar app that renders a live ZSA keyboard layout overlay. Built with Swift 6, AppKit, and SwiftUI (for preferences). Uses HID to detect key presses and the Oryx API to fetch layouts.

## Commands

```bash
swift build                          # Debug build
swift build -c release               # Release build
swift test                           # Run tests
swift run zsa-layout-overlay         # Launch app
make app                             # Build .app bundle (codesigned ad-hoc)
make lint                            # Run swiftlint if installed
brew install hidapi                  # Install HID dependency
```

## Dependencies

- **hidapi** via Homebrew (`brew install hidapi`)
- The `Package.swift` uses `-I/opt/homebrew/opt/hidapi/include` (the stable Homebrew symlink — do not change this to a versioned path)

## Architecture

```
Sources/
  AppMain.swift                @main entry point
  AppDelegate.swift           NSApplicationDelegate, wires controllers
  OverlayAppController.swift   Borderless click-through overlay window (HUD level)
  OverlayViewModel.swift      @MainActor, owns layout state and pressed key set
  MenuBarController.swift     Status bar item + menu
  DataSources/
    KeyboardDataSource.swift          Protocol for fetching layouts + key events
    OryxAPIDataSource.swift           Fetches layout from ZSA GraphQL API
    ZSAHIDDataSource.swift            Reads HID reports for live key presses
    MockKeyboardDataSource.swift      Demo data for testing without hardware
    KeymappProbeDataSource.swift      Detects Keymapp socket
  Keyboards/
    KeyboardDefinition.swift          Protocol + KeyboardRegistry
    KeyboardLayoutRenderer.swift      Draws keycaps from any KeyboardDefinition
    VoyagerKeyboard.swift            ZSA Voyager definition (geometry + HID profile)
  Layouts/
    DesignTokens.swift               Colors, fonts, sizing constants
  Models/
    Models.swift                     Layer, KeymapLayer, PressedKey, etc.
  Preferences/
    PreferencesStore.swift           UserDefaults-backed settings
    PreferencesView.swift            SwiftUI preferences pane
    PreferencesWindowController.swift Window wrapper
  Utilities/
    AppFonts.swift                   Font registration
    String+Safe.swift                String helpers
  Views/
    OverlayRootView.swift            Root SwiftUI view of the overlay
    KeycapCard.swift                 Single keycap rendering
    StripedFill.swift                Striped background for layer 1 keys
  Resources/
    *.ttf                            Bundled Inter + JetBrains Mono fonts
```

## Code style

- `@MainActor` on all UI-facing types
- Avoid force-unwrapping; use `guard let` or comment why it's safe
- Keep methods small; extract domain logic into pure functions
- Swift 6 concurrency: use `async/await`, avoid shared mutable state
- Follow existing naming patterns — `Controller` for AppKit windows, `ViewModel` for observable state

## Testing

- Tests live in `Tests/`, 2 test files currently
- Run with `swift test` (no additional setup needed)
- Target `macOS 14.0+`, apple silicon runner
- Mock data sources are available for testing without hardware

## Constraints

- **macOS 14.0+ only** — uses AppKit APIs not available earlier
- **LSUIElement = true** — no Dock icon, menu bar only
- **hidapi required** — won't build without it (`brew install hidapi`)
- **CI**: GitHub Actions on `macos-latest` (see `.github/workflows/`)
- **Release**: push a `v*` tag to trigger the release workflow
