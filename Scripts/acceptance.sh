#!/usr/bin/env bash
# EVERY MENU ITEM, AGAINST A HOSTILE TREE.
#
# Each of the nine Finder actions is a `chute` invocation — `chute finder-actions --json` prints
# the exact argv the extension sends. So this drives the real binary with the real templates, and
# fails if an action exists with no cases behind it. What it cannot reach is the click itself,
# which is `FinderTarget` in ChuteCore and covered by the unit suite.
#
#   ./Scripts/acceptance.sh            run everything
#   ./Scripts/acceptance.sh --perf     also print the timing table
#   ./Scripts/acceptance.sh --keep     leave the fixtures in place afterwards
#
# SAFE UNATTENDED. It never touches the real basket (CHUTE_BUFFER_DIR), never drives Finder
# (CHUTE_HEADLESS), restores the clipboard on exit, and writes only inside its own temp dir.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHUTE="$ROOT/.build/release/chute"
[ -x "$CHUTE" ] || { echo "build first: swift build -c release" >&2; exit 1; }

PERF=0; KEEP=0
for a in "$@"; do case "$a" in --perf) PERF=1;; --keep) KEEP=1;; esac; done

FIX=/tmp/chute-acceptance
export CHUTE_BUFFER_DIR="$(mktemp -d)/basket"
export CHUTE_HEADLESS=1                       # never reach for Finder; this may run with nobody there
SAVED="$(pbpaste 2>/dev/null)"
WORK="$(mktemp -d)"
cleanup() {
  printf %s "$SAVED" | pbcopy 2>/dev/null
  rm -rf "$WORK" "${CHUTE_BUFFER_DIR%/basket}"
  [ "$KEEP" = "1" ] || "$ROOT/Scripts/fixtures.sh" --clean "$FIX" >/dev/null 2>&1
}
trap cleanup EXIT

PASS=0; FAIL=0; SLOW=""
ok()   { PASS=$((PASS+1)); printf '  ok   %-9s %s\n' "$1" "$2"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %-9s %s\n     %s\n' "$1" "$2" "${3:-}"; }

# Runs a command, captures stdout+stderr and the exit code, and records how long it took.
OUT=""; RC=0; MS=0
run() {
  local t0 t1
  t0=$(python3 -c 'import time;print(int(time.time()*1000))')
  OUT="$("$@" 2>&1)"; RC=$?
  t1=$(python3 -c 'import time;print(int(time.time()*1000))')
  MS=$((t1-t0))
}
# id, description, then the assertion verb and its argument.
expect_ok()   { if [ "$RC" -eq 0 ]; then ok "$1" "$2"; else bad "$1" "$2" "exit $RC: $(printf '%s' "$OUT"|head -1)"; fi; }
expect_fail() { if [ "$RC" -ne 0 ]; then ok "$1" "$2"; else bad "$1" "$2" "exit 0 — a failure reported success"; fi; }
expect_has()  { if printf '%s' "$OUT" | grep -qF -- "$3"; then ok "$1" "$2"; else bad "$1" "$2" "missing '$3'"; fi; }
expect_not()  { if printf '%s' "$OUT" | grep -qF -- "$3"; then bad "$1" "$2" "should not contain '$3'"; else ok "$1" "$2"; fi; }
expect_under(){ if [ "$MS" -le "$3" ]; then ok "$1" "$2 (${MS}ms)"; else bad "$1" "$2" "${MS}ms, budget ${3}ms"; SLOW="$SLOW$1 ${MS}ms\n"; fi; }
timing()      { printf '%-10s %6sms  %s\n' "$1" "$MS" "$2" >> "$WORK/timings"; }

echo "building fixtures…"
"$ROOT/Scripts/fixtures.sh" "$FIX" >/dev/null || { echo "fixtures failed" >&2; exit 1; }
N="$FIX/names"; C="$FIX/content"; S="$FIX/structure"; L="$FIX/links"; R="$FIX/repo"; M="$FIX/permissions"

# ── the anti-drift gate ──────────────────────────────────────────────────────────────────────
# A new menu item with no cases behind it is the failure this whole file exists to prevent, so it
# is checked first and it is checked against the binary, not against a list in this script.
echo
echo "0. every action in the menu has cases here"
COVERED="copy-paths bundle-xml tree-2 tree-4 tree-all basket-add new-markdown new-markdown-clipboard paste-image"
LIVE="$("$CHUTE" finder-actions --json 2>/dev/null | python3 -c 'import json,sys; print(" ".join(a["id"] for a in json.load(sys.stdin)))')"
for id in $LIVE; do
  case " $COVERED " in *" $id "*) ok "COV-$id" "covered";;
    *) bad "COV-$id" "a menu action with no acceptance cases" "add cases, then add '$id' to COVERED";; esac
done
for id in $COVERED; do
  case " $LIVE " in *" $id "*) ;; *) bad "COV-$id" "cases exist for an action that is gone" "delete them";; esac
done

# ── 1. Copy Full Paths — `paths {files}` ─────────────────────────────────────────────────────
echo
echo "1. Copy Full Paths"
run "$CHUTE" paths "$R/src/a.ts" "$R/src/b.ts" --no-copy
expect_ok  "P-01" "two ordinary files"
expect_has "P-02" "prints absolute paths" "$R/src/a.ts"
run "$CHUTE" paths "$N/a file with spaces.txt" --no-copy
expect_has "P-03" "a space survives" "a file with spaces.txt"
run "$CHUTE" paths "$N/say \"hello\".txt" --no-copy
expect_has "P-04" "a double quote survives" 'say "hello".txt'
run "$CHUTE" paths "$N/two"$'\n'"lines.txt" --no-copy
expect_ok  "P-05" "a NEWLINE in a filename does not crash it"
run "$CHUTE" paths "$N/-rf.txt" --no-copy
expect_ok  "P-06" "a leading-dash name is not read as a flag"
run "$CHUTE" paths "$N/\$(whoami).txt" --no-copy
expect_not "P-07" "no command substitution" "$(whoami)@"
run "$CHUTE" paths "$N/🚀 rocket 🎉.txt" --no-copy
expect_has "P-08" "emoji survive" "rocket"
run "$CHUTE" paths --no-copy
# BY DESIGN, and my first expectation here was wrong: `paths` with no arguments means "this
# folder". From the MENU it can never happen — the extension refuses an empty selection — so the
# contract to pin is the CLI's, not an imagined one.
expect_ok  "P-09" "no arguments means the working directory"
expect_has "P-09b" "and it says which" "$(pwd)"
run "$CHUTE" paths "$FIX/does-not-exist.txt" --no-copy
expect_ok  "P-10" "a missing path is reported without crashing"
run "$CHUTE" paths "$R/src/a.ts" --format relative --no-copy
expect_not "P-11" "relative form drops the absolute prefix" "$FIX"
run "$CHUTE" paths "$S/many"/*.txt --no-copy
expect_under "P-12" "500 paths" 2000

# ── 2. Copy Files as Context — `bundle {files}` ──────────────────────────────────────────────
echo
echo "2. Copy Files as Context"
run "$CHUTE" bundle "$R/src" --no-copy
expect_has "B-01" "a folder expands to its files" 'export const a = 1'
expect_has "B-02" "each file is tagged with its path" '<file path='
run "$CHUTE" bundle "$R" --no-copy
expect_not "B-03" "node_modules is excluded" "left-pad"
expect_not "B-04" "__pycache__ is excluded" "cpython"
expect_not "B-05" ".git is excluded" "deadbeef"
run "$CHUTE" bundle "$C/binary.bin" --no-copy
expect_fail "B-06" "a binary-only selection fails rather than emitting rubbish"
run "$CHUTE" bundle "$C/xml-escape-hatch.txt" --no-copy
expect_has "B-07" "a literal </file> in content is neutralised" '<\/file>'
run "$CHUTE" bundle "$C/zero-byte.txt" --no-copy
expect_ok  "B-08" "a zero-byte file is not an error"
# Invalid UTF-8 alone is correctly refused; the contract worth pinning is that it does not take
# the READABLE files down with it, and that the skip is reported rather than silent.
run "$CHUTE" bundle "$R/src/a.ts" "$C/bad-utf8.txt" --no-copy
expect_ok  "B-09" "a bad-UTF-8 file does not sink the readable ones"
expect_has "B-09b" "the good file is still bundled" "export const a = 1"
run "$CHUTE" bundle "$C/bad-utf8.txt" --no-copy
expect_fail "B-09c" "and alone it is refused rather than emitting mojibake"
run "$CHUTE" bundle "$M/unreadable-file.txt" --no-copy
expect_fail "B-10" "an unreadable file is reported, not counted as empty"
run "$CHUTE" bundle "$N/say \"hello\".txt" --no-copy
expect_has "B-11" "a quote in a path is escaped in the XML attribute" '&quot;'
run "$CHUTE" bundle "$S/empty-dir" --no-copy
expect_fail "B-12" "an empty folder says so instead of copying nothing"
run "$CHUTE" bundle --no-copy "$C/ten-megabytes.txt"
expect_under "B-13" "10 MB single file" 3000
run "$CHUTE" bundle "$S/many" --no-copy
expect_under "B-14" "500 files" 5000
run "$CHUTE" bundle "$L" --no-copy
expect_ok  "B-15" "a symlink loop does not hang the bundler"

# ── 3-5. Copy Folder Tree — `tree {dir} --depth N` ───────────────────────────────────────────
echo
echo "3. Copy Folder Tree (2 / 4 / All Levels)"
run "$CHUTE" tree "$R" --depth 2 --no-copy
expect_has "T-01" "the root names itself" "repo/"
expect_not "T-02" "junk folders are left out" "node_modules"
expect_has "T-03" ".github is kept — CI is part of a repo's shape" ".github"
run "$CHUTE" tree "$S/deep" --depth 2 --no-copy
expect_not "T-04" "2 Levels stops at two" "level3"
run "$CHUTE" tree "$S/deep" --depth 4 --no-copy
expect_has "T-05" "4 Levels reaches level 4" "level4"
expect_not "T-06" "and stops there" "level5"
run "$CHUTE" tree "$S/deep" --depth 99 --no-copy
expect_has "T-07" "All Levels reaches the bottom" "at-the-bottom.txt"
run "$CHUTE" tree "$L" --depth 99 --no-copy
expect_under "T-08" "a symlink LOOP terminates (hung forever before 2026-09-02)" 5000
expect_has "T-09" "the loop is named, not followed" "loop -> .."
expect_not "T-10" "and the tree never leaves the folder" "root:"
run "$CHUTE" tree "$S/empty-dir" --depth 99 --no-copy
expect_ok  "T-11" "an empty folder renders as just itself"
run "$CHUTE" tree "$C/zero-byte.txt" --depth 2 --no-copy
expect_fail "T-12" "a FILE is refused — a tree of a file is nonsense"
run "$CHUTE" tree "$FIX/nope" --depth 2 --no-copy
expect_fail "T-13" "a missing folder is refused"
run "$CHUTE" tree "$M" --depth 99 --no-copy
expect_ok  "T-14" "an unreadable subdirectory does not abort the walk"
run "$CHUTE" tree "$S/many" --depth 99 --no-copy
expect_under "T-15" "500 entries" 2000

# ── 6. Add to Context Basket — `basket add {files}` ──────────────────────────────────────────
echo
echo "4. Add to Context Basket"
"$CHUTE" basket clear >/dev/null 2>&1
run "$CHUTE" basket add "$R/src/a.ts" "$R/src/b.ts"
expect_ok  "K-01" "two files go in"
run "$CHUTE" basket list
expect_has "K-02" "and are listed back" "a.ts"
run "$CHUTE" basket add "$R/src/a.ts"
expect_not "K-03" "a duplicate does not claim to have added one" "added 1"
run "$CHUTE" basket add "$FIX/not-here.ts"
expect_fail "K-04" "adding a file that does not exist fails"
expect_has "K-04b" "and names the real cause, not a permissions guess" "no such file"
run "$CHUTE" basket add "$R/src/a.ts" "$FIX/not-here.ts"
expect_has "K-04c" "a partial failure names what did not go in" "not added"
run "$CHUTE" basket add "$N/two"$'\n'"lines.txt"
expect_ok  "K-05" "a newline in a filename does not corrupt the store"
run "$CHUTE" basket copy --format context --no-copy
expect_has "K-06" "copy as context yields the file contents" "export const a = 1"
"$CHUTE" basket clear >/dev/null 2>&1
run "$CHUTE" basket list
expect_has "K-07" "clear empties it" "empty"
run "$CHUTE" basket copy --no-copy
expect_fail "K-08" "copying an empty basket is refused, not silently blank"
# State transition: a file that vanishes between add and copy must be named, never invented.
cp "$R/src/a.ts" "$WORK/vanishes.ts"
"$CHUTE" basket add "$WORK/vanishes.ts" >/dev/null 2>&1; rm -f "$WORK/vanishes.ts"
run "$CHUTE" basket list
expect_has "K-09" "a file deleted after adding is marked missing" "missing"
run "$CHUTE" basket copy --format context --no-copy
expect_fail "K-09b" "and copying a basket whose files are all gone is refused, not an empty blob"
"$CHUTE" basket clear >/dev/null 2>&1

# ── 7-8. New File — `new … --dir {dir}` ──────────────────────────────────────────────────────
echo
echo "5. New File (Empty Markdown / from Clipboard)"
mkdir -p "$WORK/new"
run "$CHUTE" new --blank --dir "$WORK/new"
expect_ok  "N-01" "an empty markdown file is created"
run "$CHUTE" new --blank --dir "$WORK/new"
expect_ok  "N-02" "a second one does not overwrite the first"
[ "$(find "$WORK/new" -name '*.md' | wc -l | tr -d ' ')" -ge 2 ] \
  && ok "N-03" "two distinct files exist" || bad "N-03" "two distinct files exist" "the second replaced the first"
run "$CHUTE" new --blank --dir "$FIX/nope"
expect_fail "N-04" "a missing target folder is refused"
run "$CHUTE" new --blank --dir "$M/unreadable-dir"
expect_fail "N-05" "an unwritable folder is refused, not reported as created"
printf '# Hello World\n\nbody\n' | pbcopy
run "$CHUTE" new --naming underscore --ext md --dir "$WORK/new"
expect_ok  "N-06" "a file is made from the clipboard"
expect_has "N-07" "and named from its heading" "Hello"
printf '' | pbcopy
run "$CHUTE" new --naming underscore --ext md --dir "$WORK/new"
expect_fail "N-08" "an empty clipboard is refused rather than making an empty file"

# ── 9. Image from Clipboard — `paste-image --dir {dir}` ──────────────────────────────────────
echo
echo "6. Image from Clipboard"
printf 'not an image' | pbcopy
run "$CHUTE" paste-image --dir "$WORK/new"
expect_fail "I-01" "text on the clipboard is refused with a reason"
run "$CHUTE" paste-image --dir "$FIX/nope"
expect_fail "I-02" "a missing folder is refused"

# ── summary ──────────────────────────────────────────────────────────────────────────────────
if [ "$PERF" = "1" ] && [ -f "$WORK/timings" ]; then
  echo; echo "timings"; cat "$WORK/timings"
fi
echo
[ -n "$SLOW" ] && { echo "over budget:"; printf "$SLOW"; }
echo "acceptance: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
