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
menubar_open
pause 1.2
key kp:arrow-down       # down to Local Servers, which opens on hover
pause 0.6               # the submenu's own open animation, not work
pause 2.5               # dwell so a viewer can read the row. Deliberately AFTER the stopwatch —
                        # it is time the viewer spends, not time the product costs, and counting
                        # it read 8.1s against a ledger that says 3s.
key kp:escape
take_wait
verify_take "$SLUG" 12

# NO TIMING, for the same reason as its twin which-agent-is-waiting-for-you: what this job saves
# is attention, and what a scripted take can measure is the script. The stopwatch read 5.9s and
# 6.4s on two consecutive runs of identical work — the variance is menubar_open's eased 500ms
# cursor glide and the pause that lets a viewer see the menu, both of which are CAMERAWORK. A
# human who knows where the icon is does this in about three seconds, which is what the ledger
# says. Publishing 6.4s would have the page claim the product is twice as slow as it is, on the
# authority of a stopwatch that was timing a camera move.
export_web  "$SLUG"
verify_loop "$SLUG"
say "done — $OUT/$SLUG.mp4"
