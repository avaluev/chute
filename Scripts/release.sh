#!/usr/bin/env bash
# Build, notarise, staple and publish a release — from this Mac, in one command.
#
# WHY NOT GITHUB ACTIONS: notarising from CI means putting the Developer ID PRIVATE KEY into
# GitHub secrets. For a solo developer cutting a release every few weeks that is real risk for no
# gain — the whole run takes about three minutes here and every failure is visible. Move it to CI
# when releases become frequent enough that three minutes is the problem.
#
# ONE-TIME SETUP (see the header of Scripts/notarize-setup.md):
#   1. A "Developer ID Application" certificate in the login keychain.
#   2. xcrun notarytool store-credentials chute --apple-id … --team-id … --password <app-specific>
#
# USAGE: ./Scripts/release.sh            → uses the version in Sources/ChuteCore/Version.swift
#        ./Scripts/release.sh --dry-run  → everything except the tag and the GitHub release
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
VERSION="$(sed -n 's/.*static let current = "\([^"]*\)".*/\1/p' Sources/ChuteCore/Version.swift)"
[ -n "$VERSION" ] || { echo "release: no version in Sources/ChuteCore/Version.swift" >&2; exit 1; }
TAG="v$VERSION"
DMG="$ROOT/dist/Chute-$VERSION.dmg"
PROFILE="${CHUTE_NOTARY_PROFILE:-chute}"

step() { printf '\n\033[1m→ %s\033[0m\n' "$1"; }
die()  { echo "release: $1" >&2; exit 1; }

# ---------------------------------------------------------------- preflight
step "Preflight"
[ -z "$(git status --porcelain)" ] || die "the tree is dirty — commit or stash first"
git rev-parse "$TAG" >/dev/null 2>&1 && die "$TAG already exists; bump Sources/ChuteCore/Version.swift"

SIGN_ID="$(security find-identity -v -p codesigning 2>/dev/null \
  | sed -n 's/.*"\(Developer ID Application:[^"]*\)".*/\1/p' | head -1)"
[ -n "$SIGN_ID" ] || die "no Developer ID Application certificate in the keychain.
      Enrolling in the Developer Program does NOT create one — see Scripts/notarize-setup.md"

xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1 \
  || die "no notarytool profile '$PROFILE' — see Scripts/notarize-setup.md step 4"

# ---------------------------------------------------------------- the gate
step "Gate — the suites must pass before anything is published"
swift run chutetests
./Scripts/smoke.sh

# ---------------------------------------------------------------- build
step "Building signed with: $SIGN_ID"
CHUTE_SIGN_ID="$SIGN_ID" ./Scripts/build-app.sh

codesign --verify --deep --strict --verbose=2 dist/Chute.app 2>&1 | tail -2
codesign -dvv dist/Chute.app 2>&1 | grep -q "Developer ID Application" \
  || die "the bundle is not signed with a Developer ID — notarisation would reject it"

# ---------------------------------------------------------------- dmg
step "Packaging $DMG"
STAGE="$(mktemp -d)"; trap 'rm -rf "$STAGE"' EXIT
cp -R dist/Chute.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"          # the drag-to-install gesture people expect
rm -f "$DMG"
hdiutil create -volname "Chute $VERSION" -srcfolder "$STAGE" -ov -format UDZO -quiet "$DMG"

# ---------------------------------------------------------------- notarise
# Submit the DMG, not a zip: stapling the DMG is what makes the DOWNLOAD open cleanly. The app
# inside is stapled separately so it survives being copied out of a dmg that is later thrown away.
step "Notarising — Apple usually answers in 1-3 minutes"
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait \
  | tee /tmp/chute-notary.log
grep -q "status: Accepted" /tmp/chute-notary.log || {
  ID="$(sed -n 's/ *id: *\([a-f0-9-]*\)/\1/p' /tmp/chute-notary.log | head -1)"
  echo "--- Apple's reasons ---" >&2
  [ -n "$ID" ] && xcrun notarytool log "$ID" --keychain-profile "$PROFILE" >&2
  die "notarisation was not Accepted"
}

step "Stapling"
xcrun stapler staple dist/Chute.app
xcrun stapler staple "$DMG"

# ---------------------------------------------------------------- prove it
# The only check that matters: what happens on a Mac that has never seen this app. `spctl`
# answers exactly that question, and it is the one the local build has always failed.
step "Verifying as a stranger's Mac would"
spctl -a -vvv -t install "$DMG" 2>&1 | tee /tmp/chute-spctl.log
grep -q "accepted" /tmp/chute-spctl.log || die "Gatekeeper still rejects the disk image"
xcrun stapler validate "$DMG"
xcrun stapler validate dist/Chute.app
echo "notarised, stapled, and accepted by Gatekeeper: $DMG"

# ---------------------------------------------------------------- publish
if [ "$DRY" = "1" ]; then
  step "--dry-run: stopping before the tag and the GitHub release"
  exit 0
fi

step "Tagging and publishing $TAG"
git tag -a "$TAG" -m "Chute $VERSION"
git push origin "$TAG"
gh release create "$TAG" "$DMG" \
  --title "Chute $VERSION" \
  --notes "Notarised by Apple. Download the disk image, drag Chute to Applications, and launch it once.

The \`chute\` CLI is free and MIT: \`brew install avaluev/tap/chute\`"
echo
echo "released: $(gh release view "$TAG" --json url -q .url)"
