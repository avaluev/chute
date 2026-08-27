#!/usr/bin/env bash
# Assembles Chute.app WITHOUT Xcode: SwiftPM binaries + a hand-written Info.plist + ad-hoc signature.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/dist/Chute.app"
# Single source of truth: Sources/ChuteCore/Version.swift. Four hand-kept copies of this
# number is how a bundle ends up claiming a version the binary disagrees with.
VERSION="$(sed -n 's/.*static let current = "\([^"]*\)".*/\1/p' "$ROOT/Sources/ChuteCore/Version.swift")"
[ -n "$VERSION" ] || { echo "build-app: cannot read the version from Sources/ChuteCore/Version.swift" >&2; exit 1; }

cd "$ROOT"
swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# NOTE: APFS is case-insensitive — the app executable must not be a case variant of "chute".
cp "$ROOT/.build/release/ChuteApp" "$APP/Contents/MacOS/ChuteApp"
cp "$ROOT/.build/release/chute"    "$APP/Contents/MacOS/chute"
# The icon the menu bar, Notification Center and Finder all show. Generated once by
# Scripts/make-icon.swift and committed — a build never renders it.
cp "$ROOT/Resources/Chute.icns" "$APP/Contents/Resources/Chute.icns"

# ---- Finder extension -------------------------------------------------------
# swiftc, not SwiftPM: an appex's Mach-O entry point must be _NSExtensionMain, and SwiftPM cannot
# express that linker flag. There is no main.swift — NSExtensionMain is a C symbol, not callable
# from Swift.
APPEX="$APP/Contents/PlugIns/ChuteFinder.appex"
mkdir -p "$APPEX/Contents/MacOS"
# Links ChuteCore's objects so the appex draws its menu from the SAME action table the CLI and
# the tests use. -I .build/release finds the module; the .o files supply the code (SwiftPM does not
# emit a static archive for a plain target).
# Links ChuteCore's objects so the appex draws its menu from the SAME action table the CLI and the
# tests use. -I .build/release finds the module; the .o files supply the code (SwiftPM does not emit
# a static archive for a plain target).
swiftc -O -o "$APPEX/Contents/MacOS/ChuteFinder" \
    "$ROOT/Sources/ChuteFinder/ChuteFinderSync.swift" \
    -I "$ROOT/.build/release" "$ROOT"/.build/release/ChuteCore.build/*.o \
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
  <key>CFBundleIconFile</key><string>Chute</string>
  <key>NSHumanReadableCopyright</key><string>Chute — drop context into your agent.</string>
  <key>NSAppleEventsUsageDescription</key><string>Chute reads your Finder selection so it can turn it into agent context.</string>
  <!-- How the sandboxed Finder extension reaches this app. The extension cannot run git, launch
       Terminal or drive AppleScript itself — measured — so it hands the job over through here. -->
  <key>CFBundleURLTypes</key>
  <array><dict>
    <key>CFBundleURLName</key><string>dev.valuev.chute</string>
    <key>CFBundleURLSchemes</key><array><string>chute</string></array>
  </dict></array>
</dict>
</plist>
PLIST

plutil -lint "$APP/Contents/Info.plist" >/dev/null
# Inner to outer. Signing the app first and then touching the appex invalidates the app's
# signature, and the extension then refuses to load with no message anywhere.
# A stable identity if one exists (see Scripts/sign-identity.sh), otherwise ad-hoc. Ad-hoc has no
# identity at all, which is why macOS re-asks "differs from previously opened versions" after every
# single rebuild — the same app arrives looking like a different one.
IDENTITY="Chute Local Dev"
security find-identity -v -p codesigning 2>/dev/null | grep -q "$IDENTITY" || IDENTITY="-"
[ "$IDENTITY" = "-" ] && echo "note: signing ad-hoc — run ./Scripts/sign-identity.sh once to stop the repeat macOS prompts"

# The sandbox entitlement is REQUIRED: without it Finder registers the extension and then never
# loads it. Measured — an unsigned-for-sandbox appex produced no menu and no container at all.
#
# The cost of that requirement is the container ACL: it pins the exact cdhash that created the
# container, and an ad-hoc rebuild always has a new cdhash, so the next launch dies with
#   (AppSandbox) code identity <cdhash …> not in ACL for container …/Data
# and the menu silently disappears. `Scripts/sign-identity.sh` is the cure — a stable identity
# keeps the ACL valid across rebuilds. `Scripts/install.sh` checks for the mismatch either way.
# Signing with a keychain identity can block on a "codesign wants to use your key" dialog. That
# dialog is worth waiting for: measured on this machine, the Finder extension loads when signed
# with the stable identity and stops loading when signed ad-hoc, because a fresh ad-hoc identity
# no longer matches its sandbox container. So: two minutes, a message saying what to click, and
# only then a fallback.
sign() {  # target [entitlements]
  local target="$1"; shift
  if [ "$IDENTITY" != "-" ]; then
    ( codesign --force --sign "$IDENTITY" "$@" "$target" 2>/dev/null ) & local pid=$!
    disown 2>/dev/null || true
    local waited=0
    for _ in $(seq 1 120); do
      kill -0 "$pid" 2>/dev/null || break
      waited=$((waited+1))
      [ "$waited" = "3" ] && echo "   macOS is asking permission to use the \"$IDENTITY\" key — click Always Allow"
      sleep 1
    done
    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" >/dev/null 2>&1 || true
      echo "note: no answer to the keychain prompt — falling back to an ad-hoc signature."
      echo "      The Finder menu may stop appearing until the app is signed with an identity."
      echo "      Unlock it once with:  security unlock-keychain ~/Library/Keychains/login.keychain-db"
      echo "      or click Always Allow when macOS asks, or stop the prompts for good with:"
      echo "      security set-key-partition-list -S apple-tool:,apple:,codesign: -s \\"
      echo "        -k <your login password> ~/Library/Keychains/login.keychain-db"
      IDENTITY="-"
    else
      wait "$pid" 2>/dev/null && return 0
    fi
  fi
  codesign --force --sign - "$@" "$target" 2>/dev/null \
    || echo "note: signing unavailable for $target; it still runs locally"
}

sign "$APPEX" --entitlements "$ROOT/Resources/ChuteFinder.entitlements"
sign "$APP"
echo "built $APP"
du -sh "$APP" | awk '{print "size: " $1}'
