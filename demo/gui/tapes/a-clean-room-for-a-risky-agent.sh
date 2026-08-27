#!/usr/bin/env bash
# "I want to let it run wild, but not in this repo."
# Case: a-clean-room-for-a-risky-agent (JTBD 6, 7.3 min/day).
#
# --no-launch is NOT used here: the whole point is that the terminal comes up with the agent
# already running in it, and a demo that stops before that shows a folder being created, which is
# not the job. It does mean this tape leaves a terminal behind — the one tape that does, and the
# reason it is not in the generated set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SLUG="a-clean-room-for-a-risky-agent"

preflight
scene
require_files "src"

take_start "$SLUG" 15
stopwatch_start

right_click_selection
menu_pick_sub "Set Up for an Agent" "New Clean Room for an Agent"
await_inbox_drained
CHUTE_SECS="$(stopwatch_read)"
take_wait
verify_take "$SLUG" 15

emit_timing "$SLUG" - "$CHUTE_SECS"
export_web  "$SLUG"
verify_loop "$SLUG"
say "done — $OUT/$SLUG.mp4"
say "NOTE: this tape leaves a terminal running an agent. Close it before the next take."
