#!/usr/bin/env bash
# Render every screen Chute has to a PNG, so they can be LOOKED AT — and so the marketing
# material is generated from the shipping build rather than redrawn by hand and left to rot.
#
# Copies the tree to a scratch dir, appends Scripts/menu-shot.swift into ChuteApp's main.swift,
# builds once, and captures each screen. The shipped app is never touched and gains no debug
# flag: the tooling is this script, not a switch inside the product.
#
#   ./Scripts/screens.sh                 -> site/public/media/screens/*.png (working tree)
#   ./Scripts/screens.sh --pristine      -> the same, shot from HEAD, for published assets
#   ./Scripts/screens.sh /tmp/out        -> that directory
#
# See the header of Scripts/menu-shot.swift for why this exists: the traffic light shipped
# invisible for the product's whole life, and nothing but a picture could have said so.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/site/public/media/screens"
[ -n "${1:-}" ] && [ "${1:-}" != "--pristine" ] && OUT="$1"
WORK="$(mktemp -d)/chute-screens"
trap 'rm -rf "$(dirname "$WORK")"' EXIT
mkdir -p "$WORK" "$OUT"

# WHICH TREE GETS PHOTOGRAPHED.
#
# By default the WORKING tree, because while iterating on a layout you want to see the edit you
# just made. `Scripts/build-app.sh` stamps the bundle with `<sha>-dirty` whenever the tree is
# modified, and that stamp is visible in the About screenshot — which is fine for a working
# render and wrong for a marketing asset. The board published on 2026-09-08 read
# `build 54457a3-dirty` for exactly this reason.
#
# `--pristine` shoots a detached worktree at HEAD instead, so every asset carries a real commit
# that someone can go and read. Use it for anything anyone else will see.
if [ "${1:-}" = "--pristine" ] || [ "${2:-}" = "--pristine" ]; then
  git -C "$ROOT" diff --quiet HEAD 2>/dev/null || echo "screens: tree is dirty; shooting HEAD instead"
  SRC="$(mktemp -d)/pristine"
  git -C "$ROOT" worktree add -q --detach "$SRC" HEAD || {
    echo "screens: could not create a pristine worktree" >&2; exit 1; }
  trap 'git -C "$ROOT" worktree remove --force "$SRC" >/dev/null 2>&1; rm -rf "$(dirname "$WORK")" "$(dirname "$SRC")"' EXIT
  echo "screens: shooting $(git -C "$ROOT" rev-parse --short HEAD) (pristine)"
else
  SRC="$ROOT"
  git -C "$ROOT" diff --quiet HEAD 2>/dev/null \
    || echo "screens: WORKING tree — the build stamp will read '-dirty'. Use --pristine for assets."
fi

rsync -a --exclude '.build' --exclude 'dist' --exclude '.git' --exclude 'node_modules' \
      "$SRC/" "$WORK/" || exit 1

# The fragment declares top-level helpers and reads argv, so it must land AFTER the delegate is
# built and BEFORE app.run() — the rule main.swift's own trailing comment states.
python3 - "$WORK" "$ROOT/Scripts/menu-shot.swift" <<'PY' || { echo "screens: injection failed" >&2; exit 1; }
import io, sys
main = sys.argv[1] + "/Sources/ChuteApp/main.swift"
frag = io.open(sys.argv[2], encoding="utf-8").read()
s = io.open(main, encoding="utf-8").read()
a = "app.setActivationPolicy(.accessory)"
i = s.index(a); j = s.index("\n", i) + 1
io.open(main, "w", encoding="utf-8").write(s[:j] + "\n" + frag + "\n" + s[j:])
PY

if (cd "$WORK" && swift build -c release 2>&1 | grep -E "error:" | grep -v xcrun); then
  echo "screens: the harness did not compile — is Scripts/menu-shot.swift in step with the app?" >&2
  exit 1
fi
BIN="$WORK/.build/release/ChuteApp"

shot() {  # shot <name> <args...>
  local name="$1"; shift
  rm -f "$OUT/$name.png" "$OUT/$name.png.log"
  "$BIN" "$@" >/dev/null 2>&1
  if [ -f "$OUT/$name.png" ]; then
    printf '  %-10s %s\n' "$name" "$(sips -g pixelWidth -g pixelHeight "$OUT/$name.png" 2>/dev/null | awk '/pixel/{printf "%s ", $2}')"
  else
    echo "  $name FAILED" >&2; FAIL=1
  fi
}

FAIL=0
# ── THE SCENARIOS ───────────────────────────────────────────────────────────────────────────
# A screenshot of the everyday case proves only that the everyday case works. Each of these is a
# claim about behaviour when something is unusual, and each renders through the real model and
# the real renderer — the casts are in Scripts/menu-shot.swift.
#
# --draw exits BEFORE app.run(), so applicationDidFinishLaunching never runs and no status item
# is ever created. That matters: this script must not put a second parachute in the menu bar of
# whoever is running it.
mkdir -p "$OUT/cases"
for c in mixed allclear runaway nohooks truncation; do
  shot "cases/$c" --menu-shot "$OUT/cases/$c.png" --draw --case "$c"
done
cp "$OUT/cases/mixed.png" "$OUT/menu.png" 2>/dev/null

# The windows need a running loop, so they DO briefly create a status item. Skipped unless asked.
if [ "${WINDOWS:-1}" = "1" ]; then
  shot about    --settings-shot "$OUT/about.png" 1
  shot settings --settings-shot "$OUT/settings.png" 0
  shot setup    --firstrun-shot "$OUT/setup.png"
fi
rm -f "$OUT"/*.png.log "$OUT"/cases/*.png.log
echo "screens: written to $OUT"
[ "$FAIL" -eq 0 ]
