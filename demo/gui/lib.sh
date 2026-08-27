#!/usr/bin/env bash
# The verbs a GUI demo is written in.
#
# VHS owns the terminal demos and they are demos-as-code: a tape file, a deterministic fixture,
# and `make` to regenerate all of them. The GUI half had none of that: the recorder this replaces
# performed three of its four shots by asking a human to click something, and clicked the fourth
# at a hardcoded pixel offset after a blind `sleep 0.8`. If Finder was 200 ms slow that click
# landed on empty space and you got nine seconds of a static window. Nothing noticed.
#
# THE RULE THIS FILE IS BUILT ON: the recorder cannot trust the UI, only the EFFECT.
# macOS context-menu automation is genuinely unreliable — Accessibility traversal, menu
# type-ahead and pixel offsets each break in different circumstances and none of them is
# dependable across macOS versions. So `menu_pick` tries several routes and none of them is
# believed. What is believed is an observable consequence: the clipboard really changed, the file
# really appeared, the request inbox really drained. A take whose effect never happened is
# DELETED, not shipped. This is the same lesson as demo/verify.sh, one layer up: a demo of the
# product failing is worse than no demo, and it is invisible to every check that measures pixels.
#
# THE SECOND IDEA: record BOTH paths and let the clock be real.
# cases.ts claims `seconds: { manual: 150, chute: 5 }` for the wedge. That is the entire sales
# argument and today it is an estimate printed on a page. A tape performs the manual ritual too,
# both takes are timed with a stopwatch, and the measurement is written to out/gui/<slug>.json.
# check-cases.mjs reads it and fails the deploy if the page claims a saving the stopwatch did not
# reproduce. The number on the landing page stops being a claim and becomes a recording.
#
# Sourced by demo/gui/tapes/*.sh — never run directly.
#
#   PLAN=1 ./tapes/paste-eight-files.sh    resolve everything, check tools, record nothing
#
# NEEDS A HUMAN AT THE MACHINE: it drives the real cursor and records the real screen. It cannot
# run in CI or over SSH. Grant Screen Recording and Accessibility to your TERMINAL, not to Chute.
set -euo pipefail

GUI_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$GUI_HERE/../.." && pwd)"
OUT="$REPO/demo/out/gui"
CHUTE="$REPO/.build/release/chute"
FIXTURE="${CHUTE_GUI_FIXTURE:-$HOME/Desktop/acme-app}"
PLAN="${PLAN:-0}"

# One rectangle for every recording, so five assets look like one session instead of five.
# 1280x800 at (120,120) fits inside every display Chute supports.
WIN_X=120; WIN_Y=120; WIN_W=1280; WIN_H=800

# THE 375px CONSTRAINT. The landing page must be readable at phone width, and a 1280-wide Finder
# window scaled into a 375px column renders a filename at about 4px tall — unreadable, which
# makes the demo decorative rather than evidential. Anything a viewer must READ gets cropped to
# this box for the mobile variant instead of being scaled down whole.
CROP_W=640; CROP_H=400

# The menu-bar capture: a column under the status item. 900 wide fits the widest session row
# ("waiting · studylock · claude · 12m") without cropping the project name, which is the one part
# of that menu a viewer has to be able to read.
MENUBAR_W=900; MENUBAR_H=700

# ── failure is loud ─────────────────────────────────────────────────────────────────────────
die() { printf '\n  ✗ %s\n' "$*" >&2; exit 1; }
say() { printf '  · %s\n' "$*"; }

need() { command -v "$1" >/dev/null || die "missing: $1 — brew install ${2:-$1}"; }

preflight() {
  need cliclick; need ffmpeg
  [ -x "$CHUTE" ] || die "build first — cd $REPO && swift build -c release"
  # PLAN mode resolves the whole tape and checks the tools without touching the screen, so the
  # plumbing can be exercised on a machine with no Screen Recording grant and no human at it.
  if [ "$PLAN" = "1" ]; then say "PLAN — nothing will be recorded"; mkdir -p "$OUT"; return 0; fi
  # A recording made while the app is not running produces a menu with no effect behind it.
  pgrep -x Chute >/dev/null || die "Chute.app is not running — the Finder actions do nothing without it"
  local probe="/tmp/chute-permcheck-$$.png"
  screencapture -x -R0,0,8,8 "$probe" 2>/dev/null || true
  [ -s "$probe" ] || die "Screen Recording is not granted to this terminal.
    System Settings → Privacy & Security → Screen & System Audio Recording → enable your terminal,
    then QUIT AND REOPEN it. macOS only re-reads that permission on launch."
  rm -f "$probe"
  mkdir -p "$OUT"
}

# ── PLAN mode is enforced HERE, not in the tapes ────────────────────────────────────────────
# It was enforced in the tapes for about ten minutes, which was long enough for a dry run to
# activate TextEdit and start driving the real cursor. A mode that depends on every tape
# remembering to check it is not a mode. So: every verb below that touches the machine begins
# with `planned`, and a tape may ONLY speak in verbs — `make -C demo/gui lint` fails a tape that
# reaches for osascript, cliclick or sleep directly.
planned() { [ "$PLAN" = "1" ] && { say "would $*"; return 0; }; return 1; }

# The two primitives a tape is allowed to reach the machine through.
osa() { planned "run applescript: $(printf '%s' "$1" | head -1 | cut -c1-60)…" && return 0
        osascript >/dev/null <<<"$1"; }
key() { planned "press $*" && return 0
        cliclick "$@" >/dev/null; }
pause() { planned "wait ${1}s" && return 0
          perl -e "select(undef,undef,undef,$1)"; }

# ── the core primitive: wait for a SIGNAL, never for a duration ─────────────────────────────
# Every `sleep` in a recorder is a guess about how fast a machine is today. This polls a real
# condition and fails the take when it does not arrive, which is the difference between a
# recording that is wrong and a recording that is known to be wrong.
await() { # description timeout_seconds command...
  local what="$1" limit="$2"; shift 2
  local waited=0
  while ! "$@" >/dev/null 2>&1; do
    # bash has no sub-second sleep on every path, but perl is on every Mac.
    perl -e 'select(undef,undef,undef,0.1)'
    waited=$((waited + 1))
    [ "$waited" -gt $((limit * 10)) ] && return 1
  done
  return 0
}

await_clipboard() { # regex [timeout]
  planned "wait for the clipboard to match /$1/" && return 0
  await "clipboard matches /$1/" "${2:-8}" bash -c "pbpaste | grep -qE '$1'" \
    || die "the clipboard never matched /$1/ — the menu click did not land, or the action failed"
  say "clipboard matched /$1/"
}

await_file() { # path [timeout]
  planned "wait for $1 to appear" && return 0
  await "$1 exists" "${2:-8}" test -e "$1" || die "$1 never appeared — the action did not run"
  say "$(basename "$1") appeared"
}

# The strongest signal available. The sandboxed Finder extension writes a JSON request to
# ~/.chute/requests and the app deletes it once it has carried it out. An empty inbox therefore
# proves BOTH halves: the click reached the extension, and the app acted on it. Neither a pixel
# check nor a clipboard check can tell those two failures apart.
await_inbox_drained() { # [timeout]
  planned "wait for the request inbox to drain" && return 0
  local inbox="$HOME/.chute/requests"
  await "the request inbox drained" "${1:-10}" \
    bash -c "[ -z \"\$(ls -A '$inbox' 2>/dev/null | grep '\.json$')\" ]" \
    || die "a request is still sitting in $inbox — Chute.app is not draining it"
  say "the app carried the request out"
}

# ── measuring a picture ─────────────────────────────────────────────────────────────────────
# BOTH of these were wrong on the first attempt, in the same way and for the same reason: the
# obvious `signalstats | grep YAVG` prints NOTHING on this ffmpeg. The filter runs, produces its
# metadata, and emits none of it unless `metadata=print` is asked to write somewhere explicitly.
#
# That silence was not harmless. verify_take read an empty string, `[ -n "" ]` failed, and the
# guard's else-branch deletes the take — so every recording would have been made and then
# immediately destroyed as "essentially black", with a human sitting in front of the screen
# wondering where the files went. An empty measurement must never be read as a bad measurement.

# One signalstats value for one frame — YMAX, YAVG, YMIN.
frame_stat() { # file key [seek_seconds]
  ffmpeg -v error -ss "${3:-1}" -i "$1" -frames:v 1 \
         -vf "signalstats,metadata=print:key=lavfi.signalstats.$2:file=-" -f null - 2>/dev/null \
    | grep -o "$2=[0-9.]*" | head -1 | cut -d= -f2 | cut -d. -f1
}

# Is there anything on screen at all? YMAX, deliberately, NOT the mean.
#
# In limited-range yuv420p, pure black is Y=16 rather than 0 — so a mean-luminance threshold of
# 12 accepted a completely black recording, which the self-test caught. Worse, the mean cannot
# separate "the display slept" from "this is a dark UI": Chute's own ground is #0D0F17, which
# measures 29 — only 13 above pure black. But any window with a line of text in it has a bright
# pixel somewhere, and YMAX for real content is around 235. That gap is unambiguous.
frame_has_content() { # file [seek_seconds]
  local ymax; ymax="$(frame_stat "$1" YMAX "${2:-1}")"
  [ -n "$ymax" ] || return 2          # unmeasurable — the caller must not read this as "black"
  [ "$ymax" -ge 60 ]
}

# Mean squared error between two frames: 0 is identical, and it climbs fast with real change.
# psnr's own stats output, which unlike signalstats prints without being coaxed.
frame_mse() { # a.png b.png
  ffmpeg -v error -i "$1" -i "$2" -filter_complex "psnr=stats_file=-" -f null - 2>/dev/null \
    | grep -o 'mse_avg:[0-9.]*' | head -1 | cut -d: -f2 | cut -d. -f1
}

# One frame of a video, scaled small and optionally cropped, for comparing.
grab() { # file seek out.png [crop]
  ffmpeg -v error -y -ss "$2" -i "$1" -frames:v 1 \
         -vf "${4:+$4,}scale=160:-2" "$3" 2>/dev/null
}

# ── the scene ───────────────────────────────────────────────────────────────────────────────
scene() { # [subdir]
  # The fixture is built even in PLAN: it is what proves the tape's filenames are real, and a
  # plan that cannot catch a renamed file is not worth running.
  "$REPO/demo/fixtures/make.sh" "$FIXTURE" >/dev/null
  local target="$FIXTURE/${1:-src}"
  planned "open Finder at $target" && return 0
  osascript >/dev/null <<OSA
tell application "Finder"
    activate
    close every window
    make new Finder window to (POSIX file "$target")
    set bounds of front window to {$WIN_X, $WIN_Y, $((WIN_X + WIN_W)), $((WIN_Y + WIN_H))}
    set current view of front window to list view
end tell
OSA
  await "Finder to open $target" 5 osascript -e 'tell application "Finder" to return (count of windows) > 0' \
    || die "Finder never opened a window"
  # Clear the clipboard so a stale value cannot be mistaken for this take's result.
  : | pbcopy
}

# Select files BY NAME through Finder itself rather than by clicking coordinates. A coordinate
# is a guess about row height, sidebar width and sort order; a name is what the tape actually
# means, and it fails loudly when the fixture changes.
select_files() { # relative paths under the open folder
  planned "select $*" && return 0
  local list="" p
  for p in "$@"; do list="$list, (POSIX file \"$FIXTURE/$p\")"; done
  osascript >/dev/null <<OSA
tell application "Finder" to select {${list:2}}
OSA
  say "selected $*"
}

# The one thing PLAN can prove without a screen: that every path this tape names is really in
# the fixture. A renamed fixture file is otherwise found at recording time, with a human sitting
# there waiting, which is the most expensive moment to find it.
require_files() { # relative paths
  local missing="" p
  for p in "$@"; do [ -e "$FIXTURE/$p" ] || missing="$missing $p"; done
  [ -z "$missing" ] || die "the fixture has no:$missing
    demo/fixtures/make.sh builds it — this tape and that script disagree."
  say "all ${#@} fixture files present"
}

# ── the cursor ──────────────────────────────────────────────────────────────────────────────
# Eased, never teleported. A pointer that jumps between two points reads as synthetic, and the
# demo rules ban compensating for it with zoom effects, cursor rings or music — so the motion
# itself has to carry it. cliclick's own `w:` waits between steps.
move_to() { # x y [milliseconds]
  planned "move the cursor to $1,$2 over ${3:-400}ms" && return 0
  local x="$1" y="$2" ms="${3:-400}" steps=24 i
  local from; from="$(cliclick p | tr ',' ' ')"
  local fx fy; read -r fx fy <<<"$from"
  local per=$((ms / steps))
  for ((i = 1; i <= steps; i++)); do
    # ease-in-out on a 0..1 parameter, so it starts and stops the way a hand does.
    local t=$((i * 100 / steps))
    local e=$(( t < 50 ? 2 * t * t / 100 : 100 - 2 * (100 - t) * (100 - t) / 100 ))
    cliclick "m:$((fx + (x - fx) * e / 100)),$((fy + (y - fy) * e / 100))" "w:$per" >/dev/null
  done
}

# Where the current Finder selection actually is on screen, so a right-click lands on the
# selection rather than on a coordinate someone measured once in 2026.
selection_point() {
  osascript <<'OSA' 2>/dev/null || echo ""
tell application "System Events" to tell process "Finder"
    set r to position of (first UI element of outline 1 of scroll area 1 of splitter group 1 of window 1 whose selected is true)
    set s to size of (first UI element of outline 1 of scroll area 1 of splitter group 1 of window 1 whose selected is true)
    return ((item 1 of r) + (item 1 of s) / 4 as integer) & "," & ((item 2 of r) + (item 2 of s) / 2 as integer)
end tell
OSA
}

right_click_selection() {
  planned "right-click the selection" && return 0
  local pt; pt="$(selection_point | tr -d ' ')"
  if [ -z "$pt" ]; then
    # The Accessibility path is the one that breaks between macOS releases. Say so and fall back
    # to the window's own geometry rather than pretending the click was precise.
    say "accessibility could not locate the selection — falling back to window geometry"
    pt="$((WIN_X + 240)),$((WIN_Y + 150))"
  fi
  move_to "${pt%,*}" "${pt#*,}" 500
  cliclick "rc:$pt" >/dev/null
  say "right-clicked at $pt"
}

# Three routes, none of them believed. Whichever one worked is established afterwards by the
# caller's await_* — that is the whole contract of this file.
menu_pick() { # visible menu title
  planned "pick '$1' from the menu" && return 0
  local title="$1"
  perl -e 'select(undef,undef,undef,0.35)'   # the menu's own open animation, not a guess at work
  if osascript >/dev/null 2>&1 <<OSA
tell application "System Events" to tell process "Finder" to click menu item "$title" of menu 1 of window 1
OSA
  then say "picked '$title' by name"; return 0; fi
  # Type-ahead: macOS menus select the first item matching what you type.
  cliclick "t:${title:0:12}" >/dev/null
  perl -e 'select(undef,undef,undef,0.2)'
  cliclick kp:return >/dev/null
  say "picked '$title' by type-ahead"
}

# Two of the eight heroes film an action that now lives one level down — `seed` and `sandbox`
# moved under "Set Up for an Agent" when thirteen actions were grouped into eight rows. A submenu
# needs a hover to open before the child is reachable, and the hover has to be given time the
# same way a hand would.
menu_pick_sub() { # parent_title child_title
  planned "open '$1' and pick '$2'" && return 0
  pause 0.35
  if osascript >/dev/null 2>&1 <<OSA
tell application "System Events" to tell process "Finder"
    click menu item "$2" of menu 1 of menu item "$1" of menu 1 of window 1
end tell
OSA
  then say "picked '$1' → '$2' by name"; return 0; fi
  # Type-ahead to the parent, right-arrow to open it, type-ahead to the child. Every step is a
  # guess; what is believed is the caller's await_* afterwards.
  key "t:${1:0:10}"
  pause 0.2
  key kp:arrow-right
  pause 0.25
  key "t:${2:0:10}"
  pause 0.2
  key kp:return
  say "picked '$1' → '$2' by type-ahead"
}

# The menu-bar half. `chute sessions` and `chute ports` are the two menu-bar heroes, and neither
# is reachable from a Finder right-click — the status item has to be clicked where it actually is.
menubar_open() {
  planned "click the Chute status item" && return 0
  # Ask AppKit where it is rather than guessing at a screen coordinate: the menu bar's contents
  # shift with every other status item the user has installed, and a demo machine has different
  # ones from a developer machine.
  local pt; pt="$(osascript 2>/dev/null <<'OSA'
tell application "System Events" to tell process "Chute"
    set p to position of menu bar item 1 of menu bar 1
    set s to size of menu bar item 1 of menu bar 1
    return ((item 1 of p) + (item 1 of s) / 2 as integer) & "," & ((item 2 of p) + 10 as integer)
end tell
OSA
)"
  pt="$(printf '%s' "$pt" | tr -d ' ')"
  [ -n "$pt" ] || die "could not find Chute in the menu bar — is the app running, and is
    Accessibility granted to THIS terminal? System Settings → Privacy & Security → Accessibility."
  move_to "${pt%,*}" "${pt#*,}" 500
  key "c:$pt"
  say "opened the menu bar at $pt"
}

# ── the stopwatch ───────────────────────────────────────────────────────────────────────────
# The number on the landing page comes from HERE, not from a config file.
_t0=0
stopwatch_start() { _t0="$(perl -MTime::HiRes=time -e 'printf "%.3f", time')"; }
stopwatch_read()  { perl -MTime::HiRes=time -e "printf \"%.1f\", time - $_t0"; }

# ── takes ───────────────────────────────────────────────────────────────────────────────────
# take_start backgrounds the recorder and DOES NOT RETURN until it is actually writing. The old
# recorder backgrounded screencapture and immediately clicked, so the first ~0.5 s of every take
# happened before recording began; it papered over that with `( sleep 0.8; click ) &`, which is a
# guess about how fast the machine is today. Waiting for the file to exist is not a guess.
TAKE_PID=0; TAKE_NAME=""
take_start() { # name seconds
  TAKE_NAME="$1"
  planned "record $1 for ${2}s" && return 0
  rm -f "$OUT/$1.mov"
  # No -C. A captured cursor RING is the "cursor highlight" the demo rules ban; the plain arrow
  # is what the user actually sees on their own screen.
  screencapture -v -V "$2" -R"$WIN_X,$WIN_Y,$WIN_W,$WIN_H" "$OUT/$1.mov" &
  TAKE_PID=$!
  await "the recorder to start writing" 6 test -s "$OUT/$1.mov" \
    || die "screencapture never started — is Screen Recording granted to THIS terminal?"
  say "recording $1"
}

# The menu bar is not inside the Finder rectangle, so the two menu-bar heroes need their own
# region: a column under the status item, wide enough for the dropdown and tall enough for a long
# session list. Anchored to the RIGHT EDGE of the main display rather than to a fixed x, because
# where Chute sits depends on how many other status items the machine has.
take_menubar() { # name seconds
  TAKE_NAME="$1"
  planned "record the menu bar for ${2}s" && return 0
  local w; w="$(osascript -e 'tell application "Finder" to return item 1 of (bounds of window of desktop)' 2>/dev/null)"
  local sw; sw="$(osascript -e 'tell application "Finder" to return item 3 of (bounds of window of desktop)' 2>/dev/null)"
  [ -n "$sw" ] || die "could not read the display width"
  local x=$(( sw - MENUBAR_W ))
  rm -f "$OUT/$1.mov"
  screencapture -v -V "$2" -R"$x,0,$MENUBAR_W,$MENUBAR_H" "$OUT/$1.mov" &
  TAKE_PID=$!
  await "the recorder to start writing" 6 test -s "$OUT/$1.mov" \
    || die "screencapture never started — is Screen Recording granted to THIS terminal?"
  say "recording $1 (menu bar, ${MENUBAR_W}x${MENUBAR_H} at ${x},0)"
}

take_wait() {
  planned "wait for the recording to finish" && return 0
  wait "$TAKE_PID" 2>/dev/null || true
}

# A take is not an asset until it has been checked. These are cheap and they catch the two
# failures that look identical to a human skimming a directory listing: a black recording, and
# one that stopped early.
verify_take() { # name expected_seconds
  local f="$OUT/$1.mov" want="$2"
  [ "$PLAN" = "1" ] && return 0
  [ -s "$f" ] || die "$f is empty — screencapture produced nothing"
  local dur; dur="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" | cut -d. -f1)"
  [ "$dur" -ge $((want - 2)) ] || { rm -f "$f"; die "$1 is ${dur}s, expected about ${want}s — take discarded"; }
  # Mean luminance of a frame a second in. A window that never drew, or a display that slept,
  # comes out near zero and is otherwise indistinguishable from a good file in a directory listing.
  frame_has_content "$f" 1
  case $? in
    0) : ;;                                   # something was drawn
    2) say "⚠ could not measure $1 — keeping it, look at it yourself" ;;
    *) rm -f "$f"
       die "$1 never drew anything (brightest pixel $(frame_stat "$f" YMAX 1), black is 16) — take discarded" ;;
  esac
  say "$1.mov — ${dur}s, not blank"
}

# ── the measurement the page is allowed to quote ────────────────────────────────────────────
# Pass "-" for a side that was NOT measured. Only the race tape performs the manual ritual; the
# other seven film the Chute path alone, and writing the ledger's own estimate into a file called
# "measured" would make check-cases.mjs compare a number against itself and report agreement.
# That is worse than no measurement: it looks like evidence.
emit_timing() { # slug manual_seconds|- chute_seconds
  # NEVER in PLAN. A dry run reads 0.0s off a stopwatch that was never started, and writing that
  # out produced a timing file the deploy gate then trusted — a dry run silently poisoning the
  # numbers on the live site. Caught by check-cases.mjs on its first run against this directory,
  # which is the argument for having the gate read the measurements at all.
  planned "record the measured timing for $1" && return 0
  mkdir -p "$OUT"
  local manual="$2"
  [ "$manual" = "-" ] && manual="null"
  cat > "$OUT/$1.json" <<JSON
{
  "slug": "$1",
  "measured": { "manual": $manual, "chute": $3 },
  "note": "Seconds read off a stopwatch around a real take. null means that side was not performed — only the race tape runs the manual ritual. Consumed by site/scripts/check-cases.mjs."
}
JSON
  if [ "$manual" = "null" ]; then
    say "measured: chute ${3}s (the manual side was not performed by this tape)"
  else
    say "measured: manual ${2}s vs chute ${3}s"
  fi
}

# ── delivery ────────────────────────────────────────────────────────────────────────────────
# WHY THERE IS NO drawtext ANYWHERE: the ffmpeg on this machine is built without that filter.
# Found by running the filtergraph on synthetic input, not at recording time with a human sitting
# in front of the screen. Every caption is a PNG from overlay.py instead, which also means the
# demos are captioned in JetBrains Mono and the palette from brand/tokens.json rather than in
# whatever ffmpeg's default face happens to be.
OVERLAY="$GUI_HERE/overlay.py"

# THE HERO ARTIFACT. Two takes of the same job, side by side, aligned at their true start.
#
# The problem this solves: the manual ritual really does take 95 seconds, and nobody watches a
# 95-second video of someone copy-pasting. Speeding it up would break the one rule the demo
# cannot break (real speed — "the speed is the pitch"). So the manual take is MEASURED in full
# and SHOWN in part: the race runs until the point is made, the right-hand clock stops at the
# moment the job really finished, and the last frame states exactly how much of the left-hand run
# you are not being shown. Short, and it declares its own omission.
#
# The two takes are recorded separately and composed. Driving two Finder windows at once is not
# reliable, and pretending otherwise would be the lie. The frame says so itself, top right, so
# the artifact can explain itself when it is reposted without the page around it.
compose_race() { # slug manual_seconds chute_seconds [display_seconds]
  local slug="$1" manual="$2" chute="$3" show="${4:-14}"
  planned "compose the race for $slug (${show}s of a ${manual}s ritual)" && return 0
  local L="$OUT/$slug-manual.mov" Rr="$OUT/$slug.mov"
  [ -s "$L" ] && [ -s "$Rr" ] || die "compose_race needs both takes: $L and $Rr"

  local have; have="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$L" | cut -d. -f1)"
  [ "$have" -ge "$show" ] || die "the manual take is only ${have}s — cannot show ${show}s of it"

  python3 "$OVERLAY" labels "$OUT/$slug-label.png" --width 1920 >/dev/null
  python3 "$OVERLAY" clock  "$OUT/$slug-clock" --width 1920 --height 660 \
          --manual "$manual" --chute "$chute" --seconds "$show" >/dev/null

  # Left is trimmed to the display length; right plays out and then HOLDS its final frame
  # (tpad clone), which is what makes "done, and the other one is still going" legible.
  ffmpeg -v error -y \
    -i "$L" -i "$Rr" -i "$OUT/$slug-label.png" \
    -framerate 1 -start_number 0 -i "$OUT/$slug-clock/%03d.png" \
    -filter_complex "\
[0:v]trim=0:${show},setpts=PTS-STARTPTS,scale=960:600[L];\
[1:v]scale=960:600,tpad=stop_mode=clone:stop_duration=${show}[R];\
[L][R]hstack=inputs=2[row];\
[row]pad=1920:660:0:60:color=0x0D0F17[padded];\
[padded][2:v]overlay=0:0[labeled];\
[labeled][3:v]overlay=0:0:shortest=0[out]" \
    -map "[out]" -t "$show" -c:v libx264 -pix_fmt yuv420p -crf 23 -movflags +faststart -an \
    "$OUT/$slug-race.mp4" || die "compose failed for $slug"
  rm -rf "$OUT/$slug-clock" "$OUT/$slug-label.png"
  say "$slug-race.mp4 — ${show}s of a ${manual}s ritual, beside a ${chute}s one"
}

# The solo take, which is what the case pages and every phone actually get. A side-by-side race
# is 187px per panel at 375px wide and unreadable there, so the race is a desktop artifact and
# this is the one that has to survive the crop.
export_web() { # slug
  local slug="$1" src="$OUT/$1.mov"
  planned "export $slug to mp4/webm/poster" && return 0
  [ -s "$src" ] || die "no take to export: $src"
  # scale=1280:-2 normalises the 2x that screencapture produces on a Retina display; -2 keeps
  # the height even, which h264 requires and which is otherwise an obscure encoder failure.
  ffmpeg -v error -y -i "$src" -vf "scale=1280:-2" -c:v libx264 -pix_fmt yuv420p -crf 23 \
         -movflags +faststart -an "$OUT/$slug.mp4" || die "mp4 export failed"
  ffmpeg -v error -y -i "$src" -vf "scale=1280:-2" -c:v libvpx-vp9 -crf 34 -b:v 0 -an \
         "$OUT/$slug.webm" 2>/dev/null || say "no vp9 in this ffmpeg — mp4 only"
  # The poster is the FIRST frame, not a flattering one from the middle: it is what a viewer
  # stares at before the video plays, and it should be the problem state, which is the hook.
  ffmpeg -v error -y -ss 0 -i "$src" -frames:v 1 -vf "scale=1280:-2" -q:v 3 \
         "$OUT/$slug.jpg" || die "poster export failed"

  local kb; kb=$(( $(stat -f%z "$OUT/$slug.mp4") / 1024 ))
  say "$slug.mp4 ${kb}KB"
  # A landing page that ships four 3 MB videos is slow on the connection of the person most
  # likely to be on a train. Loud, not fatal — re-encode or shorten the take.
  [ "$kb" -gt 2500 ] && say "⚠ ${kb}KB is over the 2500KB budget — shorten the take or raise crf"
  return 0
}

# Case-page demos autoplay muted on a loop. A take that ends somewhere different from where it
# started produces a visible jump every few seconds, which is the single most irritating thing a
# background video can do. The tape is responsible for returning the scene; this proves it did.
verify_loop() { # slug [tolerance]
  # Split, not one `local`: bash expands every word of a local statement BEFORE assigning any of
  # them, so `f="$OUT/$slug.mov"` on the same line as `slug="$1"` reads an unset variable and
  # dies under `set -u`. Caught by PLAN mode on the first run after wiring it up.
  local slug="$1" tol="${2:-14}"
  local f="$OUT/$slug.mov"
  planned "check that $slug loops cleanly" && return 0
  local dur; dur="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")"
  local last; last="$(perl -e "printf '%.1f', $dur - 0.2")"
  grab "$f" 0 /tmp/chute-loop-a.png
  grab "$f" "$last" /tmp/chute-loop-b.png
  local diff; diff="$(frame_mse /tmp/chute-loop-a.png /tmp/chute-loop-b.png)"
  rm -f /tmp/chute-loop-a.png /tmp/chute-loop-b.png
  [ -z "$diff" ] && { say "could not measure the loop seam for $slug"; return 0; }
  if [ "$diff" -le "$tol" ]; then
    say "$slug loops cleanly (seam $diff)"
  else
    say "⚠ $slug jumps on loop (seam $diff) — end the tape where it began, or it will flicker"
  fi
}
