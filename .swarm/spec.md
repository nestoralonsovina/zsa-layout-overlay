# Specification: ZSA Layout Overlay

A macOS overlay that displays a live ZSA Voyager keyboard layout as a transparent HUD.

## Functional Requirements

- FR-001: Repository MUST have a .gitignore excluding build artifacts, macOS system files, scraped website data, and IDE files
- FR-002: The overlay MUST render a live keyboard layout above all applications without intercepting clicks
- FR-003: The overlay MUST read real-time keypresses and layer changes from the ZSA Voyager via hidapi/HID bridge
- FR-004: The overlay chrome MUST auto-fade after inactivity and re-appear on keypress
- FR-005: Layout data MUST be loadable from HAR capture files

## Success Criteria

- SC-001: `git status` shows only source files, not build artifacts or scraped data
- SC-002: Overlay renders on screen and clicks pass through to underlying windows
