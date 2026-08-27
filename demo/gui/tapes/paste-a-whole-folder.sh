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
osa 'tell application "TextEdit"
       activate
       make new document
       set bounds of front window to {1420, 120, 2000, 920}
     end tell'

for f in "${RITUAL[@]}"; do
  osa "tell application \"TextEdit\" to open POSIX file \"$FIXTURE/$f\""
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
osa 'tell application "TextEdit" to close every document saving no'
verify_take "$SLUG-manual" 95

# ── Take B — the same job ───────────────────────────────────────────────────────────────────
say "take B — one right-click"
scene
select_files "${SELECT[@]}"
take_start "$SLUG" 12
stopwatch_start

right_click_selection
menu_pick "Copy Files with Contents"
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

emit_timing  "$SLUG" "$MANUAL" "$CHUTE_SECS"
export_web   "$SLUG"                                  # mp4 + webm + poster, for every case page
verify_loop  "$SLUG"
compose_race "$SLUG" "$MANUAL" "$CHUTE_SECS" 14       # the wide hero, desktop only

say "done:"
say "  $OUT/$SLUG.mp4        the solo take — case pages, and every phone"
say "  $OUT/$SLUG-race.mp4   the race — landing hero, too wide to read at 375px"
say "  $OUT/$SLUG.json       what the stopwatch read, consumed by check-cases.mjs"
