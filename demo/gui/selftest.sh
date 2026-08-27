#!/usr/bin/env bash
# Prove the DELIVERY half without a screen, a permission or a human.
#
# Recording needs a real Mac with a real Finder and someone sitting at it. Composing, exporting,
# the loop-seam check and every caption do not — they are ffmpeg and PIL over files. So they are
# tested here, on synthetic takes of realistic length, and they are tested on every change.
#
# This exists because `burn_clock` was written against ffmpeg's `drawtext` filter, which this
# machine's ffmpeg does not have. That would have failed at recording time, with a human in front
# of the screen and a fixture already set up — the single most expensive moment to discover it.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

FAIL=0
ok()  { printf "  ok   %s\n" "$1"; }
bad() { printf "  FAIL %s\n       %s\n" "$1" "$2"; FAIL=$((FAIL+1)); }

SLUG="selftest-race"
mkdir -p "$OUT"
# KEEP=1 leaves the artifacts behind. A failing compose is diagnosed by LOOKING at the frame,
# and a trap that tidies up first is a trap that hides the evidence.
[ "${KEEP:-0}" = "1" ] || trap 'rm -rf "$OUT/$SLUG"*' EXIT

echo "Delivery pipeline, on synthetic takes"

# Two takes of realistic shape: a long ritual and a short one. testsrc2 MOVES, so a frozen right
# panel is distinguishable from a still one, and smptebars is flat, so the loop seam is ~0.
ffmpeg -v error -y -f lavfi -i "testsrc2=s=1280x800:r=30:d=20" -pix_fmt yuv420p "$OUT/$SLUG-manual.mov"
ffmpeg -v error -y -f lavfi -i "smptebars=s=1280x800:r=30:d=5"  -pix_fmt yuv420p "$OUT/$SLUG.mov"

# ── captions render, in the brand face ──────────────────────────────────────────────────────
python3 "$HERE/overlay.py" labels "$OUT/$SLUG-l.png" --width 1920 >/dev/null 2>&1 \
  && [ -s "$OUT/$SLUG-l.png" ] && ok "labels render" || bad "labels render" "overlay.py labels produced nothing"
python3 "$HERE/overlay.py" clock "$OUT/$SLUG-c" --width 1920 --height 660 \
  --manual 95.2 --chute 4.8 --seconds 14 >/dev/null 2>&1
N=$(ls "$OUT/$SLUG-c" 2>/dev/null | wc -l | tr -d ' ')
[ "$N" = "15" ] && ok "clock renders one frame per second (15 for 0–14)" \
                || bad "clock frame count" "got $N, expected 15"
rm -rf "$OUT/$SLUG-c" "$OUT/$SLUG-l.png"

# ── the race composes to the exact frame the page expects ───────────────────────────────────
compose_race "$SLUG" 95.2 4.8 14 >/dev/null
if [ -s "$OUT/$SLUG-race.mp4" ]; then
  DIM="$(ffprobe -v error -show_entries stream=width,height -of csv=p=0:s=x "$OUT/$SLUG-race.mp4")"
  DUR="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT/$SLUG-race.mp4" | cut -d. -f1)"
  [ "$DIM" = "1920x660" ] && ok "race is 1920x660" || bad "race dimensions" "got $DIM"
  [ "$DUR" = "14" ] && ok "race is 14s, not the 20s of the manual take" || bad "race duration" "got ${DUR}s"
else
  bad "race composes" "no output file"
fi

# The right panel must HOLD its last frame after its take ends — that hold is what makes
# "done, and the other one is still going" legible. Compare the right half at 6s and at 13s.
grab "$OUT/$SLUG-race.mp4" 6  /tmp/st-a.png "crop=960:600:960:60"
grab "$OUT/$SLUG-race.mp4" 13 /tmp/st-b.png "crop=960:600:960:60"
HOLD="$(frame_mse /tmp/st-a.png /tmp/st-b.png)"
[ -n "$HOLD" ] && [ "$HOLD" -le 5 ] && ok "the finished side holds its last frame (drift $HOLD)" \
                                    || bad "the finished side holds" "drifted ${HOLD:-unmeasurable} between 6s and 13s"

# …and the unfinished side must still be MOVING, or the race shows two frozen panels.
grab "$OUT/$SLUG-race.mp4" 6  /tmp/st-c.png "crop=960:600:0:60"
grab "$OUT/$SLUG-race.mp4" 13 /tmp/st-d.png "crop=960:600:0:60"
MOVE="$(frame_mse /tmp/st-c.png /tmp/st-d.png)"
[ -n "$MOVE" ] && [ "$MOVE" -ge 20 ] && ok "the unfinished side is still running (change $MOVE)" \
                                     || bad "the unfinished side moves" "only ${MOVE:-unmeasurable} change — both panels look frozen"
rm -f /tmp/st-*.png

# ── the solo export, which is what every phone gets ─────────────────────────────────────────
export_web "$SLUG" >/dev/null
[ -s "$OUT/$SLUG.mp4" ] && ok "mp4 exported" || bad "mp4 exported" "missing"
[ -s "$OUT/$SLUG.jpg" ] && ok "poster exported" || bad "poster exported" "missing"
W="$(ffprobe -v error -show_entries stream=width -of csv=p=0 "$OUT/$SLUG.mp4")"
[ "$W" = "1280" ] && ok "solo take normalised to 1280 wide (Retina capture is 2x)" \
                  || bad "solo width" "got $W, expected 1280"

# ── the loop seam ───────────────────────────────────────────────────────────────────────────
verify_loop "$SLUG" | grep -q "loops cleanly" && ok "a still take is reported as looping cleanly" \
                                              || bad "loop check" "smptebars should have a ~0% seam"

# ── the guard that would have eaten every recording ─────────────────────────────────────────
# verify_take deletes a black take. It read an empty measurement and deleted EVERY take. Prove
# both directions: a real take survives, a black one does not.
ffmpeg -v error -y -f lavfi -i "color=c=black:s=1280x800:r=30:d=6" -pix_fmt yuv420p "$OUT/$SLUG-black.mov"
if ( verify_take "$SLUG-black" 6 >/dev/null 2>&1 ); then
  bad "a black take is discarded" "verify_take accepted a completely black recording"
else
  ok "a black take is discarded"
fi
verify_take "$SLUG" 5 >/dev/null 2>&1 && ok "a real take survives verify_take" \
                                      || bad "a real take survives" "verify_take deleted a good recording"

echo
echo "delivery: $((12 - FAIL)) passed, $FAIL failed"
exit $([ "$FAIL" -eq 0 ] && echo 0 || echo 1)
