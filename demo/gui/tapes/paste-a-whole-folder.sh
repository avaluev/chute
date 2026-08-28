#!/usr/bin/env bash
# THE WEDGE, recorded as an argument rather than as a feature tour.
#
# Case: site/src/lib/cases.ts → paste-a-whole-folder-into-your-agent (JTBD 2, 41.1 min/day).
#
# Two takes, one fixture, one stopwatch:
#   A — the ritual. Eight files, opened and copied one at a time, the way it is done today.
#   B — the same folders, right-clicked once.
# The clock burned into each take is read off the stopwatch, not typed into this file, and the
# pair is written to out/gui/<slug>.json where check-cases.mjs compares it to what the landing
# page claims. If the ritual turns out to be faster than the ledger says, the PAGE is wrong.
#
# HONESTY RULE FOR TAKE A: it must be the WHOLE ritual, including pasting into something. A
# manual path that stops after the copy measures half the work and quietly inflates the saving —
# the exact failure this apparatus exists to prevent, committed by the apparatus.
#
# A tape speaks only in verbs from ../lib.sh. No raw osascript, cliclick or sleep: `make lint`
# fails on those, because that is how a dry run once started driving the real cursor.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SLUG="paste-a-whole-folder-into-your-agent"

# WHAT GETS RIGHT-CLICKED. Three folders, because that is what a person actually selects — not
# six individually shift-clicked files. `bundle` expands them, so one click covers everything
# inside. The first draft of this tape named eight invented filenames; PLAN mode caught it
# before a human had sat down to record, which is the entire point of PLAN mode.
SELECT=(src/auth src/api src/ui)

# WHAT THE RITUAL OPENS. The same content, reached the way it is reached today: one file at a
# time. This list and SELECT must cover the same bytes or the two clocks are not comparable.
RITUAL=(src/auth/session.ts src/auth/token.ts src/api/client.ts src/api/routes.ts
        src/ui/Avatar.tsx src/ui/Nav.tsx)

preflight
scene
require_files "${SELECT[@]}" "${RITUAL[@]}"

# ── Take A — what it costs today ────────────────────────────────────────────────────────────
# Opens on the PROBLEM, not on Chute. The before-state is the hook: a viewer who has done this
# recognises it in the first second, and that recognition is what the rest of the page trades on.
say "take A — the ritual"
take_start "$SLUG-manual" 95
stopwatch_start          # after the recorder is writing, so it times the WORK, not the startup

# A scratch document standing in for the agent's input box. The paste has to land SOMEWHERE or
# this measures copying, not the job.
#
# TextEdit is driven WITHOUT its own AppleScript dictionary: `tell application "TextEdit"` needs
# a per-target Automation grant, and on a machine where that pair was never approved the consent
# prompt does not draw and every event dies at the AE timeout (measured 2026-08-28). Launch
# Services (`open`) and System Events are the two channels every recording machine already
# trusts, so the ritual speaks only through them.
scratch_editor 1420 120 580 800

for f in "${RITUAL[@]}"; do
  open_in_editor "$FIXTURE/$f"   # waits for the window, rather than betting 0.8s on the machine
  key kd:cmd t:a ku:cmd          # select all
  key kd:cmd t:c ku:cmd          # copy
  key kd:cmd t:w ku:cmd          # close it again
  pause 0.2
  key kd:cmd t:v ku:cmd          # and into the "prompt"
  key "t:$(basename "$f")"       # the filename you have to type yourself
  key kp:return
done
MANUAL="$(stopwatch_read)"
take_wait
close_editor                     # scratch only; nothing in it is worth a save sheet
verify_take "$SLUG-manual" 95

# ── Take B — the same job ───────────────────────────────────────────────────────────────────
say "take B — one right-click"
scene
select_files "${SELECT[@]}"
take_start "$SLUG" 12
stopwatch_start

right_click_selection
menu_pick "Copy Files as Context"
await_inbox_drained
# The wedge's whole claim is contents PLUS a token count. Assert both, or a take that copied
# only the paths passes every check and ships as proof of something it does not show.
await_clipboard 'export (async )?function loadSession'
await_clipboard '<file path='
CHUTE_SECS="$(stopwatch_read)"
take_wait
verify_take "$SLUG" 12

# The scene is returned to where it opened, so the case page's autoplaying loop does not jump
# every twelve seconds. verify_loop measures the seam and says so if this was not enough.
key kp:esc
pause 0.6

# THE MANUAL SIDE IS NOT MEASURED, and this is the whole finding of the first real recording run.
#
# A script performing the ritual is not a person performing the ritual. This loop opened six
# files, selected, copied, closed and pasted each one in 6.5 SECONDS — the ledger says 150s
# because 150s is what a HUMAN takes: aiming a mouse, reading, finding the next file. Frames 8s
# through 90s of the 95-second take are one static image (mse 0.13); the robot had finished and
# the recorder ran on alone.
#
# 6.5s beside Chute's 5.6s does not argue for the product, it argues against it — and it would
# have been printed under "backed by a stopwatch, not an estimate". That is the same dishonesty
# this apparatus already caught once, when emit_timing was handed the ledger's own figure and
# agreed with itself. A real clock timing the wrong performer is not better than an estimate.
#
# So: `-`, like the other seven tapes. The saving stays a ledger estimate and check-cases.mjs
# says so out loud. The only honest way to earn the claim is a human doing the ritual on camera,
# which is a decision about the demo, not about this file.
emit_timing  "$SLUG" - "$CHUTE_SECS"
export_web   "$SLUG"                                  # mp4 + webm + poster, for every case page
verify_loop  "$SLUG"
# THE RACE IS OFF until a human performs Take A. It burns $MANUAL into a clock beside Chute's
# number, and $MANUAL is 6.5s of robot — a side-by-side of 6.5s against 5.6s is an argument
# against buying. compose_race, overlay.py's clock mode and six of selftest's twelve assertions
# are all still here and all still pass; the only thing missing is a manual take worth racing.
# Re-enable this line the moment Take A is performed by a person:
#   compose_race "$SLUG" "$MANUAL" "$CHUTE_SECS" 14

say "done:"
say "  $OUT/$SLUG.mp4        the solo take — case pages, the landing hero, and every phone"
say "  $OUT/$SLUG.json       the Chute side off a stopwatch; the manual side is null on purpose"
