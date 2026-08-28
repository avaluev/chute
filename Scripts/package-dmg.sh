#!/usr/bin/env bash
# Build dist/Chute-<version>.dmg — the thing a stranger actually downloads.
#
# SEPARATE FROM release.sh ON PURPOSE. The packaging used to live inside release.sh, behind a
# preflight that demands a Developer ID certificate — so until that $99 enrolment completes, the
# disk image could not be built AT ALL, and the drag-to-Applications experience could not be
# looked at, tested, or shown to anyone. Signing is a separate concern from packaging, and only
# one of them was blocked.
#
#   ./Scripts/package-dmg.sh            → package whatever is in dist/Chute.app
#   ./Scripts/package-dmg.sh --build    → build the app first
#
# release.sh calls this after signing, so there is exactly one implementation of the layout.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="$(sed -n 's/.*static let current = "\([^"]*\)".*/\1/p' Sources/ChuteCore/Version.swift)"
[ -n "$VERSION" ] || { echo "package-dmg: no version in Sources/ChuteCore/Version.swift" >&2; exit 1; }
APP="$ROOT/dist/Chute.app"
DMG="$ROOT/dist/Chute-$VERSION.dmg"

[ "${1:-}" = "--build" ] && ./Scripts/build-app.sh
[ -d "$APP" ] || { echo "package-dmg: $APP does not exist — run with --build" >&2; exit 1; }

STAGE="$(mktemp -d)"; trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"   # the drag-to-install gesture people expect
rm -f "$DMG"
hdiutil create -volname "Chute $VERSION" -srcfolder "$STAGE" -ov -format UDZO -quiet "$DMG"

# PROVE IT MOUNTS. `hdiutil create` succeeding says the file was written, not that anyone can
# open it — and an image that fails to attach is indistinguishable from a good one until a
# customer double-clicks it. Attach it, look for both halves of the gesture, detach.
MOUNT="$(mktemp -d)"
hdiutil attach "$DMG" -mountpoint "$MOUNT" -nobrowse -quiet
ok=1
[ -d "$MOUNT/Chute.app" ]   || { echo "package-dmg: Chute.app is not in the image" >&2; ok=0; }
[ -L "$MOUNT/Applications" ] || { echo "package-dmg: the Applications shortcut is missing — there is nothing to drag onto" >&2; ok=0; }
[ -x "$MOUNT/Chute.app/Contents/MacOS/chute" ] || { echo "package-dmg: the bundled CLI is not executable" >&2; ok=0; }
hdiutil detach "$MOUNT" -quiet || true
rmdir "$MOUNT" 2>/dev/null || true
[ "$ok" = "1" ] || exit 1

echo "$DMG"
echo "  $(du -h "$DMG" | awk '{print $1}') · mounts, contains Chute.app and the Applications shortcut"
# Say plainly what a stranger will meet, rather than letting a local test imply more than it proves.
if codesign -dvv "$APP" 2>&1 | grep -q "Developer ID Application"; then
  echo "  signed with a Developer ID — run ./Scripts/release.sh to notarise and publish"
else
  echo "  NOT notarised: a stranger who downloads this meets Gatekeeper. That needs the Apple"
  echo "  Developer ID — see docs/11-PHASE-0-RUNBOOK.md step 7. Fine for local testing."
fi
