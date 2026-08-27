#!/usr/bin/env bash
# "Something is on 3000 and I cannot find which window it is in."
# Case: whats-on-port-3000 (JTBD 15, 4.9 min/day) — the second menu-bar hero.
#
# The row has to be legible: port, what the process actually is, and the project it belongs to.
# That is why the menu-bar capture is 900 wide — narrower and the project name crops, which is
# the half of the row that answers the question.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SLUG="whats-on-port-3000"

preflight
say "check first: chute ports should list something on :3000"

take_menubar "$SLUG" 12
stopwatch_start
menubar_open
pause 1.2
key kp:arrow-down       # down to Local Servers, which opens on hover
pause 2.5
CHUTE_SECS="$(stopwatch_read)"
key kp:escape
take_wait
verify_take "$SLUG" 12

emit_timing "$SLUG" - "$CHUTE_SECS"
export_web  "$SLUG"
verify_loop "$SLUG"
say "done — $OUT/$SLUG.mp4"
