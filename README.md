# ZSA Layout Overlay POC

This repository is a research prototype for a macOS overlay that renders a live keyboard layout above every application without intercepting clicks.

## What this POC proves

- A native macOS overlay window can stay above other apps.
- The overlay can be transparent and non-interactive.
- The UI can be fed by a pluggable keyboard data source.
- The project can detect whether a local Keymapp Unix socket is present.

## What this POC does not prove yet

- Decoding ZSA Keymapp's real gRPC protocol end-to-end.
- Reading raw ZSA HID reports directly from the keyboard.
- Automatically importing your exact Oryx layout.

## Architecture sketch

The app is split into three layers:

1. Overlay window
   - AppKit `NSWindow`
   - borderless, transparent, click-through
   - visible on every space and beside fullscreen apps

2. Render model
   - a local `RenderedKeyboardLayout`
   - active layer, highlighted key positions, status text
   - independent from transport details

3. Data source
   - `KeyboardDataSource` protocol
   - `MockKeyboardDataSource` drives the demo now
   - `KeymappProbeDataSource` checks for the local socket
   - a future `KeymappGRPCDataSource` can replace the probe once the protobuf client is available

## Running

```bash
swift run zsa-layout-overlay
```

## Expected behavior

- A small overlay appears near the bottom-right of the main screen.
- Clicks pass through it to the app underneath.
- If Keymapp is not installed or its API socket is not available, the mock source keeps the overlay animated.
- If a Keymapp socket is present, the status line reports that the socket is reachable.

## Next step for real keyboard data

There are two viable paths:

1. Add a generated Swift gRPC client from `zsa/kontroll`'s `proto/keymapp.proto`.
2. Skip Keymapp and talk to the keyboard directly through `IOHIDManager`.

For a fast path to a usable overlay, the first option is better.
