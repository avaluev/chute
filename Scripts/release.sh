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
# Only when we are actually going to CUT the tag. --dry-run never reaches the tag path (see the
# publish section), but this check ran before $DRY was consulted — so with v0.2.0 already pushed,
# `release.sh --dry-run` died here before building, signing or notarising anything. That flag
# exists precisely to prove the pipeline without cutting a release, and it could not.
if [ "$DRY" = "0" ]; then
  git rev-parse "$TAG" >/dev/null 2>&1 \
    && die "$TAG already exists; bump Sources/ChuteCore/Version.swift"
fi

# SIGNING IS OPTIONAL, BECAUSE TODAY THERE IS NO CERTIFICATE.
#
# This script used to `die` here without a Developer ID, which meant it could not cut the release
# that actually ships — v0.2.1 on GitHub is unsigned, unstapled and rejected by spctl, and it was
# published some other way. A release script that cannot produce the shipped artifact is not a
# release script; worse, its notes said "Notarised by Apple." unconditionally, so the one path it
# could never run was also the only one it described. Found 2026-09-09 by checking the live .dmg.
#
# So: notarise when a certificate exists, ship honestly unsigned when it does not, and say which
# happened in the release notes either way.
SIGN_ID="$(security find-identity -v -p codesigning 2>/dev/null \
  | sed -n 's/.*"\(Developer ID Application:[^"]*\)".*/\1/p' | head -1)"
if [ -n "$SIGN_ID" ]; then
  SIGNED=1
  xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1 \
    || die "a Developer ID exists but no notarytool profile '$PROFILE' — see Scripts/notarize-setup.md step 4.
      Delete the certificate or create the profile; a half-configured signing setup is how an
      unsigned build gets published under notarised release notes."
else
  SIGNED=0
  echo "release: no Developer ID Application certificate — building UNSIGNED."
  echo "         This is the current, expected path. See Scripts/notarize-setup.md to change it."
fi

# ---------------------------------------------------------------- the gate
step "Gate — the suites must pass before anything is published"
swift run -c release chutetests
./Scripts/smoke.sh

# ---------------------------------------------------------------- build
if [ "$SIGNED" = "1" ]; then
  step "Building signed with: $SIGN_ID"
  CHUTE_SIGN_ID="$SIGN_ID" ./Scripts/build-app.sh
  codesign --verify --deep --strict --verbose=2 dist/Chute.app 2>&1 | tail -2
  codesign -dvv dist/Chute.app 2>&1 | grep -q "Developer ID Application" \
    || die "the bundle is not signed with a Developer ID — notarisation would reject it"
else
  step "Building unsigned (ad-hoc)"
  ./Scripts/build-app.sh
fi

# ---------------------------------------------------------------- dmg
# One implementation of the layout, in package-dmg.sh, which also proves the image MOUNTS —
# `hdiutil create` succeeding only says a file was written. It is a separate script because
# packaging is not signing: it must stay runnable before the Developer ID exists.
step "Packaging $DMG"
./Scripts/package-dmg.sh

# ---------------------------------------------------------------- notarise
# Submit the DMG, not a zip: stapling the DMG is what makes the DOWNLOAD open cleanly. The app
# inside is stapled separately so it survives being copied out of a dmg that is later thrown away.
LOG="$(mktemp -d)"; trap 'rm -rf "$LOG"' EXIT
if [ "$SIGNED" = "1" ]; then
step "Notarising — Apple usually answers in 1-3 minutes"
# `|| true`: under pipefail a rejection fails the pipeline and `set -e` ends the script before
# the grep that explains it — the message written for this case never printed.
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait \
  | tee "$LOG/notary.log" || true
grep -q "status: Accepted" "$LOG/notary.log" || {
  ID="$(sed -n 's/ *id: *\([a-f0-9-]*\)/\1/p' "$LOG/notary.log" | head -1)"
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
spctl -a -vvv -t install "$DMG" 2>&1 | tee "$LOG/spctl.log" || true
grep -q "accepted" "$LOG/spctl.log" || die "Gatekeeper still rejects the disk image"
xcrun stapler validate "$DMG"
xcrun stapler validate dist/Chute.app
echo "notarised, stapled, and accepted by Gatekeeper: $DMG"
else
step "Unsigned build — recording what a stranger's Mac will actually say"
# NOT a failure, and deliberately not `die`. spctl WILL reject this, and the release notes and
# the site both tell the reader so, with the Open Anyway steps. Printing it here keeps the fact
# in front of whoever cuts the release rather than letting it be a surprise on someone's Mac.
spctl -a -vvv -t install "$DMG" 2>&1 | tee "$LOG/spctl.log" || true
grep -q "rejected" "$LOG/spctl.log" \
  && echo "expected: Gatekeeper rejects an unsigned image; the notes explain Open Anyway" \
  || echo "unexpected: spctl did not reject an unsigned image — check the notes are still true"
fi

# THE CHECKSUM THE SITE PROMISES. page.tsx says the disk image "ships with a SHA-256 to check",
# and the release notes give the `shasum -a 256 -c` command — so the file that command reads has
# to exist. It was being produced by hand; a promise kept by memory is a promise already broken.
SUM="$DMG.sha256"
( cd "$(dirname "$DMG")" && shasum -a 256 "$(basename "$DMG")" > "$(basename "$SUM")" )
echo "checksum: $(cat "$SUM")"

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

# THE NOTES MUST DESCRIBE THE BUILD THAT WAS ACTUALLY MADE. This said "Notarised by Apple."
# unconditionally, on a script whose signed path has never once run.
if [ "$SIGNED" = "1" ]; then
  NOTES="Notarised by Apple. Download the disk image, drag Chute to Applications, and launch it once.

The \`chute\` CLI is free and MIT: \`brew install avaluev/tap/chute\`"
else
  NOTES="Chute is **not signed by Apple** — there is no Apple Developer Program membership behind
this project. On first launch macOS says \"Apple could not verify 'Chute' is free of malware.\"
and offers only **Done** and **Move to Trash**. To open it anyway: click Done, then
**System Settings → Privacy & Security → Open Anyway**, authenticate, and launch it again.

Because the app is unsigned, the Finder extension may not load on a Mac other than the one that
built it. If the right-click menu never appears, use the source install, which builds on yours.

Verify the download:
\`\`\`
shasum -a 256 -c Chute-$VERSION.dmg.sha256
\`\`\`

The \`chute\` CLI is free and MIT: \`brew install avaluev/tap/chute\`"
fi

if ! gh release create "$TAG" "$DMG" "$SUM" \
  --title "Chute $VERSION" \
  --notes "$NOTES"
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
