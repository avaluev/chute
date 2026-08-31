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

# THE LICENCE KEY BLOCKS THE RELEASE, and nothing else could catch it. `License.verify` defaults to
# `productionPublicKey`, which is still the literal `REPLACE_ME_BEFORE_RELEASE` — not valid base64,
# so EVERY licence key a buyer pastes fails, silently, and they are told nothing useful. The unit
# suite cannot see it: `LicenseSuite` deliberately verifies against its own generated keypair so it
# never needs the production secret, which is correct for a test and blind for a release.
#
# So the gate lives here, at the one moment it matters. Mint the real pair with
# `node worker/keygen.mjs new`, put the PUBLIC half in Version's sibling
# Sources/ChuteCore/License.swift:28, and keep the private half as a Cloudflare Worker secret.
KEY="$(sed -n 's/.*productionPublicKey = "\([^"]*\)".*/\1/p' Sources/ChuteCore/License.swift)"
if [ "$KEY" = "REPLACE_ME_BEFORE_RELEASE" ] || [ -z "$KEY" ]; then
  echo "release: Sources/ChuteCore/License.swift:28 is still the placeholder public key." >&2
  echo "         Every licence key would fail verification for every buyer." >&2
  echo "         Mint one with: node worker/keygen.mjs new" >&2
  exit 1
fi
DMG="$ROOT/dist/Chute-$VERSION.dmg"
PROFILE="${CHUTE_NOTARY_PROFILE:-chute}"

step() { printf '\n\033[1m→ %s\033[0m\n' "$1"; }
die()  { echo "release: $1" >&2; exit 1; }

# ---------------------------------------------------------------- preflight
step "Preflight"
[ -z "$(git status --porcelain)" ] || die "the tree is dirty — commit or stash first"
# Only when we are actually going to CUT the tag. --dry-run never reaches the tag path (see the
# publish section), but this check ran before $DRY was consulted — so with v0.2.0 already pushed,
# `release.sh --dry-run` died here before building, signing or notarising anything. That flag
# exists precisely to prove the pipeline without cutting a release, and it could not.
if [ "$DRY" = "0" ]; then
  git rev-parse "$TAG" >/dev/null 2>&1 \
    && die "$TAG already exists; bump Sources/ChuteCore/Version.swift"
fi

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
# One implementation of the layout, in package-dmg.sh, which also proves the image MOUNTS —
# `hdiutil create` succeeding only says a file was written. It is a separate script because
# packaging is not signing: it must stay runnable before the Developer ID exists.
step "Packaging $DMG"
./Scripts/package-dmg.sh

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
# THREE STEPS THAT MUST NOT HALF-HAPPEN. Each one used to be unguarded, and `set -e` turned any
# failure into a half-published release that the preflight above then refused to retry, with a
# message ("$TAG already exists") that reads as if the release went out when it did not.
git tag -a "$TAG" -m "Chute $VERSION"

git push origin "$TAG" || {
  git tag -d "$TAG" >/dev/null 2>&1 || true      # local only; nothing was published
  die "could not push $TAG — the local tag has been removed, so this is safe to re-run"
}

if ! gh release create "$TAG" "$DMG" \
  --title "Chute $VERSION" \
  --notes "Notarised by Apple. Download the disk image, drag Chute to Applications, and launch it once.

The \`chute\` CLI is free and MIT: \`brew install avaluev/tap/chute\`"
then
  # The tag IS live on the remote now. Take it back down rather than leaving the exact state the
  # preflight cannot distinguish from a finished release.
  git push origin ":refs/tags/$TAG" >/dev/null 2>&1 || true
  git tag -d "$TAG" >/dev/null 2>&1 || true
  die "the GitHub release failed; $TAG has been withdrawn locally and on origin, so re-running is safe.
      The notarised disk image is still at $DMG — nothing has to be rebuilt."
fi

# The release exists from here on. Nothing below may abort the script: a transient `gh` failure
# on the LAST line used to make a completed release look like a crash.
echo
URL="$(gh release view "$TAG" --json url -q .url 2>/dev/null || true)"
echo "released: ${URL:-https://github.com/avaluev/chute/releases/tag/$TAG}"
