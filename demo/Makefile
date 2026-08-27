# Regenerate every demo asset. `make` from this directory.
#
# Determinism is the whole point: the fixture is rebuilt from scratch before EVERY tape, so a
# re-record changes a GIF only when the product changed. Without that, each release produces
# forty diffs that mean nothing and the assets stop being reviewable.
#
# Requires: vhs ttyd ffmpeg cliclick  (brew install vhs ttyd ffmpeg cliclick)
#           and the JetBrains Mono font (brew install --cask font-jetbrains-mono)

REPO    := $(shell cd .. && pwd)
FIXTURE := $(CURDIR)/.fixture
TAPES   := $(wildcard tapes/*.tape)
GIFS    := $(patsubst tapes/%.tape,out/%.gif,$(TAPES))

export CHUTE_REPO    := $(REPO)
export CHUTE_FIXTURE := $(FIXTURE)

.PHONY: all demos clean check tools
all: demos

demos: tools $(GIFS)
	@echo
	@ls -la out/*.gif | awk '{printf "  %-28s %s\n", $$9, $$5}'
	@echo "  $(words $(GIFS)) demos regenerated"

# The binary under test is the RELEASE binary — a debug build is slower on screen and the demo
# is supposed to show real speed.
out/%.gif: tapes/%.tape common.tape setup.tape fixtures/make.sh
	@mkdir -p out
	@cd .. && swift build -c release >/dev/null
	@./fixtures/make.sh "$(FIXTURE)"
	@echo "→ $*"
	@vhs $< >/dev/null

# Colour comes from brand/tokens.json and nowhere else.
common.tape chute.theme.json: ../brand/tokens.json ../brand/gen-vhs-theme.mjs
	@node ../brand/gen-vhs-theme.mjs

tools:
	@for t in vhs ttyd ffmpeg; do \
	  command -v $$t >/dev/null || { echo "missing: $$t — brew install vhs ttyd ffmpeg"; exit 1; }; \
	done

# What "deterministic" honestly means here.
#
# The GIF is NOT byte-reproducible and cannot be: VHS records a real terminal, so frame timing
# jitters by milliseconds and the GIF palette/dither shifts with it. Measured: two identical runs
# gave the same 173 frames with 0.68% of pixels differing. Claiming byte-equality would be a
# check that fails for reasons nobody can fix, and a check like that gets deleted.
#
# What IS guaranteed, and what this verifies:
#   1. the FIXTURE is byte-identical every build, down to the git SHA — so recorded CONTENT
#      never drifts, which is the property that makes a re-record reviewable;
#   2. every tape produced a real GIF at the declared width;
#   3. two runs of the same tape agree on frame count and on >99% of the final frame — so a
#      change in what the product PRINTS still fails loudly.
check: tools
	@echo "1. fixture determinism"
	@./fixtures/make.sh .check/fx-a >/dev/null && ./fixtures/make.sh .check/fx-b >/dev/null
	@diff -r --exclude=.git .check/fx-a .check/fx-b >/dev/null \
	  && [ "$$(git -C .check/fx-a rev-parse HEAD)" = "$$(git -C .check/fx-b rev-parse HEAD)" ] \
	  && echo "   identical trees and identical commit $$(git -C .check/fx-a rev-parse --short HEAD)" \
	  || { echo "   FIXTURE DRIFTED — every demo would change for no reason"; exit 1; }
	@echo "2. every tape produced a GIF"
	@for t in $(TAPES); do g="out/$$(basename $$t .tape).gif"; \
	  [ -s "$$g" ] || { echo "   MISSING $$g"; exit 1; }; \
	  w=$$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$$g"); \
	  [ "$$w" = "1200" ] || { echo "   $$g is $${w}px wide, expected 1200"; exit 1; }; \
	done
	@echo "   $(words $(TAPES)) GIFs, all 1200px"
	@echo "3. re-recording bundle.gif reproduces the same output"
	@cp out/bundle.gif .check/first.gif
	@rm -f out/bundle.gif && $(MAKE) --no-print-directory out/bundle.gif >/dev/null 2>&1
	@a=$$(ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of csv=p=0 .check/first.gif); \
	 b=$$(ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of csv=p=0 out/bundle.gif); \
	 [ "$$a" = "$$b" ] || { echo "   frame count changed: $$a then $$b"; exit 1; }; \
	 ffmpeg -y -loglevel error -sseof -0.5 -i .check/first.gif -vframes 1 .check/a.png; \
	 ffmpeg -y -loglevel error -sseof -0.5 -i out/bundle.gif   -vframes 1 .check/b.png; \
	 d=$$(magick compare -metric AE .check/a.png .check/b.png null: 2>&1 | cut -d' ' -f1); \
	 total=$$(magick identify -format '%[fx:w*h]' .check/a.png); \
	 pct=$$(echo "$$d $$total" | awk '{printf "%.2f", 100*$$1/$$2}'); \
	 awk -v p="$$pct" 'BEGIN{exit !(p<1.0)}' \
	   && echo "   $$a frames both runs, final frame differs by $$pct% (encoder jitter, under the 1% bar)" \
	   || { echo "   final frame differs by $$pct% — the product's output changed"; exit 1; }
	@echo "demo pipeline: verified"

clean:
	rm -rf out .fixture .check
