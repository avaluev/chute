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

# ---- Finder extension -------------------------------------------------------
# swiftc, not SwiftPM: an appex's Mach-O entry point must be _NSExtensionMain, and SwiftPM cannot
# express that linker flag. There is no main.swift — NSExtensionMain is a C symbol, not callable
# from Swift.
APPEX="$APP/Contents/PlugIns/ChuteFinder.appex"
mkdir -p "$APPEX/Contents/MacOS"
swiftc -O -o "$APPEX/Contents/MacOS/ChuteFinder" \
    "$ROOT/Sources/ChuteFinder/ChuteFinderSync.swift" \
    -Xlinker -e -Xlinker _NSExtensionMain

cat > "$APPEX/Contents/Info.plist" <<APPEXPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>ChuteFinder</string>
  <key>CFBundleDisplayName</key><string>Chute</string>
  <key>CFBundleIdentifier</key><string>dev.valuev.chute.finder</string>
  <key>CFBundleExecutable</key><string>ChuteFinder</string>
  <key>CFBundlePackageType</key><string>XPC!</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <!-- LSUIElement, NSPrincipalClass and the empty NSExtensionAttributes are all present in Google
       Drive's shipping extension and were all missing here; without them it does not register. -->
  <key>LSUIElement</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSExtension</key>
  <dict>
    <key>NSExtensionAttributes</key><dict/>
    <key>NSExtensionPointIdentifier</key><string>com.apple.FinderSync</string>
    <key>NSExtensionPrincipalClass</key><string>ChuteFinderSync</string>
  </dict>
</dict>
</plist>
APPEXPLIST
plutil -lint "$APPEX/Contents/Info.plist" >/dev/null

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
# Inner to outer. Signing the app first and then touching the appex invalidates the app's
# signature, and the extension then refuses to load with no message anywhere.
codesign --force --sign - --entitlements "$ROOT/Resources/ChuteFinder.entitlements" "$APPEX" \
    2>/dev/null || echo "note: appex ad-hoc signing unavailable"
codesign --force --sign - "$APP"   2>/dev/null || echo "note: ad-hoc signing unavailable; app still runs locally"
echo "built $APP"
du -sh "$APP" | awk '{print "size: " $1}'
