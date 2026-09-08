#!/usr/bin/env bash
# Render every screen Chute has to a PNG, so they can be LOOKED AT — and so the marketing
# material is generated from the shipping build rather than redrawn by hand and left to rot.
#
# Copies the tree to a scratch dir, appends Scripts/menu-shot.swift into ChuteApp's main.swift,
# builds once, and captures each screen. The shipped app is never touched and gains no debug
# flag: the tooling is this script, not a switch inside the product.
#
#   ./Scripts/screens.sh                 -> site/public/media/screens/*.png
#   ./Scripts/screens.sh /tmp/out        -> that directory
#
# See the header of Scripts/menu-shot.swift for why this exists: the traffic light shipped
# invisible for the product's whole life, and nothing but a picture could have said so.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/site/public/media/screens}"
WORK="$(mktemp -d)/chute-screens"
trap 'rm -rf "$(dirname "$WORK")"' EXIT
mkdir -p "$WORK" "$OUT"

rsync -a --exclude '.build' --exclude 'dist' --exclude '.git' --exclude 'node_modules' \
      "$ROOT/" "$WORK/" || exit 1

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
shot menu     --menu-shot     "$OUT/menu.png" --draw
shot about    --settings-shot "$OUT/about.png" 1
shot settings --settings-shot "$OUT/settings.png" 0
shot setup    --firstrun-shot "$OUT/setup.png"
rm -f "$OUT"/*.png.log
echo "screens: written to $OUT"
[ "$FAIL" -eq 0 ]
