#!/usr/bin/env bash
# One master recording → every aspect ratio a social platform wants, plus a poster frame.
#
# The same 20 seconds has to work as a site hero (16:9), an X/LinkedIn post (1:1), a Reels/Shorts
# upload (9:16) and a feed video (4:5). Re-shooting for each is how a launch week disappears.
# Crop, never letterbox: black bars read as "reposted from somewhere else".
#
# USAGE: ./reframe.sh out/hero.mov [basename]
set -euo pipefail
SRC="${1:?usage: reframe.sh <master.mov|.mp4> [basename]}"
NAME="${2:-$(basename "${SRC%.*}")}"
OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/out/social"
mkdir -p "$OUT"

# scale-then-crop keeps the CENTRE of the frame, which is where a terminal demo's action is.
fit() { echo "scale=w=$1:h=$2:force_original_aspect_ratio=increase,crop=$1:$2,setsar=1"; }

emit() { # label WxH
  local label="$1" w="${2%x*}" h="${2#*x}"
  echo "→ $label ${w}x${h}"
  ffmpeg -y -loglevel error -i "$SRC" -vf "$(fit "$w" "$h")" \
    -c:v libx264 -pix_fmt yuv420p -crf 20 -movflags +faststart -an \
    "$OUT/$NAME-$label.mp4"
  ffmpeg -y -loglevel error -i "$SRC" -vf "$(fit "$w" "$h")" \
    -c:v libvpx-vp9 -crf 34 -b:v 0 -an "$OUT/$NAME-$label.webm"
}

emit wide   1920x1080   # site hero, YouTube
emit square 1080x1080   # X, LinkedIn, Instagram feed
emit tall   1080x1920   # Shorts, Reels, TikTok
emit feed   1080x1350   # Instagram/LinkedIn portrait — the most screen a feed will give you

# A GIF for the README, where autoplay video does not exist. Two-pass palette: a naive gif filter
# posterises the brand green into mud.
echo "→ gif (README, 900px)"
PAL="$(mktemp -d)/p.png"
ffmpeg -y -loglevel error -i "$SRC" -vf "fps=16,scale=900:-1:flags=lanczos,palettegen=stats_mode=diff" "$PAL"
ffmpeg -y -loglevel error -i "$SRC" -i "$PAL" \
  -lavfi "fps=16,scale=900:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" \
  "$OUT/$NAME.gif"

echo "→ poster frame"
ffmpeg -y -loglevel error -sseof -1.5 -i "$SRC" -vframes 1 "$OUT/$NAME-poster.png"

ls -la "$OUT" | awk 'NR>1 {printf "  %-34s %s\n", $9, $5}'
