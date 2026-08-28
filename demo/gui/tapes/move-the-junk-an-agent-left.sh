#!/usr/bin/env bash
# "temp_, scratch_, three .log files, and I no longer know which of them matters."
# Case: move-the-junk-an-agent-left (JTBD 13, 6.6 min/day) — site/src/lib/cases.ts:144-150,
# confirmed against docs/03-JTBD-LEDGER.md:29 (same manual/chute seconds in both places).
#
# THE FIXTURE HAS NO JUNK IN IT. demo/fixtures/make.sh (which this tape must not touch — it is
# not in this tape's owned files, and every other demo needs it clean) builds a tidy little
# project with nothing an agent would have left behind. Right for every other demo; wrong for
# this one, whose entire premise IS a folder with junk in it. So this tape drops five files into
# $FIXTURE/src itself, right after `scene` rebuilds the fixture: one temp_ prefix, one scratch_
# prefix, three .log extensions — the exact three categories Sources/ChuteCore/Junk.swift checks
# (scratchPatterns, scratchExtensions) and the exact wording of the pain quote above, so the take
# shows the real "clean-junk" candidate list, not an empty "nothing to clean". Plain `printf`, not
# a lib.sh verb: this is filesystem setup, the same class of thing `scene` already does via
# fixtures/make.sh, not screen automation — `make lint` bans osascript/cliclick/sleep/
# screencapture/open/killall in a tape, not touch or printf.
#
# THE TAKE STOPS AT THE PREVIEW, same choice turn-an-answer-back-into-files.sh already made for
# its own destructive confirm. "Move Junk to Trash" has a confirmButton in FinderActions.swift, so
# picking it runs a dry run and the app shows an alert listing what it WOULD move before anything
# happens — and that list is the fix this case actually sells ("you see the list first ... never
# rm"). Clicking the alert's "Move to Trash" needs a Tab-then-Space past its Cancel-is-default
# focus (no keyboard shortcut is wired to it, on purpose, so a stray Return cannot write), and
# that click would only prove something the alert on camera already proves. So the junk is never
# actually sent to Trash by this tape — the list appearing is the shot.
#
# TIMED. Unlike the menu-bar heroes, this is one discrete user action with a real observable
# effect (the request inbox draining), not a dwell a viewer has to read — so it gets the same
# stopwatch_read/emit_timing treatment as every other Finder short, gated on await_inbox_drained
# exactly the way turn-an-answer-back-into-files.sh gates its own preview-only confirm.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SLUG="move-the-junk-an-agent-left"

preflight
scene
mkdir -p "$FIXTURE/src"
printf 'placeholder\n' > "$FIXTURE/src/temp_output.txt"
printf '# scratch\n'   > "$FIXTURE/src/scratch_notes.md"
printf 'debug\n'       > "$FIXTURE/src/debug.log"
printf 'error\n'       > "$FIXTURE/src/error.log"
printf 'build\n'       > "$FIXTURE/src/build.log"
require_files src/temp_output.txt src/scratch_notes.md src/debug.log src/error.log src/build.log

take_start "$SLUG" 14
stopwatch_start

right_click_selection
menu_pick "Move Junk to Trash"
await_inbox_drained
CHUTE_SECS="$(stopwatch_read)"
take_wait
verify_take "$SLUG" 14

emit_timing "$SLUG" - "$CHUTE_SECS"
export_web  "$SLUG"
verify_loop "$SLUG"
say "done — $OUT/$SLUG.mp4"
say "NOTE: this tape leaves the confirm alert showing and the junk files in place — press Cancel and re-run scene before the next take."
