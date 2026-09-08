#!/usr/bin/env bash
# THE APP IN /Applications IS NOT THE TREE. Rebuild and reinstall when it has fallen behind.
#
# ── WHY THIS EXISTS ─────────────────────────────────────────────────────────────────────────
#
# On 2026-09-08 the menu was redesigned, committed, and verified at 1253/1253 — and the founder
# opened the menu bar and saw the OLD menu, because nothing had rebuilt `/Applications/Chute.app`.
# The work was real, the tests were green, and the only thing anyone could actually LOOK at was
# four commits out of date. An hour went into "where is the menu".
#
# `Scripts/install.sh` already documents the sibling of this failure: a build installed politely
# into ~/Applications while the running copy sat in /Applications, and a whole exchange went to
# "I see no change" for an install that had genuinely happened.
#
# A rule the human has to remember gets broken. This is a hook, so it cannot be.
#
# ── WHAT IT DOES ────────────────────────────────────────────────────────────────────────────
#
# Compares the installed bundle's `ChuteBuild` stamp against the tree's HEAD. If they differ, it
# rebuilds and reinstalls over whichever copy is actually installed. Idempotent: run it as often
# as you like, it does nothing when the app is current.
#
#   ./Scripts/reinstall-if-stale.sh          rebuild+install only when stale
#   ./Scripts/reinstall-if-stale.sh --check  report only, exit 1 if stale (for CI / a gate)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Where the app actually is — the same chooser install.sh uses, for the same reason.
INSTALLED=""
FOUND=()
for d in "/Applications/Chute.app" "$HOME/Applications/Chute.app"; do
  [ -d "$d" ] && FOUND+=("$d")
done
[ "${#FOUND[@]}" -gt 0 ] && INSTALLED="${FOUND[0]}"

# TWO COPIES IS TWO MENU BAR ICONS, and this script would quietly keep only the first one
# current while the stale one kept launching beside it. It happened on 2026-09-08: an
# uninstall-then-install test relocated the app to ~/Applications — the exact hazard
# Scripts/install.sh's own header documents — and the founder ended up with two parachutes in
# the menu bar and no indication which was which. Say so loudly; do not pick one silently.
if [ "${#FOUND[@]}" -gt 1 ]; then
  echo "reinstall-if-stale: TWO installs — ${FOUND[*]}" >&2
  echo "  Two copies means two menu bar icons. Quit both, delete the one you do not want," >&2
  echo "  then re-run with CHUTE_APP_DIR set to the folder you keep." >&2
  exit 1
fi
[ -n "$INSTALLED" ] || { echo "reinstall-if-stale: Chute is not installed — nothing to keep current"; exit 0; }

HEAD_SHORT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
git -C "$ROOT" diff --quiet HEAD 2>/dev/null || HEAD_SHORT="$HEAD_SHORT-dirty"
# The stamp reads "<short sha> <ISO time>"; only the first field is the identity.
# plutil, NOT `defaults read`: defaults caches per-user and cheerfully reports a value that is
# no longer in the file, which is how a stale install can look current to the very script whose
# job is to notice.
stamp_of() { plutil -extract ChuteBuild raw "$1/Contents/Info.plist" 2>/dev/null | awk '{print $1}'; }
STAMPED="$(stamp_of "$INSTALLED")"

[ "$STAMPED" = "$HEAD_SHORT" ] && { echo "reinstall-if-stale: $INSTALLED is current ($HEAD_SHORT)"; exit 0; }

echo "reinstall-if-stale: installed '$STAMPED' != tree '$HEAD_SHORT'"
[ "${1:-}" = "--check" ] && { echo "  run ./Scripts/reinstall-if-stale.sh to fix"; exit 1; }

# Never ship a bundle the suite has not passed. A stale app is bad; a broken one is worse.
if ! (cd "$ROOT" && swift build -c release >/dev/null 2>&1 && swift run -c release chutetests >/dev/null 2>&1); then
  echo "  REFUSED — the tree does not build or the suite is red. Fix that first." >&2
  exit 1
fi
# BUILD FIRST, EXPLICITLY. `install.sh` only builds when `dist/Chute.app` is ABSENT — so with a
# bundle left over from an earlier build it copies that one and reports success. Caught 2026-09-08:
# this script announced "reinstalled at 71c3f16" while the app it installed was stamped 8337638,
# four commits behind. A reinstaller that can install the wrong thing and say otherwise is worse
# than no reinstaller, because it is the thing you stop checking.
"$ROOT/Scripts/build-app.sh" >/dev/null 2>&1 || { echo "  build failed" >&2; exit 1; }
CHUTE_APP_DIR="$(dirname "$INSTALLED")" "$ROOT/Scripts/install.sh" >/dev/null 2>&1 \
  || { echo "  install failed" >&2; exit 1; }

# AND PROVE IT. The whole point of this script is that the app matches the tree; taking install.sh
# at its word is what let the stale copy through in the first place.
NOW_STAMPED="$(stamp_of "$INSTALLED")"
if [ "$NOW_STAMPED" != "$HEAD_SHORT" ]; then
  echo "  FAILED — installed '$NOW_STAMPED' still does not match tree '$HEAD_SHORT'" >&2
  exit 1
fi
echo "  reinstalled $INSTALLED at $HEAD_SHORT"
