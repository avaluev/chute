#!/usr/bin/env bash
# THE FOCUS RATCHET — the app is the pitch; the CLI is a footnote, never the other way round.
#
# ── WHY THIS FILE EXISTS ────────────────────────────────────────────────────────────────────
#
# On 2026-09-08 the founder read README.md and the landing page and called it "bullshit
# information about the project" — both led with `brew install` and a wall of `chute <command>`
# rows before ever naming the Finder menu or the menu bar, which is the actual product. Nothing
# stopped that: check-claims.mjs verifies every claim is TRUE, but truth and EMPHASIS are
# different axes, and nothing in this repo measured emphasis. A page can be 100% accurate and
# still open with the free command line tool instead of the app it exists to sell.
#
# This is a ratchet in the shape of Scripts/check-untested-logic.sh, not a style opinion: a
# committed baseline, a file may improve (go down) freely, it may never regress (go up) without
# someone deliberately re-recording it — which is a visible line in a diff, not a thing nobody
# noticed.
#
# ── WHAT IT MEASURES ────────────────────────────────────────────────────────────────────────
#
# For README.md, site/src/app/page.tsx and every other top-level site/src/app/*/page.tsx, two
# numbers per file:
#
#   ABOVE  — CLI-shaped mentions (a `chute <command>` invocation, "brew install", the word "CLI",
#            "terminal command", "command line/-line") that occur on a line strictly BEFORE the
#            first line naming "Finder" or the "menu bar". If the file never names either surface,
#            every CLI mention in it counts — the worst case, on purpose.
#   RATIO  — CLI-shaped mentions as a percentage of app-surface mentions ("Finder" / "menu bar"),
#            both counted in the file's first $FOCUS_N lines (default 60) — a proxy for "what a
#            reader sees before scrolling". 0 CLI / some surface mentions = 0. Some CLI / 0
#            surface mentions = 999, a deliberate flag rather than a division by zero.
#
# Both numbers may fall freely. Neither may rise without --record, and --record is a decision
# someone makes on purpose, not a thing this script does for you.
#
#   ./Scripts/check-focus.sh            check against the baseline
#   ./Scripts/check-focus.sh --record   re-record it (do this ONLY when the numbers improved)
#
# ── WHAT THIS CANNOT CATCH — read this before trusting a green run ─────────────────────────
#
#   - SOURCE TEXT, not the rendered page. A .tsx file's JSX often renders in a different order
#     than it appears in the source (e.g. a `const FAQ = [...]` array defined near the top of
#     page.tsx renders inside a <Section> near the bottom of the actual page). This script has no
#     way to know that; it reads the file top to bottom exactly as `cat` would.
#   - CONTENT ASSEMBLED FROM IMPORTED DATA IS INVISIBLE. `<CopyLine text={CONFIG.brew} />` puts
#     "brew install …" on the rendered page; this script sees only the four words
#     `text={CONFIG.brew}` and counts nothing. Anything pulled in from lib/cases.ts,
#     lib/commands.json or a component this file imports is outside its reach.
#   - IT IS A WORD LIST, NOT A READER. "Command Line Tools" (Apple's Xcode toolchain, unrelated to
#     Chute) trips the same pattern as Chute's own CLI. A sentence arguing AGAINST leading with
#     the CLI still counts as a CLI-shaped mention — this script cannot tell a claim from a
#     rebuttal, the same limitation check-claims.mjs documents for itself.
#   - IT CANNOT SEE PROMINENCE. One CLI mention in an <h1> counts the same as one buried in a
#     code comment three hundred lines down.
#   - IT ONLY WALKS README.md and the top-level site/src/app/*/page.tsx files. Nested/dynamic
#     routes (cases/[slug]/page.tsx), shared components (Header, Footer, FAQ visuals) and
#     marketing/*.md are not swept.
#
# A green run means the measured proxy did not regress. It does not mean the page reads well —
# read it.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASELINE="$ROOT/Scripts/focus-baseline.txt"
FOCUS_N="${FOCUS_N:-60}"

CLI_CS='chute [a-z][a-z-]*'                                   # case-sensitive: real invocations
CLI_CI='\bCLI\b|brew install|terminal command|command[- ]line' # case-insensitive: prose signals
SURFACE='\bFinder\b|menu[- ]?bar'                              # case-insensitive either way

# Total occurrences (not lines) of the CLI-shaped patterns, in lines 1..$2 of file $1 (or the
# whole file when $2 is empty). `import` lines are dropped first: a TSX import such as
# `import { InstallCli } from "@/components/install-cli"` trips the \bCLI\b pattern on the
# hyphen in the path, and an import is never something a reader sees.
cli_count() {
  local f="$1" end="${2:-}" text
  if [ -z "$end" ]; then text="$(cat "$f")"; else text="$(sed -n "1,${end}p" "$f")"; fi
  text="$(printf '%s\n' "$text" | grep -v '^import ')"
  local a b
  a="$(printf '%s\n' "$text" | grep -oE "$CLI_CS" | wc -l | tr -d ' ')"
  b="$(printf '%s\n' "$text" | grep -oiE "$CLI_CI" | wc -l | tr -d ' ')"
  echo $((a + b))
}

surface_count() {
  local f="$1" end="${2:-}" text
  if [ -z "$end" ]; then text="$(cat "$f")"; else text="$(sed -n "1,${end}p" "$f")"; fi
  printf '%s\n' "$text" | grep -v '^import ' | grep -oiE "$SURFACE" | wc -l | tr -d ' '
}

first_surface_line() { grep -n -m1 -iE "$SURFACE" "$1" | cut -d: -f1; }

FILES=()
[ -f "$ROOT/README.md" ] && FILES+=("$ROOT/README.md")
for f in "$ROOT"/site/src/app/page.tsx "$ROOT"/site/src/app/*/page.tsx; do
  [ -f "$f" ] && FILES+=("$f")
done

measure() {
  for f in "${FILES[@]}"; do
    local total fsl above nEnd cliN surfN pct rel
    total="$(wc -l < "$f" | tr -d ' ')"
    fsl="$(first_surface_line "$f")"
    if [ -z "$fsl" ]; then
      above="$(cli_count "$f")"
    elif [ "$fsl" -le 1 ]; then
      above=0
    else
      above="$(cli_count "$f" $((fsl - 1)))"
    fi
    nEnd=$FOCUS_N; [ "$nEnd" -gt "$total" ] && nEnd=$total
    cliN="$(cli_count "$f" "$nEnd")"
    surfN="$(surface_count "$f" "$nEnd")"
    if [ "$surfN" -eq 0 ]; then
      [ "$cliN" -eq 0 ] && pct=0 || pct=999
    else
      pct=$(((cliN * 100) / surfN))
    fi
    rel="${f#"$ROOT/"}"
    printf '%d %d %s\n' "$above" "$pct" "$rel"
  done
}

if [ "${1:-}" = "--record" ]; then
  measure | sort -k3 > "$BASELINE"
  echo "recorded $(wc -l < "$BASELINE" | tr -d ' ') files"
  column -t "$BASELINE"
  exit 0
fi

[ -f "$BASELINE" ] || { echo "check-focus: no baseline — run with --record" >&2; exit 1; }
[ "${#FILES[@]}" -gt 0 ] || { echo "  FAIL nothing measured — is README.md at the repo root, and site/src/app where the baseline expects?"; exit 1; }

NOW="$(mktemp)"; measure | sort -k3 > "$NOW"; trap 'rm -f "$NOW"' EXIT

FAIL=0
while read -r was_above was_pct file; do
  [ -z "${file:-}" ] && continue
  line="$(awk -v f="$file" '$3 == f {print}' "$NOW")"
  if [ -z "$line" ]; then continue; fi   # deleted files are always fine
  now_above="$(awk '{print $1}' <<<"$line")"
  now_pct="$(awk '{print $2}' <<<"$line")"
  if [ "$now_above" -gt "$was_above" ]; then
    echo "  FAIL $file: $was_above -> $now_above CLI-shaped mention(s) above the first Finder/menu-bar mention"
    echo "       Move the app-surface framing earlier, or the CLI reference later — see the CLI section near the bottom."
    FAIL=$((FAIL + 1))
  fi
  if [ "$now_pct" -gt "$was_pct" ]; then
    echo "  FAIL $file: CLI:surface ratio in the first $FOCUS_N lines went $was_pct% -> $now_pct%"
    echo "       Either cut a CLI-shaped mention from the top of the file, or name Finder/the menu bar there too."
    FAIL=$((FAIL + 1))
  fi
done < "$BASELINE"

while read -r n_above n_pct file; do
  [ -z "${file:-}" ] && continue
  grep -q " $file\$" "$BASELINE" || {
    echo "  FAIL $file is new and unrecorded (above=$n_above, ratio=$n_pct%)"
    echo "       If this file's focus is deliberate, record it: ./Scripts/check-focus.sh --record"
    FAIL=$((FAIL + 1))
  }
done < "$NOW"

TOTAL_ABOVE="$(awk '{s+=$1} END {print s+0}' "$NOW")"
BASE_ABOVE="$(awk '{s+=$1} END {print s+0}' "$BASELINE")"
echo "focus: $TOTAL_ABOVE CLI-shaped mention(s) above the surfaces (baseline $BASE_ABOVE) across $(wc -l < "$NOW" | tr -d ' ') files"
[ "$FAIL" -eq 0 ] || echo "check-focus: $FAIL regression(s)"
[ "$FAIL" -eq 0 ]
