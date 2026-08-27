#!/usr/bin/env bash
# "Option-right-click, Copy as Pathname, fix the quoting, repeat. Thirty-two times a day."
# Case: stop-typing-file-paths (JTBD 1, 9.1 min/day) — the highest FREQUENCY job in the ledger.
#
# Frequency is the argument here, not size. The take is short on purpose: this is the one a
# viewer will recognise instantly and it does not need explaining.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SLUG="stop-typing-file-paths"
FILES=(src/auth/session.ts src/auth/token.ts src/api/client.ts src/api/routes.ts)

preflight
scene
require_files "${FILES[@]}"
select_files "${FILES[@]}"

take_start "$SLUG" 10
stopwatch_start

right_click_selection
menu_pick "Copy Full Paths"
await_inbox_drained
await_clipboard 'src/auth/session\.ts'
await_clipboard 'src/api/routes\.ts'
CHUTE_SECS="$(stopwatch_read)"
take_wait
verify_take "$SLUG" 10

emit_timing "$SLUG" - "$CHUTE_SECS"
export_web  "$SLUG"
verify_loop "$SLUG"
say "done — $OUT/$SLUG.mp4"
