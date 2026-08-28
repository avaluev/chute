#!/usr/bin/env bash
# "It gave me four files as one blob of markdown and now I'm copy-pasting each one."
# Case: turn-an-answer-back-into-files (JTBD 9, 28.5 min/day) — the second-largest saving.
#
# The whole point of this one is the PREVIEW. A right-click that silently writes into a repo is
# the thing that would destroy the trust the rest of the page is sold on, so the demo has to show
# the list arriving and a human agreeing to it. Film the confirmation, not just the result.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SLUG="turn-an-answer-back-into-files"

preflight
scene
require_files "src"

# The agent's answer, on the clipboard, exactly as it arrives from a chat window. This fixture is
# the reason demo/verify.sh exists: the first version of this demo used the wrong fence format and
# shipped to the live site showing "chute: no named code blocks found" twice.
osa "set the clipboard to (read POSIX file \"$REPO/demo/fixtures/answer.md\")"

take_start "$SLUG" 14
stopwatch_start

right_click_selection
menu_pick "Save Clipboard as Files…"
await_inbox_drained
# The preview names the files it WOULD write and nothing exists yet. Assert both, or a take that
# silently wrote them would pass every check and prove the opposite of the point.
CHUTE_SECS="$(stopwatch_read)"
take_wait
verify_take "$SLUG" 14

emit_timing "$SLUG" - "$CHUTE_SECS"
export_web  "$SLUG"
verify_loop "$SLUG"
say "done — $OUT/$SLUG.mp4"
