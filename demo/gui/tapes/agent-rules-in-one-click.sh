#!/usr/bin/env bash
# "Every new repo starts with me pasting the same CLAUDE.md I wrote three months ago."
# Case: agent-rules-in-one-click (JTBD 7, 9.9 min/day).
#
# One of the four that only became a Finder action on 2026-08-28. It lives under "Set Up for an
# Agent" rather than inline, because the ledger says a job under ~10 min/day may sit one level
# down — so this tape has to open a submenu, which is a hover the demo must give time to.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SLUG="agent-rules-in-one-click"

preflight
scene
require_files "src"

take_start "$SLUG" 12
stopwatch_start

right_click_selection
menu_pick_sub "Set Up for an Agent" "Add Agent Rules"
await_inbox_drained
await_file "$FIXTURE/src/CLAUDE.md" 8
CHUTE_SECS="$(stopwatch_read)"
take_wait
verify_take "$SLUG" 12

emit_timing "$SLUG" - "$CHUTE_SECS"
export_web  "$SLUG"
verify_loop "$SLUG"
say "done — $OUT/$SLUG.mp4"
