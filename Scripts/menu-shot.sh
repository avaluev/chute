#!/usr/bin/env bash
# Render the menu bar drop-down to a PNG, so it can be LOOKED AT.
#
# Copies the tree to a scratch dir, appends Scripts/menu-shot.swift into ChuteApp's main.swift,
# builds, and draws the real rendered menu. The shipped app is never touched and gains no debug
# flag — the tooling is this script, not a switch inside the product.
#
#   ./Scripts/menu-shot.sh                  -> /tmp/chute-menu.png
#   ./Scripts/menu-shot.sh out.png          -> that path
#
# See the header of Scripts/menu-shot.swift for why this exists: the traffic light shipped
# invisible for the product's whole life, and nothing but a picture could have said so.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-/tmp/chute-menu.png}"
WORK="$(mktemp -d)/chute-menu-shot"
trap 'rm -rf "$(dirname "$WORK")"' EXIT

mkdir -p "$WORK"
rsync -a --exclude '.build' --exclude 'dist' --exclude '.git' "$ROOT/" "$WORK/" || exit 1

# The fragment declares top-level helpers and reads argv, so it must land AFTER the delegate is
# built and BEFORE app.run() — the same rule main.swift's own trailing comment states.
python3 - "$WORK" "$ROOT/Scripts/menu-shot.swift" <<'PY'
import io, sys
main = sys.argv[1] + "/Sources/ChuteApp/main.swift"
frag = io.open(sys.argv[2], encoding="utf-8").read()
s = io.open(main, encoding="utf-8").read()
a = "app.setActivationPolicy(.accessory)"
i = s.index(a); j = s.index("\n", i) + 1
io.open(main, "w", encoding="utf-8").write(s[:j] + "\n" + frag + "\n" + s[j:])
PY
[ $? -eq 0 ] || { echo "menu-shot: could not inject the harness" >&2; exit 1; }

(cd "$WORK" && swift build -c release 2>&1 | grep -E "error:" | grep -v xcrun) && {
  echo "menu-shot: the harness did not compile — is Scripts/menu-shot.swift in step with the renderer?" >&2
  exit 1
}
rm -f "$OUT" "$OUT.log"
"$WORK/.build/release/ChuteApp" --menu-shot "$OUT" --draw >/dev/null 2>&1
[ -f "$OUT" ] || { echo "menu-shot: nothing was written; log follows" >&2; cat "$OUT.log" 2>/dev/null >&2; exit 1; }
echo "menu-shot: $OUT"
tail -1 "$OUT.log" 2>/dev/null
