<!-- PLAN_HASH: 1jvglp0043htj -->
# ZSA Layout Overlay
Swarm: default
Phase: 1 [PENDING] | Updated: 2026-04-25T17:05:45.360Z

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
