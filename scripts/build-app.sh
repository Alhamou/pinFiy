#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release --product PinFiyApp
BIN_DIR="$(swift build -c release --product PinFiyApp --show-bin-path)"
APP="PinFiy.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/PinFiyApp" "$APP/Contents/MacOS/PinFiy"

ICON_SRC="docs/pinFiy-512.png"
ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
write_icon() {
  sips -z "$1" "$1" "$ICON_SRC" --out "$ICONSET/$2" >/dev/null
}
write_icon 16 icon_16x16.png
write_icon 32 icon_16x16@2x.png
write_icon 32 icon_32x32.png
write_icon 64 icon_32x32@2x.png
write_icon 128 icon_128x128.png
write_icon 256 icon_128x128@2x.png
write_icon 256 icon_256x256.png
write_icon 512 icon_256x256@2x.png
write_icon 512 icon_512x512.png
write_icon 1024 icon_512x512@2x.png
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$(dirname "$ICONSET")"
cat > "$APP/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>PinFiy</string>
  <key>CFBundleIdentifier</key>
  <string>app.pinfiy.PinFiy</string>
  <key>CFBundleName</key>
  <string>PinFiy</string>
  <key>CFBundleDisplayName</key>
  <string>pinFiy</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright © 2026 pinFiy contributors. MIT License.</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
EOF
codesign --force --sign - "$APP"
