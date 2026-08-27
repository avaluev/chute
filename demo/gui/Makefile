# The GUI half of demos-as-code. VHS owns the terminal (see ../Makefile); this owns the Finder
# right-click, the menu bar and the ⌥⌘N popup — the shots that sell the app rather than the CLI.
#
#   make plan     resolve every tape, prove the fixture matches, record nothing   (safe anywhere)
#   make lint     a tape may only speak in verbs
#   make all      record everything                    (NEEDS A HUMAN AND THE REAL SCREEN)
TAPES := $(wildcard tapes/*.sh)
OUT   := ../out/gui

.PHONY: plan lint all clean
plan: lint
	@for t in $(TAPES); do echo "→ $$t"; PLAN=1 ./$$t | sed 's/^/  /'; done

# THE INVARIANT THIS ENFORCES. PLAN mode is implemented in lib.sh's verbs, so a tape that reaches
# past them for raw osascript, cliclick or sleep is not covered by it — and a dry run of such a
# tape drives the real cursor. That happened once, within ten minutes of the mode existing. Use
# osa / key / pause instead; they are the same thing with the guard attached.
lint:
	@fail=0; for t in $(TAPES); do \
	  if sed 's/#.*//' $$t | grep -nE '\b(osascript|cliclick|sleep|screencapture)\b' >/dev/null; then \
	    echo "  FAIL $$t reaches past the verbs:"; \
	    sed 's/#.*//' $$t | grep -nE '\b(osascript|cliclick|sleep|screencapture)\b' | sed 's/^/       /'; \
	    echo "       use osa / key / pause / take_start — they carry the PLAN guard"; \
	    fail=1; \
	  fi; \
	done; \
	[ $$fail = 0 ] && echo "  ok   every tape speaks only in verbs"

all: lint
	@for t in $(TAPES); do echo "→ $$t"; ./$$t; done
	@ls -la $(OUT)/*.mov 2>/dev/null | awk '{printf "  %-52s %sKB\n", $$9, int($$5/1024)}'

clean:
	rm -rf $(OUT)
