#!/usr/bin/env bash
# Record the Finder and menu-bar demos — the half VHS cannot reach.
#
# VHS owns the terminal. This owns everything else: the right-click menu, the menu-bar switcher,
# the ⌥⌘N popup. Those are the shots that sell the APP rather than the CLI, and they are the
# reason the landing page has a hero at all.
#
# THIS NEEDS A HUMAN AT THE MACHINE. It drives the real cursor and records the real screen, so it
# cannot run in CI, cannot run over SSH, and will fight you for the pointer while it works.
# macOS will ask for Screen Recording and Accessibility the first time; grant both to your
# terminal, not to Chute.
#
#   ./record.sh list                 what can be recorded
#   ./record.sh bundle               one shot
#   ./record.sh all                  every shot, with a countdown between
#   ./record.sh bundle --dry-run     set the scene, print the plan, record nothing
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
OUT="$HERE/../out/gui"
FIXTURE="${CHUTE_GUI_FIXTURE:-$HOME/Desktop/acme-app}"

# A fixed window rectangle, so every recording crops identically and the assets look like one
# session rather than five. 1280x800 at (120,120) fits inside any Mac display Chute supports.
WIN_X=120; WIN_Y=120; WIN_W=1280; WIN_H=800

DRY=0
for a in "$@"; do [ "$a" = "--dry-run" ] && DRY=1; done

need() { command -v "$1" >/dev/null || { echo "missing: $1 — brew install $2"; exit 1; }; }
need cliclick cliclick
need ffmpeg ffmpeg

# ---------------------------------------------------------------- permissions
# Failing here with a clear sentence beats producing a black 12-second video and finding out later.
check_permissions() {
  local probe="/tmp/chute-permcheck-$$.png"
  screencapture -x -R0,0,8,8 "$probe" 2>/dev/null || true
  if [ ! -s "$probe" ]; then
    cat >&2 <<'MSG'
Screen Recording is not granted to this terminal.
  System Settings → Privacy & Security → Screen & System Audio Recording → enable your terminal,
  then QUIT AND REOPEN it. macOS only re-reads that permission on launch.
MSG
    exit 1
  fi
  rm -f "$probe"
}

# ---------------------------------------------------------------- scene
scene() {
  "$REPO/demo/fixtures/make.sh" "$FIXTURE" >/dev/null
  osascript >/dev/null <<OSA
tell application "Finder"
    activate
    close every window
    make new Finder window to (POSIX file "$FIXTURE/src")
    set bounds of front window to {$WIN_X, $WIN_Y, $((WIN_X + WIN_W)), $((WIN_Y + WIN_H))}
    set current view of front window to list view
end tell
OSA
  sleep 1.2
}

record() {  # name seconds
  local name="$1" secs="$2"
  mkdir -p "$OUT"
  # -v records video, -R the region, -V the duration. No -C: a captured cursor RING is the
  # "cursor highlight" the demo rules ban; the plain arrow is what a user actually sees.
  screencapture -v -V "$secs" -R"$WIN_X,$WIN_Y,$WIN_W,$WIN_H" "$OUT/$name.mov"
}

countdown() { for i in 3 2 1; do printf "\r  recording in %s… " "$i"; sleep 1; done; printf "\r%-24s\r" ""; }

# ---------------------------------------------------------------- the shots

shot_bundle() {  # THE HERO: right-click a selection, copy files with contents.
  scene
  # Select the two source folders the way a person would: click the first, shift-click the last.
  cliclick "m:$((WIN_X + 200)),$((WIN_Y + 120))" w:400 "c:$((WIN_X + 200)),$((WIN_Y + 120))"
  sleep 0.3
  cliclick kd:shift "c:$((WIN_X + 200)),$((WIN_Y + 160))" ku:shift
  sleep 0.5
  [ "$DRY" = "1" ] && { echo "  would right-click at $((WIN_X + 200)),$((WIN_Y + 160)) and record 9s"; return; }
  countdown
  ( sleep 0.8; cliclick "rc:$((WIN_X + 200)),$((WIN_Y + 160))" ) &
  record bundle 9
}

shot_menubar() {  # Act two: the badge, and which agent is waiting.
  scene
  [ "$DRY" = "1" ] && { echo "  would click the menu-bar item and record 8s"; return; }
  echo "  click the ⤓ in the menu bar when recording starts"
  countdown
  record menubar 8
}

shot_hotkey() {  # ⌥⌘N from wherever you happen to be.
  scene
  [ "$DRY" = "1" ] && { echo "  would press ⌥⌘N and record 7s"; return; }
  countdown
  ( sleep 1.0; cliclick kd:alt,cmd t:n ku:alt,cmd ) &
  record hotkey 7
}

shot_ports() {  # The local-servers submenu, for the "which window holds :3000" story.
  scene
  [ "$DRY" = "1" ] && { echo "  would open the menu bar and hover Local Servers, record 8s"; return; }
  echo "  open the ⤓ menu and hover Local Servers when recording starts"
  countdown
  record ports 8
}

SHOTS="bundle menubar hotkey ports"

case "${1:-list}" in
  list) echo "shots: $SHOTS"; echo "output: $OUT"; echo "fixture: $FIXTURE";;
  all)
    check_permissions
    for s in $SHOTS; do echo "→ $s"; "shot_$s"; sleep 1; done
    ;;
  bundle|menubar|hotkey|ports)
    [ "$DRY" = "1" ] || check_permissions
    echo "→ $1"; "shot_$1"
    ;;
  *) echo "usage: record.sh [list|all|bundle|menubar|hotkey|ports] [--dry-run]"; exit 1;;
esac

if [ "$DRY" = "0" ] && [ -d "$OUT" ]; then
  echo
  ls -la "$OUT"/*.mov 2>/dev/null | awk '{printf "  %-40s %sKB\n", $9, int($5/1024)}'
  echo
  echo "Next: turn one into every social format —"
  echo "  cd $REPO/demo && ./reframe.sh out/gui/bundle.mov hero"
fi
