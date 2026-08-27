#!/usr/bin/env bash
# "Command-N, Command-V, Command-S, find the folder, type a name. Twenty-five times a day."
# Case: clipboard-straight-into-a-file (JTBD 3, 12.9 min/day).
#
# The detail that sells it is the NAME. The file is named from the answer's own first heading and
# its extension comes from the code inside it — so the shot has to hold on the filename appearing
# in Finder, which is the moment the viewer realises they did not have to invent one.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SLUG="clipboard-straight-into-a-file"

preflight
scene
require_files "src"
osa "set the clipboard to \"# Session Refresh Notes

The token refresh races when two tabs reload at once.\""

take_start "$SLUG" 12
stopwatch_start

right_click_selection
menu_pick_sub "New File Here" "New Markdown File from Clipboard"
await_inbox_drained
await_file "$FIXTURE/src/Session_Refresh_Notes.md" 8
CHUTE_SECS="$(stopwatch_read)"
take_wait
verify_take "$SLUG" 12

emit_timing "$SLUG" - "$CHUTE_SECS"
export_web  "$SLUG"
verify_loop "$SLUG"
say "done — $OUT/$SLUG.mp4"
