#!/usr/bin/env bash
# THE RATCHET — decision logic must not accumulate where no test can reach it.
#
# ── WHY THIS FILE EXISTS ────────────────────────────────────────────────────────────────────
#
# `chutetests` links ChuteCore only (Package.swift). Sources/ChuteApp and Sources/ChuteFinder have
# ZERO unit coverage — not low, zero — because XCTest ships with Xcode and this repo builds with
# the Command Line Tools. Two audits counted 154 untested decision points there and named
# `ChuteFinderSync.run` as the highest-value extraction. Both times it was ranked and deferred.
#
# On 2026-09-02 the founder selected 34 items in a Python project, chose Copy Folder Tree ▸ All
# Levels, and got thirteen .pyc files. The cause was ONE LINE in `ChuteFinderSync.targetFolder()`:
#
#     controller.selectedItemURLs()?.first ?? controller.targetedURL()
#
# It reads correctly. It is wrong for every multi-selection. 917 assertions and 144 end-to-end
# checks were green, and none of them could see that line, because it did not live anywhere a
# test could import.
#
# A finding that is written down and deferred is not a guard. This is the guard.
#
# ── WHAT IT DOES ────────────────────────────────────────────────────────────────────────────
#
# Counts decision points per file in the two untestable targets and compares them against a
# committed baseline. A file may go DOWN freely. It may never go UP, and a new file may not appear,
# without someone deliberately re-recording the baseline — which is a visible line in a diff rather
# than a thing nobody noticed.
#
# The fix for a red run is not to raise the number. It is to move the decision into ChuteCore as a
# pure function and test it, which is the move `StatusMenu`, `ActionRequest`, `OnboardingSteps`,
# `ConfirmPrompt` and now `FinderTarget` have all already made.
#
#   ./Scripts/check-untested-logic.sh            check against the baseline
#   ./Scripts/check-untested-logic.sh --record   re-record it (do this ONLY when lowering)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASELINE="$ROOT/Scripts/untested-logic.txt"

# Decision points, not lines: `if`, `guard`, `switch`, `case`, `for`, `while`, `&&`, `||`. Word
# boundaries so `iffy` and `forEach` do not count, and `//` comments are stripped first so a
# sentence about a guard is not a guard.
count_file() {
  sed 's://.*::' "$1" \
    | grep -oE '\b(if|guard|switch|case|for|while)\b|&&|\|\|' \
    | wc -l | tr -d ' '
}

measure() {
  for f in "$ROOT"/Sources/ChuteApp/*.swift "$ROOT"/Sources/ChuteFinder/*.swift; do
    [ -f "$f" ] || continue
    printf '%s %s\n' "$(count_file "$f")" "${f#"$ROOT/"}"
  done | sort -k2
}

if [ "${1:-}" = "--record" ]; then
  measure > "$BASELINE"
  echo "recorded $(wc -l < "$BASELINE" | tr -d ' ') files, $(awk '{s+=$1} END {print s}' "$BASELINE") decision points"
  exit 0
fi

[ -f "$BASELINE" ] || { echo "check-untested-logic: no baseline — run with --record" >&2; exit 1; }

FAIL=0
NOW="$(mktemp)"; measure > "$NOW"; trap 'rm -f "$NOW"' EXIT

while read -r was file; do
  now="$(awk -v f="$file" '$2 == f {print $1}' "$NOW")"
  if [ -z "$now" ]; then continue; fi          # deleted files are always fine
  if [ "$now" -gt "$was" ]; then
    echo "  FAIL $file: $was -> $now decision points in a target no test can import"
    echo "       Move the new branch into Sources/ChuteCore as a pure function and test it."
    FAIL=$((FAIL+1))
  fi
done < "$BASELINE"

while read -r n file; do
  grep -q " $file\$" "$BASELINE" || {
    echo "  FAIL $file is new, and it is in a target no test can import ($n decision points)"
    echo "       If it is only AppKit wiring, re-record. If it decides anything, ChuteCore."
    FAIL=$((FAIL+1))
  }
done < "$NOW"

TOTAL="$(awk '{s+=$1} END {print s}' "$NOW")"
BASE_TOTAL="$(awk '{s+=$1} END {print s}' "$BASELINE")"
echo "untested decision points: $TOTAL (baseline $BASE_TOTAL) across $(wc -l < "$NOW" | tr -d ' ') files"
[ "$FAIL" -eq 0 ] || echo "check-untested-logic: $FAIL file(s) grew"
[ "$FAIL" -eq 0 ]
