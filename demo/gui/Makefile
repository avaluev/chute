# The GUI half of demos-as-code. VHS owns the terminal (see ../Makefile); this owns the Finder
# right-click, the menu bar and the ⌥⌘N popup — the shots that sell the app rather than the CLI.
#
#   make check    lint + selftest + plan — everything provable without a screen  (safe anywhere)
#   make selftest the compose/export/verify pipeline, on synthetic takes
#   make plan     resolve every tape, prove the fixture matches, record nothing
#   make lint     a tape may only speak in verbs
#   make all      record everything                    (NEEDS A HUMAN AND THE REAL SCREEN)
TAPES := $(wildcard tapes/*.sh)
OUT   := ../out/gui

.PHONY: check selftest plan lint all clean

# Everything that does not need a screen. Run this before asking anyone to sit down and record.
check: lint selftest plan

# The half of this that ffmpeg and PIL can prove on their own. It exists because burn_clock was
# written against a filter this ffmpeg does not have, and verify_take's blank-frame guard read an
# empty measurement and would have deleted every recording the moment it was made.
selftest:
	@./selftest.sh
plan: lint
	@for t in $(TAPES); do echo "→ $$t"; PLAN=1 ./$$t | sed 's/^/  /'; done

# THE INVARIANT THIS ENFORCES. PLAN mode is implemented in lib.sh's verbs, so a tape that reaches
# past them for raw osascript, cliclick or sleep is not covered by it — and a dry run of such a
# tape drives the real cursor. That happened once, within ten minutes of the mode existing. Use
# osa / key / pause instead; they are the same thing with the guard attached.
lint:
	@fail=0; for t in $(TAPES); do \
	  if sed 's/#.*//' $$t | grep -nE '\b(osascript|cliclick|sleep|screencapture|open|killall)\b' >/dev/null; then \
	    echo "  FAIL $$t reaches past the verbs:"; \
	    sed 's/#.*//' $$t | grep -nE '\b(osascript|cliclick|sleep|screencapture|open|killall)\b' | sed 's/^/       /'; \
	    echo "       use osa / key / pause / take_start — they carry the PLAN guard"; \
	    fail=1; \
	  fi; \
	done; \
	[ $$fail = 0 ] && echo "  ok   every tape speaks only in verbs"
	@# A TAPE FOR A CASE THAT NO LONGER EXISTS. `lint` proved a tape's GRAMMAR and `plan` proved
	@# its fixture, so both stayed green on 2026-08-31 while three tapes went on planning
	@# recordings of Finder rows that had been deleted that morning. Shape, not substance — the
	@# same gap this repo has now paid for three times. A tape is named after its case; if
	@# cases.ts no longer has that slug, the tape records something the product cannot do.
	@# Read the tape's OWN declared SLUG, not its filename: paste-a-whole-folder.sh has always
	@# declared paste-a-whole-folder-into-your-agent, and a filename-based check called the
	@# highest-value tape in the product an orphan on its first run.
	@fail=0; for t in $(TAPES); do \
	  slug=$$(sed -n 's/^SLUG="\(.*\)"/\1/p' $$t | head -1); \
	  [ -n "$$slug" ] || { echo "  FAIL $$t declares no SLUG="; fail=1; continue; }; \
	  grep -q "\"$$slug\"" ../../site/src/lib/cases.ts || { \
	    echo "  FAIL $$t records '$$slug', which is no longer a case"; \
	    echo "       the case was retired — delete the tape, or restore the case"; fail=1; }; \
	done; \
	[ $$fail = 0 ] && echo "  ok   every tape still has a case behind it"

all: lint
	@for t in $(TAPES); do echo "→ $$t"; ./$$t; done
	@ls -la $(OUT)/*.mov 2>/dev/null | awk '{printf "  %-52s %sKB\n", $$9, int($$5/1024)}'

clean:
	rm -rf $(OUT)
