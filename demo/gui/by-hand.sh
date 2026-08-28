#!/usr/bin/env bash
# THE ONE TAKE A SCRIPT CANNOT MAKE.
#
# Every tape in tapes/ is performed by cliclick and System Events, and for the CHUTE side that is
# honest: the product's latency is the product's latency whoever triggers it. For the MANUAL side
# it is not. A script types ⌘A the instant the window draws; a person looks, aims, reads, finds
# the next file. Run as a tape, the wedge's manual ritual measured 6.5 SECONDS against a ledger
# that says 150 — and 6.5s beside Chute's 5.6s is an argument against buying the product.
#
# So this one is performed by you. The recorder runs open-ended and stops when you say the job is
# done, so the take is exactly as long as the work and the clock is a clock. Everything after that
# — verification, the timing file, the side-by-side — is the same pipeline every tape uses.
#
# Usage:  ./demo/gui/by-hand.sh                 record the manual ritual and build the race
#         PLAN=1 ./demo/gui/by-hand.sh          resolve everything, record nothing
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

SLUG="paste-a-whole-folder-into-your-agent"
RITUAL=(src/auth/session.ts src/auth/token.ts src/api/client.ts src/api/routes.ts
        src/ui/Avatar.tsx src/ui/Nav.tsx)

# Take B has to exist already: this script measures the ritual and races it against the recording
# the tape made. Running them the other way round would compare today's ritual with a Chute take
# from another build.
CHUTE_JSON="$OUT/$SLUG.json"
[ -s "$CHUTE_JSON" ] || die "record the Chute side first:
    ./demo/gui/tapes/paste-a-whole-folder.sh
  It writes $CHUTE_JSON, which is the number this take is raced against."
CHUTE_SECS="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["measured"]["chute"])' "$CHUTE_JSON")"
[ -s "$OUT/$SLUG.mov" ] || die "the Chute take $OUT/$SLUG.mov is missing — re-run the tape"

preflight
scene
require_files "${RITUAL[@]}"
scratch_editor 1420 120 580 800

cat <<TXT

  ────────────────────────────────────────────────────────────────────────────
  THE RITUAL — six files, one at a time, the way it is done without Chute.

  For each of these, in order:

$(printf '      %s\n' "${RITUAL[@]}")

    1. find it in the Finder window on the left and double-click it
    2. ⌘A   select all
    3. ⌘C   copy
    4. ⌘W   close it
    5. click the TextEdit window on the right, ⌘V to paste
    6. type the file's name after the paste — the agent has to be told what it is
    7. Return

  DO IT AT YOUR NORMAL PACE. Not fast, not carefully — the pace you would use at
  4pm on a Thursday. The number this produces goes on the landing page.

  Nothing else may be on screen inside the recorded frame, and do not switch to
  another app: the take is ${WIN_W}x${WIN_H} at ${WIN_X},${WIN_Y} and records everything in it.

  ────────────────────────────────────────────────────────────────────────────

TXT

if [ "$PLAN" = "1" ]; then
  say "would count you in, record until you press Return, then build the race"
  say "would compare your seconds against the ledger's 150s for JTBD 2"
  exit 0
fi

printf '  Press Return to start the countdown. '
read -r _
for n in 3 2 1; do printf '  %s…\n' "$n"; perl -e 'select(undef,undef,undef,1)'; done

take_open "$SLUG-manual"
stopwatch_start
printf '\n  RECORDING. Press Return the instant the last paste lands.\n\n'
read -r _
MANUAL="$(stopwatch_read)"
take_close

# The floor is 20s, not the ledger's 150s: the point of measuring is that the ledger might be
# wrong. What a floor catches is a take that ended by accident — a stray Return, a fumbled start.
verify_take "$SLUG-manual" 20

say "the ritual took ${MANUAL}s by hand · Chute did the same job in ${CHUTE_SECS}s"
emit_timing  "$SLUG" "$MANUAL" "$CHUTE_SECS"
compose_race "$SLUG" "$MANUAL" "$CHUTE_SECS" 14

cat <<TXT

  Done. Now, in this order:

    1. WATCH IT BACK   open $OUT/$SLUG-race.mp4
    2. PUBLISH         make -C demo publish
    3. CHECK           cd site && npm run check:cases

  Step 3 compares ${MANUAL}s against what docs/03-JTBD-LEDGER.md claims for JTBD 2.
  If it fails, the stopwatch wins and the LEDGER is what changes — that is the whole
  reason this take is performed by a person.

TXT
