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
</dict>
</plist>
PLIST

plutil -lint "$APP/Contents/Info.plist" >/dev/null
codesign --force --deep --sign - "$APP" 2>/dev/null || echo "note: ad-hoc signing unavailable; app still runs locally"
echo "built $APP"
du -sh "$APP" | awk '{print "size: " $1}'
