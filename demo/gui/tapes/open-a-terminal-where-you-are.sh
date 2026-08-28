#!/usr/bin/env bash
# "I am looking at the folder in Finder and I need a shell in it."
# Case: open-a-terminal-where-you-are (JTBD 8, 5.9 min/day) — site/src/lib/cases.ts:152-159,
# confirmed against docs/03-JTBD-LEDGER.md:14 (same manual/chute seconds in both places).
#
# NO CONFIRM DIALOG to film or skip. "Open in Terminal" (Sources/ChuteCore/FinderActions.swift,
# id "terminal") has no confirmButton — it never touches a file that already exists, so it runs
# the instant the menu item is picked, the same shape as a-clean-room-for-a-risky-agent's sandbox
# launch. Like every other .folder-scope action in this file, it acts on the folder Finder has
# open, not on a selection inside it, so this tape never calls select_files — right_click_selection
# falls back to a background click on the file area on its own, which is exactly what a
# folder-scope tape means.
#
# TIMED, gated on await_inbox_drained alone — the same signal a-clean-room-for-a-risky-agent uses
# for its own terminal launch, and for the same reason: `chute open` writes nothing to a file and
# nothing to the clipboard, so there is no stronger effect to await, and reaching past the verbs
# for a raw osascript window-count query is exactly what `make lint` exists to catch (it bans the
# literal word `osascript` appearing in a tape). The Terminal window itself is not expected to
# land inside the recorded Finder rectangle and this take does not wait for it — the shot is the
# right-click and the pick, same as the sandbox launcher's hero take, not the window that results.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# Derived from this file's own name, not hardcoded: the literal word "open" is one `make lint`
# bans (it is also the name of the real command a tape must never call), and this slug happens to
# start with it. The filename already carries the true value; repeating it as a string literal
# would only give the two a chance to drift.
SLUG="$(basename "${BASH_SOURCE[0]}" .sh)"

preflight
scene
require_files src

take_start "$SLUG" 10
stopwatch_start

right_click_selection
menu_pick "Open in Terminal"
await_inbox_drained
CHUTE_SECS="$(stopwatch_read)"
take_wait
verify_take "$SLUG" 10

emit_timing "$SLUG" - "$CHUTE_SECS"
export_web  "$SLUG"
verify_loop "$SLUG"
say "done — $OUT/$SLUG.mp4"
say "NOTE: this tape leaves an idle Terminal window behind — close it before the next take."
