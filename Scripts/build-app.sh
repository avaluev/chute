#!/usr/bin/env bash
# Assembles Chute.app WITHOUT Xcode: SwiftPM binaries + a hand-written Info.plist + ad-hoc signature.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/dist/Chute.app"
VERSION="0.1.0"

cd "$ROOT"
swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# NOTE: APFS is case-insensitive — the app executable must not be a case variant of "chute".
cp "$ROOT/.build/release/ChuteApp" "$APP/Contents/MacOS/ChuteApp"
cp "$ROOT/.build/release/chute"    "$APP/Contents/MacOS/chute"

service_entry() {  # $1 = menu title, $2 = selector, $3 = send types
  cat <<PLIST
    <dict>
      <key>NSMenuItem</key><dict><key>default</key><string>$1</string></dict>
      <key>NSMessage</key><string>$2</string>
      <key>NSPortName</key><string>Chute</string>
      <key>NSSendFileTypes</key><array>$3</array>
    </dict>
PLIST
}
ITEM='<string>public.item</string>'
FOLDER='<string>public.folder</string>'

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Chute</string>
  <key>CFBundleDisplayName</key><string>Chute</string>
  <key>CFBundleIdentifier</key><string>dev.valuev.chute</string>
  <key>CFBundleExecutable</key><string>ChuteApp</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHumanReadableCopyright</key><string>Chute — drop context into your agent.</string>
  <key>NSAppleEventsUsageDescription</key><string>Chute reads your Finder selection so it can turn it into agent context.</string>
  <key>NSServices</key>
  <array>
$(service_entry "Chute – Copy Paths for Prompt" "copyPaths" "$ITEM")
$(service_entry "Chute – Bundle Context (XML)" "bundleContext" "$ITEM")
$(service_entry "Chute – New File from Clipboard" "newFromClipboard" "$FOLDER")
$(service_entry "Chute – Unpack Markdown Here" "unpackHere" "$FOLDER")
$(service_entry "Chute – Sandbox + Agent (yolo)" "sandboxHere" "$FOLDER")
$(service_entry "Chute – Checkpoint Before Agent" "checkpointHere" "$FOLDER")
  </array>
</dict>
</plist>
PLIST

plutil -lint "$APP/Contents/Info.plist" >/dev/null
codesign --force --deep --sign - "$APP" 2>/dev/null || echo "note: ad-hoc signing unavailable; app still runs locally"
echo "built $APP"
du -sh "$APP" | awk '{print "size: " $1}'
