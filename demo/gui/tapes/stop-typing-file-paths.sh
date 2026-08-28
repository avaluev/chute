#!/usr/bin/env bash
# "Option-right-click, Copy as Pathname, fix the quoting, repeat. Thirty-two times a day."
# Case: stop-typing-file-paths (JTBD 1, 9.1 min/day) — the highest FREQUENCY job in the ledger.
#
# Frequency is the argument here, not size. The take is short on purpose: this is the one a
# viewer will recognise instantly and it does not need explaining.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SLUG="stop-typing-file-paths"
# ONE FOLDER, because Finder selects within one container. The first draft asked for two files
# from src/auth and two from src/api; Finder silently selected the two that shared a parent and
# the take filmed the wrong selection. select_files counts them now, so this fails loudly rather
# than recording a lie — but the tape still has to ask for something Finder can actually do.
#
# Two files, not four. The fixture has no folder with four in it, and giving it one would change
# every byte of the fixture and invalidate all thirteen terminal GIFs for a demo that is about
# FREQUENCY, not size. Thirty-two times a day is the argument; the count on the menu row is not.
# Paths are relative to the FIXTURE ROOT (select_files prefixes $FIXTURE), not to the
# folder `scene` opened. They must all live in that opened folder all the same.
FILES=(src/auth/session.ts src/auth/token.ts)

preflight
scene src/auth
require_files "${FILES[@]}"
select_files "${FILES[@]}"

take_start "$SLUG" 10
stopwatch_start

right_click_selection
menu_pick "Copy Full Paths"
await_inbox_drained
await_clipboard 'src/auth/session\.ts'
await_clipboard 'src/auth/token\.ts'
CHUTE_SECS="$(stopwatch_read)"
take_wait
verify_take "$SLUG" 10

emit_timing "$SLUG" - "$CHUTE_SECS"
export_web  "$SLUG"
verify_loop "$SLUG"
say "done — $OUT/$SLUG.mp4"
