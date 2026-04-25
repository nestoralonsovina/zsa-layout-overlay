<!-- PLAN_HASH: 35h4407u35ygr -->
# ZSA Layout Overlay
Swarm: default
Phase: 1 [PENDING] | Updated: 2026-04-25T19:18:14.516Z

---
## Phase 1: Repository Setup [PENDING]
- [ ] 1.1: Add a proper .gitignore for Swift/SwiftUI macOS project with HID bridge, build artifacts, scraped website data, and macOS system files [SMALL]

---
## Phase 2: UI Architecture & Design Cleanup [COMPLETE]
- [x] 2.1: Create Utilities/String+Safe.swift with a single deduplicated safeText() function handling control characters, private-use codepoints, and Unicode variation selectors without stripping legitimate symbols/brackets [SMALL] (depends: 2.3)
- [x] 2.2: Extract KeycapCard (lines 163-369) and StripedFill (lines 376-392) from OverlayRootView.swift into Views/KeycapCard.swift and Views/StripedFill.swift [MEDIUM] (depends: 2.3)
- [x] 2.3: Organize Sources/ into subdirectories — create DataSources/, Views/, Models/, Utilities/, Layouts/ directories and move files: DataSources (KeyboardDataSource, MockKeyboardDataSource, ZSAHIDDataSource, OryxHARDataSource, KeymappProbeDataSource), Views (OverlayRootView), Models (Models), Layouts (empty, for task 2.4). Root files stay: AppMain, AppDelegate, OverlayAppController, OverlayViewModel. Create git checkpoint before starting. [MEDIUM]
- [x] 2.4: Extract keySpecs array (lines 151-227) and layout constants (keyWidth, keyHeight, gap, rect helper) from Models.swift into Layouts/VoyagerLayout.swift with a VoyagerLayout enum containing static properties [MEDIUM] (depends: 2.3)
- [x] 2.5: Add ErrorState enum (none, warning, error) and error callback to KeyboardDataSource protocol. Update OverlayViewModel to aggregate errors from all data sources and expose them to the UI. Update ZSAHIDDataSource to report hidapi errors through the callback. [MEDIUM] (depends: 2.3)
- [x] 2.6: Visual design pass: extract design tokens (font sizes, spacings, radii, durations) into Layouts/DesignTokens.swift. Refine chrome fade animation timing. Ensure all keycap positions respect 6px gap consistently. Add OpacityModifier enum for consistent transparency values. [MEDIUM] (depends: 2.1, 2.2, 2.4)

---
## Phase 3: Menu Bar & Build System [COMPLETE]
- [x] 3.1: Add Makefile at repo root with .PHONY build, run, clean, install, lint targets wrapping swift build/run/swiftlint. Add .swiftlint.yml with basic config (opt_in_rules: empty_string, redundant_nil_coalescing). make lint runs swiftlint --quiet or prints skip message if swiftlint not installed. [SMALL]
- [x] 3.2: Add NSStatusItem menu bar icon using SF Symbol 'keyboard' with Show/Hide Overlay, Restart, and Quit menu items. Create MenuBarController managing status item lifecycle. Change applicationShouldTerminateAfterLastWindowClosed to false so hiding window does not kill app. Wire Show/Hide to toggle window visibility. Wire Quit to NSApp.terminate. Wire Restart to call OverlayAppController.restart(). [MEDIUM] (depends: 3.3)
- [x] 3.3: Create git checkpoint. Add stored Task? handle to OverlayAppController for cancellation. Add restart() that cancels active Task, reinitializes data sources, clears errors, and starts fresh. Add reset() to OverlayViewModel clearing capture, pressedKeyIndices, activeErrors, restoring fallback status. Add hideWindow() to OverlayWindowController calling orderOut(nil). [MEDIUM]
