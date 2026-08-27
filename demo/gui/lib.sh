#!/usr/bin/env bash
# The verbs a GUI demo is written in.
#
# VHS owns the terminal demos and they are demos-as-code: a tape file, a deterministic fixture,
# and `make` to regenerate all thirteen. The GUI half had none of that — record.sh performs three
# of its four shots by asking a human to click something, and clicks the fourth at a hardcoded
# pixel offset after a blind `sleep 0.8`. If Finder is 200 ms slow that click lands on empty
# space and you get nine seconds of a static window. Nothing notices.
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
  # comes out near zero and is otherwise indistinguishable from a good file.
  local lum; lum="$(ffmpeg -v error -ss 1 -i "$f" -frames:v 1 -vf signalstats -f null - 2>&1 \
                    | grep -o 'YAVG:[0-9.]*' | head -1 | cut -d: -f2 | cut -d. -f1)"
  [ -n "$lum" ] && [ "$lum" -gt 12 ] || { rm -f "$f"; die "$1 is essentially black (YAVG=${lum:-?}) — take discarded"; }
  say "$1.mov — ${dur}s, not blank"
}

# ── the measurement the page is allowed to quote ────────────────────────────────────────────
emit_timing() { # slug manual_seconds chute_seconds
  # NEVER in PLAN. A dry run reads 0.0s off a stopwatch that was never started, and writing that
  # out produced a timing file the deploy gate then trusted — a dry run silently poisoning the
  # numbers on the live site. Caught by check-cases.mjs on its first run against this directory,
  # which is the argument for having the gate read the measurements at all.
  planned "record the measured timing for $1" && return 0
  mkdir -p "$OUT"
  cat > "$OUT/$1.json" <<JSON
{
  "slug": "$1",
  "measured": { "manual": $2, "chute": $3 },
  "note": "Seconds read off a stopwatch around two real takes, not estimated. Consumed by site/scripts/check-cases.mjs."
}
JSON
  say "measured: manual ${2}s vs chute ${3}s"
}

# The clock the viewer sees is drawn from the MEASURED time. Burning a configured number here
# would reintroduce exactly the gap this file exists to close.
burn_clock() { # name label seconds
  local f="$OUT/$1.mov" font="/Library/Fonts/JetBrainsMono-Regular.ttf"
  [ "$PLAN" = "1" ] && { say "would burn '$2 — ${3}s' onto $1.mov"; return 0; }
  [ -f "$font" ] || font="/System/Library/Fonts/SFNSMono.ttf"
  ffmpeg -v error -y -i "$f" -vf \
    "drawtext=fontfile=$font:text='$2  %{eif\\:t\\:d}s':x=w-tw-28:y=28:fontsize=28:fontcolor=0xF7F7F7:box=1:boxcolor=0x0D0F17@0.85:boxborderw=10" \
    "$OUT/$1-clocked.mov"
  mv "$OUT/$1-clocked.mov" "$f"
  say "clock burned in from the measured ${3}s"
}
