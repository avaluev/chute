#!/usr/bin/env bash
# Do the demos actually SHOW THE PRODUCT WORKING?
#
# THE BUG THIS EXISTS FOR. unpack.gif shipped to the live site showing the command failing twice —
# "chute: no named code blocks found" — under the caption "a markdown answer becomes a real file
# tree". The fixture used the wrong code-fence format. Every existing check passed: the GIF was
# 1200px, had 173 frames, was not blank, and was byte-stable across runs. Not one of them asked
# whether the command SUCCEEDED.
#
# A demo of the product failing is worse than no demo. So before any recording, every command a
# tape will run is executed for real against a fresh fixture and must exit 0 and print no error.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
CHUTE="$REPO/.build/release/chute"
FIX="$HERE/.verify"

[ -x "$CHUTE" ] || { echo "verify: build first — swift build -c release" >&2; exit 1; }

PASS=0; FAIL=0
ok()  { printf "  ok   %s\n" "$1"; PASS=$((PASS+1)); }
bad() { printf "  FAIL %s\n       %s\n" "$1" "$2"; FAIL=$((FAIL+1)); }

# Runs a command in a fresh fixture and fails on a non-zero exit OR on chute's error prefix.
# The prefix matters: several commands report a refusal on stderr and still exit 0, and a demo
# that films a refusal is exactly the thing this script exists to catch.
demo() { # label command...
  local label="$1"; shift
  rm -rf "$FIX"; "$HERE/fixtures/make.sh" "$FIX" >/dev/null
  local out code
  # errexit OFF around the call, deliberately. With it on, a failing command substitution in an
  # assignment kills the whole script — so the FIRST broken demo aborted the run with no output
  # at all and read as "nothing to report". Silence is not a pass.
  set +e
  out="$(cd "$FIX" && "$@" 2>&1)"; code=$?
  set -e
  if [ "$code" -ne 0 ]; then bad "$label" "exit $code: $(printf '%s' "$out" | head -1)"; return; fi
  if printf '%s' "$out" | grep -q "^chute: "; then
    bad "$label" "$(printf '%s' "$out" | grep '^chute: ' | head -1)"; return
  fi
  ok "$label"
}

clip() { pbcopy < "$1"; }

echo "Verifying every demo shows the product WORKING"

demo "paths"       "$CHUTE" paths src/auth/session.ts --no-copy
demo "bundle"      "$CHUTE" bundle src/auth src/api --no-copy
demo "tokens"      "$CHUTE" tokens src --no-copy
demo "tree"        "$CHUTE" tree --depth 3 --no-copy
demo "seed"        "$CHUTE" seed
demo "checkpoint"  "$CHUTE" checkpoint .
demo "doctor"      "$CHUTE" doctor
demo "redact"      "$CHUTE" redact "$HERE/fixtures/leaky.env.txt" --no-copy
demo "sessions"    "$CHUTE" sessions
demo "ports"       "$CHUTE" ports

# Clipboard-driven demos: the fixture on the pasteboard is half the test. This is precisely the
# pair that broke — the command was fine, the fixture was not.
clip "$HERE/fixtures/answer.md"
demo "unpack (preview)" "$CHUTE" unpack
clip "$HERE/fixtures/answer.md"
demo "unpack --force"   "$CHUTE" unpack --force
clip "$HERE/fixtures/answer.md"
demo "new"              "$CHUTE" new --no-rename

rm -rf "$FIX"
echo
echo "demos: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
