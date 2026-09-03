#!/usr/bin/env bash
# Assembles Chute.app WITHOUT Xcode: SwiftPM binaries + a hand-written Info.plist + ad-hoc signature.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/dist/Chute.app"
# Single source of truth: Sources/ChuteCore/Version.swift. Four hand-kept copies of this
# number is how a bundle ends up claiming a version the binary disagrees with.
VERSION="$(sed -n 's/.*static let current = "\([^"]*\)".*/\1/p' "$ROOT/Sources/ChuteCore/Version.swift")"
[ -n "$VERSION" ] || { echo "build-app: cannot read the version from Sources/ChuteCore/Version.swift" >&2; exit 1; }

# WHICH BUILD THIS IS, stamped at build time. `VERSION` is hand-bumped and stayed "0.2.0" across
# every commit of 2026-08-28 — so it cannot tell you the app in ~/Applications is ninety minutes
# older than the tree it came from. That gap cost a session: Recent Copies was fixed in 0d23f86 at
# 21:09 and the running app had been built at 20:14, so a bug with a passing test and a shipped fix
# still looked broken. `chute doctor` reads this back, and `--report` carries it into every bug
# report, which is the same question a stranger's report has to answer.
BUILD="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
git -C "$ROOT" diff --quiet HEAD 2>/dev/null || BUILD="$BUILD-dirty"
BUILT_AT="$(date -u +%Y-%m-%dT%H:%MZ)"

cd "$ROOT"
swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# NOTE: APFS is case-insensitive — the app executable must not be a case variant of "chute".
cp "$ROOT/.build/release/ChuteApp" "$APP/Contents/MacOS/ChuteApp"
cp "$ROOT/.build/release/chute"    "$APP/Contents/MacOS/chute"
# STRIP BEFORE SIGNING, always. Measured 2026-09-01: `strip -x` takes each Swift binary from
# ~1.08 MB to ~744 KB — 31%, and about a megabyte off a 3.3 MB bundle — because a release Swift
# binary ships a large local symbol table nothing at runtime reads. `-x` keeps the global and
# undefined symbols, which is what the appex's `_NSExtensionMain` entry point and every dynamic
# link need; a bare `strip` would take those too.
#
# ORDER IS LOAD-BEARING: stripping a signed binary invalidates its signature and the extension
# then refuses to load with no message anywhere. Strip here, sign at the bottom, never the reverse.
strip -x "$APP/Contents/MacOS/ChuteApp" "$APP/Contents/MacOS/chute"
# The icon the menu bar, Notification Center and Finder all show. Generated once by
# Scripts/make-icon.swift and committed — a build never renders it.
cp "$ROOT/Resources/Chute.icns" "$APP/Contents/Resources/Chute.icns"

# ---- Finder extension -------------------------------------------------------
# swiftc, not SwiftPM: an appex's Mach-O entry point must be _NSExtensionMain, and SwiftPM cannot
# express that linker flag. There is no main.swift — NSExtensionMain is a C symbol, not callable
# from Swift.
APPEX="$APP/Contents/PlugIns/ChuteFinder.appex"
mkdir -p "$APPEX/Contents/MacOS"
# Links ChuteCore's objects so the appex draws its menu from the SAME action table the CLI and the
# tests use. -I .build/release finds the module; the .o files supply the code (SwiftPM does not emit
# a static archive for a plain target).
#
# ONE OBJECT PER SOURCE FILE THAT STILL EXISTS — never `*.o`. SwiftPM does not delete the object
# of a source you renamed or removed; it leaves it in .build forever. This was `*.o` until
# 2026-09-03, and TerminalAdapter.swift had been renamed to TerminalAppAdapter.swift, so the link
# picked up both objects and died with "ld: 7 duplicate symbols" — on a machine with a warm
# .build only. A cold clone builds fine, which is why it survived: the person who shipped last had
# no stale object, and the next rename would have broken the release build again.
OBJS=()
for src in "$ROOT"/Sources/ChuteCore/*.swift; do
    OBJS+=("$ROOT/.build/release/ChuteCore.build/$(basename "$src").o")
done
swiftc -O -o "$APPEX/Contents/MacOS/ChuteFinder" \
    "$ROOT/Sources/ChuteFinder/ChuteFinderSync.swift" \
    -I "$ROOT/.build/release" "${OBJS[@]}" \
    -Xlinker -e -Xlinker _NSExtensionMain
strip -x "$APPEX/Contents/MacOS/ChuteFinder"
# The entry point must survive the strip, or the extension loads as a plain executable and Finder
# shows nothing. This is the same assertion CI makes on the assembled bundle.
# NO PIPE INTO `grep -q` UNDER `pipefail`. grep -q exits the instant it matches, the
# producer then dies writing to a closed pipe ("write on a pipe with no reader"), and
# pipefail reports the whole pipeline as FAILED even though the match succeeded. It is
# timing-dependent, so it passes on a quiet machine and fires under load. Observed here
# 2026-09-03: this exact assertion claimed _NSExtensionMain was gone from a binary that
# `nm` shows it in. A here-string is not a pipeline, so there is nothing to fail.
grep -q _NSExtensionMain <<<"$(nm -u "$APPEX/Contents/MacOS/ChuteFinder")" \
  || { echo "build-app: _NSExtensionMain is gone from the appex after stripping" >&2; exit 1; }

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
  <key>ChuteBuild</key><string>$BUILD $BUILT_AT</string>
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
  <key>ChuteBuild</key><string>$BUILD $BUILT_AT</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>CFBundleIconFile</key><string>Chute</string>
  <key>NSHumanReadableCopyright</key><string>Copyright © 2026 Alexandr Valuev. All rights reserved.</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>
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
#
# Three identities, in falling order of what they buy you:
#   1. Developer ID Application  — the only one a STRANGER can open without a Gatekeeper wall.
#      Picked automatically when present, or forced with CHUTE_SIGN_ID. Gets the hardened runtime
#      and a secure timestamp, both of which notarisation REFUSES the submission without.
#   2. Chute Local Dev           — stable, local, keeps the appex sandbox container ACL valid.
#   3. ad-hoc                    — works on this machine until the next rebuild changes the cdhash.
IDENTITY="${CHUTE_SIGN_ID:-}"
if [ -z "$IDENTITY" ]; then
  IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
    | sed -n 's/.*"\(Developer ID Application:[^"]*\)".*/\1/p' | head -1)"
fi
if [ -z "$IDENTITY" ]; then
  IDENTITY="Chute Local Dev"
  security find-identity -v -p codesigning 2>/dev/null | grep -q "$IDENTITY" || IDENTITY="-"
fi
[ "$IDENTITY" = "-" ] && echo "note: signing ad-hoc — run ./Scripts/sign-identity.sh once to stop the repeat macOS prompts"

# Hardened runtime + timestamp ONLY for Developer ID. Locally they are pure cost: the timestamp
# needs Apple's server, and the hardened runtime buys nothing for a build that never leaves here.
HARDEN=()
case "$IDENTITY" in
  "Developer ID Application:"*)
    HARDEN=(--options runtime --timestamp)
    echo "signing for distribution with: $IDENTITY"
    ;;
esac

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
    local err; err="$(mktemp)"
    ( codesign --force --sign "$IDENTITY" "${HARDEN[@]+"${HARDEN[@]}"}" "$@" "$target" 2>"$err" ) & local pid=$!
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
      # The exit code, not just "did it finish". A codesign that FAILED — a revoked certificate,
      # a bad entitlement, a locked keychain that answered instead of hanging — used to land here
      # with its stderr sent to /dev/null, fall through to the ad-hoc branch without a word, and
      # let the script print "built $APP" as if nothing had happened. An ad-hoc bundle does not
      # notarise and its Finder extension stops loading, so a silent downgrade is the one outcome
      # that must never be quiet.
      if wait "$pid" 2>/dev/null; then rm -f "$err"; return 0; fi
      echo "note: codesign failed for $target with \"$IDENTITY\":" >&2
      sed 's/^/      /' "$err" >&2
      echo "      falling back to an ad-hoc signature — this build CANNOT be notarised." >&2
      SIGNED_ADHOC=1
    fi
  fi
  rm -f "${err:-}" 2>/dev/null || true
  SIGNED_ADHOC=1
  codesign --force --sign - "$@" "$target" 2>/dev/null \
    || echo "note: signing unavailable for $target; it still runs locally"
}

SIGNED_ADHOC=0
sign "$APPEX" --entitlements "$ROOT/Resources/ChuteFinder.entitlements"
# The app is NOT sandboxed (it does the work the sandboxed appex cannot), but it IS hardened for
# Developer ID — and a hardened app with no entitlements cannot send an Apple Event. See the file.
sign "$APP" --entitlements "$ROOT/Resources/Chute.entitlements"
# WHAT WAS ACTUALLY SIGNED, asserted rather than assumed. Both of these have shipped wrong before
# in projects that assumed the flags took: an entitlement silently dropped because it was passed to
# the wrong `sign` call, and an appex entry point stripped away. The cost of checking is 40 ms.
codesign -d --entitlements - "$APP" 2>/dev/null | grep -q "com.apple.security.automation.apple-events" \
  || { echo "build-app: the app signed WITHOUT the Apple Events entitlement — every osascript it runs will fail under the hardened runtime" >&2; exit 1; }
codesign -d --entitlements - "$APPEX" 2>/dev/null | grep -q "com.apple.security.app-sandbox" \
  || { echo "build-app: the appex signed WITHOUT the sandbox entitlement — Finder will register it and never load it" >&2; exit 1; }

# Say which kind of build this is, every time. `release.sh` re-verifies the outer signature
# independently, but anyone running build-app.sh directly got an unqualified "built" either way.
if [ "$SIGNED_ADHOC" = "1" ]; then
  echo "built $APP  (AD-HOC SIGNED — runs locally, will not notarise)"
else
  echo "built $APP  (signed: $IDENTITY)"
fi
echo "build: $BUILD $BUILT_AT"
SIZE="$(du -sh "$APP" | awk '{print $1}')"          # e.g. 2.4M
echo "size: $SIZE"
# THE SIZE CLAIM, GATED AT ITS SOURCE. "2.5 MB" was hand-typed into eight files and stayed there
# while the bundle grew to 3.3 MB — nothing compared the sentence to the artifact. This does.
# The fact sheet is the one place the number is allowed to live; every asset quotes it from there.
SHEET="$ROOT/marketing/06-FACT-SHEET.md"
CLAIMED="$(sed -n 's/^| App bundle size | \*\*\([0-9.]*\) MB\*\*.*/\1/p' "$SHEET")"
ACTUAL="${SIZE%M}"
SIZE_BAD=0
if [ "$CLAIMED" != "$ACTUAL" ]; then
  echo "build-app: the fact sheet says the app is ${CLAIMED} MB and it is ${ACTUAL} MB." >&2
  echo "           Fix marketing/06-FACT-SHEET.md, then every asset that quotes it." >&2
  SIZE_BAD=1
fi

# THE CLI BINARY, SAME GATE. This row had a `Prove it` command and no gate, so it drifted exactly
# the way the bundle row did before it was gated: it read 727 KB while the shipped binary was
# 747 KB, and `marketing/02-LANDING-COPY.md` sold that number to a reader. A number in the file
# whose whole job is gated numbers is the last place an ungated one belongs.
# If the binary ever passes 1 MB, `ls -lh` prints "1.0M" and this goes red rather than quiet —
# which is the right way round: change the row's unit deliberately.
CLI_SIZE="$(ls -lh "$APP/Contents/MacOS/chute" | awk '{print $5}')"   # e.g. 789K
CLAIMED_CLI="$(sed -n 's/^| CLI binary size | \*\*\([0-9]*\) KB\*\*.*/\1/p' "$SHEET")"
if [ "$CLAIMED_CLI" != "${CLI_SIZE%K}" ]; then
  echo "build-app: the fact sheet says the CLI binary is ${CLAIMED_CLI} KB and it is ${CLI_SIZE%K} KB." >&2
  echo "           Fix marketing/06-FACT-SHEET.md, then every asset that quotes it." >&2
  SIZE_BAD=1
fi
[ "$SIZE_BAD" -eq 0 ] || exit 1

# ── DID THIS BUILD REACH THE APP YOU ACTUALLY RUN? ────────────────────────────────────────────
# Nothing answered that until 2026-09-03, and the gap cost a whole exchange: a new icon was built
# into dist/, verified there, and reported as done, while the copy in /Applications — the one with
# the Dock pin, the one the founder was looking at — was six days old and unchanged. `swift build`
# says "Build complete", `install.sh` is a separate command, and the distance between them is
# invisible. This closes it: after every build, any installed copy whose stamp differs is named.
# A note, never a failure — building without installing is a legitimate thing to do.
# COMPARE THE COMMIT, NOT THE TIMESTAMP. `$BUILT_AT` changes every minute, so matching the whole
# stamp made this fire after every single rebuild of the same code — and a check that always
# complains is one nobody reads. The commit is what answers the real question: is the app you
# launch built from the code in front of you? A dirty tree cannot be distinguished any finer than
# its commit, and that is honest: `-dirty` on both sides means "close enough to be worth checking
# yourself", not "identical".
for CANDIDATE in "$HOME/Applications/Chute.app" "/Applications/Chute.app"; do
  [ -d "$CANDIDATE" ] || continue
  INSTALLED="$(/usr/libexec/PlistBuddy -c 'Print :ChuteBuild' "$CANDIDATE/Contents/Info.plist" 2>/dev/null || echo "unreadable ?")"
  [ "${INSTALLED%% *}" = "$BUILD" ] && continue
  echo "note: $CANDIDATE was built from ${INSTALLED%% *}, this tree is $BUILD." >&2
  echo "      The app you launch is not this code — run Scripts/install.sh." >&2
done
