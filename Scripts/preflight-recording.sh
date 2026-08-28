#!/usr/bin/env bash
# Everything that must be true before a human sits down to record, checked in one place.
#
# It exists because each of these has cost a take: an app that was not running, a terminal without
# the Screen Recording grant, a stale extension, and a notification banner that landed inside the
# frame. None of them is visible until you watch the recording back.
#
# Read-only. It changes nothing and grants nothing — macOS will not let it.
set -uo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pass=0; fail=0
ok()  { printf '  ok    %s\n' "$1"; pass=$((pass+1)); }
bad() { printf '  FAIL  %s\n       → %s\n' "$1" "$2"; fail=$((fail+1)); }

printf '\nBefore you record\n\n'

# 1 ── the app
if pgrep -x ChuteApp >/dev/null; then ok "Chute.app is running"
else bad "Chute.app is not running" "open ~/Applications/Chute.app  — without it the Finder rows do nothing"; fi

# 2 ── Screen Recording, for THIS terminal. The only honest probe is to try it.
probe="${TMPDIR:-/tmp}/chute-preflight-$$.png"
screencapture -x -R0,0,8,8 "$probe" 2>/dev/null
if [ -s "$probe" ]; then ok "Screen Recording is granted to this terminal"
else bad "Screen Recording is NOT granted to this terminal" \
         "System Settings → Privacy & Security → Screen Recording. Quit and reopen Terminal after granting."; fi
rm -f "$probe"

# 3 ── Accessibility, which is what moves the cursor and types into menus
if osascript -e 'tell application "System Events" to return name of first process whose frontmost is true' >/dev/null 2>&1
then ok "Accessibility is granted to this terminal"
else bad "Accessibility is NOT granted to this terminal" \
         "System Settings → Privacy & Security → Accessibility."; fi

# 4 ── the extension, end to end
if [ -x .build/release/chute ]; then
  line="$(.build/release/chute doctor 2>&1 | head -1)"
  case "$line" in *"all"*"checks passed"*) ok "chute doctor: $line" ;;
                  *) bad "chute doctor is not clean — $line" "run: .build/release/chute doctor" ;; esac
else bad "no release binary" "swift build -c release"; fi

# 5 ── Do Not Disturb. A banner inside the frame ruins a take and cannot be undone.
#     macOS exposes no supported read for Focus, so this is a REMINDER, not a check — and it is
#     labelled as one rather than reporting a green tick nobody verified.
printf '  note  Turn Do Not Disturb ON by hand — Control Centre → Focus.\n'
printf '        A notification banner inside the frame makes a take unusable.\n'

# 6 ── the fixture, and whether a previous run left anything in it
FIXTURE="${CHUTE_GUI_FIXTURE:-$HOME/Desktop/acme-app}"
if [ -d "$FIXTURE" ]; then
  strays="$(find "$FIXTURE" -maxdepth 2 -name 'chute-*' -type d 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$strays" = "0" ]; then ok "fixture is clean: $FIXTURE"
  else printf '  note  %s scratch folder(s) left by an earlier take — `scene` rebuilds the\n        fixture, so they clear on the next recording.\n' "$strays"; fi
else bad "no fixture at $FIXTURE" "./demo/fixtures/make.sh \"$FIXTURE\""; fi

printf '\npreflight: %s passed, %s failed\n\n' "$pass" "$fail"
[ "$fail" = "0" ] || exit 1
printf 'Next: ./demo/gui/by-hand.sh    (the manual ritual — see docs/13-RECORDING-BY-HAND.md)\n\n'
