#!/bin/zsh

set -euo pipefail
setopt null_glob

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Voyager Overlay"
APP_BUNDLE_NAME="${APP_NAME}.app"
EXECUTABLE_NAME="zsa-layout-overlay"
DEFAULT_OUTPUT_DIR="/Users/Shared"
OUTPUT_DIR="${1:-$DEFAULT_OUTPUT_DIR}"
APP_DIR="$OUTPUT_DIR/$APP_BUNDLE_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
EXECUTABLE_PATH="$ROOT_DIR/.build/debug/$EXECUTABLE_NAME"
HIDAPI_SOURCE="/opt/homebrew/lib/libhidapi.0.dylib"
HIDAPI_DEST="$FRAMEWORKS_DIR/libhidapi.0.dylib"
HAR_SOURCE="${ZSA_LAYOUT_HAR:-$ROOT_DIR/typ.ing.har}"
RESOURCE_BUNDLES=("$ROOT_DIR"/.build/debug/ZSALayoutOverlay_*.bundle)
PLIST_PATH="$CONTENTS_DIR/Info.plist"
FORCE_REBUILD="${ZSA_EXPORT_REBUILD:-0}"

mkdir -p "$OUTPUT_DIR"

if [[ "$FORCE_REBUILD" == "1" || ! -x "$EXECUTABLE_PATH" ]]; then
  env \
    CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build-cache/clang-module-cache" \
    SWIFTPM_CUSTOM_CACHE_PATH="$ROOT_DIR/.build-cache/swiftpm-cache" \
    swift build
fi

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Missing built executable at $EXECUTABLE_PATH" >&2
  exit 1
fi

if [[ ! -f "$HIDAPI_SOURCE" ]]; then
  echo "Missing hidapi dylib at $HIDAPI_SOURCE" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$FRAMEWORKS_DIR" "$RESOURCES_DIR"

cp "$EXECUTABLE_PATH" "$MACOS_DIR/$EXECUTABLE_NAME"
cp -L "$HIDAPI_SOURCE" "$HIDAPI_DEST"

if [[ -f "$HAR_SOURCE" ]]; then
  cp "$HAR_SOURCE" "$RESOURCES_DIR/typ.ing.har"
else
  echo "Warning: no typ.ing.har found at $HAR_SOURCE; app will look for /Users/Shared/typ.ing.har or ~/Downloads/typ.ing.har at runtime." >&2
fi

for bundle in "${RESOURCE_BUNDLES[@]}"; do
  if [[ -d "$bundle" ]]; then
    cp -R "$bundle" "$RESOURCES_DIR/"
  fi
done

/usr/bin/install_name_tool \
  -change /opt/homebrew/opt/hidapi/lib/libhidapi.0.dylib \
  @executable_path/../Frameworks/libhidapi.0.dylib \
  "$MACOS_DIR/$EXECUTABLE_NAME"

cat > "$PLIST_PATH" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>Voyager Overlay</string>
  <key>CFBundleExecutable</key>
  <string>zsa-layout-overlay</string>
  <key>CFBundleIdentifier</key>
  <string>local.nestoralonsovina.voyager-overlay</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Voyager Overlay</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

/usr/bin/plutil -lint "$PLIST_PATH" >/dev/null
/usr/bin/codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "Exported app bundle:"
echo "  $APP_DIR"
