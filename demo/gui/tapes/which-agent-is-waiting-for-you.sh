#!/usr/bin/env bash
# "Nine terminals. One of them stopped four minutes ago and I don't know which."
# Case: which-agent-is-waiting-for-you — the menu bar, and the ONLY hero with no minutes figure.
#
# It buys back attention rather than seconds, so there is no stopwatch here and emit_timing is
# deliberately not called. Inventing a number for this one would make the other twenty-four less
# believable, which is the opposite of what the whole apparatus is for.
#
# THE BADGE NEEDS HOOKS. Without them every session reads `working` and the count stays dark, so
# this is the one demo whose SETUP is on the operator: wire the hooks snippet into your own
# settings first, and have at least one session actually waiting.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SLUG="which-agent-is-waiting-for-you"

preflight
say "check first: chute sessions should list more than one, with at least one waiting"

take_menubar "$SLUG" 12
menubar_open
pause 3.5          # long enough to read the grouping — this shot is READ, not watched
key kp:escape
take_wait
verify_take "$SLUG" 12

export_web  "$SLUG"
verify_loop "$SLUG"
say "done — $OUT/$SLUG.mp4  (no timing: this one costs attention, not seconds)"
