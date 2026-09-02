#!/usr/bin/env bash
# THE PLAUSIBILITY GATE — the first check in this repo that tests a MAGNITUDE.
#
# ── WHY THIS FILE EXISTS ────────────────────────────────────────────────────────────────────
#
# Three separate wrong numbers shipped in the menu bar, and every gate stayed green through all
# of them:
#
#   · CPU came from `ps -o pcpu`, a LIFETIME AVERAGE. It read Google Chrome at 21.4% while a real
#     one-second measurement put it at 0.5%. Forty-fold.
#   · Memory was summed `rss`, which counts every shared page once per process. A session is a
#     tree of twenty-four, so the figure ran ×1.78 to ×1.93 high.
#   · CPU again, after the first fix: mach ticks read as nanoseconds. On Intel the timebase is
#     1/1 so the naive reading is correct, which is why it survives review on the machine most
#     people write it on. Here it under-reported by 24×.
#
# `Scripts/smoke.sh` asserted that the keys `cpuPercent` and `memoryBytes` EXIST. They always did.
# Every gate in this repo checks shape, so a number could be off by 24× and stay green forever.
#
# Everything below checks a number against something physical — the RAM in the machine, the cores
# in the machine, a load of known size, an allocation of known size. A shape cannot satisfy them.
#
# ── HOW TO READ A FAILURE ───────────────────────────────────────────────────────────────────
#
# Each check names the specific bug it would have caught. A red line here is not "a test broke";
# it is "the menu is about to lie about this, in this direction, by roughly this much".
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHUTE="$ROOT/.build/release/chute"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n     %s\n' "$1" "${2:-}"; }

[ -x "$CHUTE" ] || { echo "build first: swift build -c release"; exit 1; }

MEMSIZE=$(sysctl -n hw.memsize)
CORES=$(sysctl -n hw.logicalcpu)
MAXCPU=$((CORES * 100))
printf 'this machine: %s GB of RAM, %s logical cores (ceiling %s%%)\n\n' \
  "$((MEMSIZE / 1073741824))" "$CORES" "$MAXCPU"

JSON="$("$CHUTE" sessions --json 2>/dev/null)"
if [ -z "$JSON" ] || [ "$JSON" = "[]" ]; then
  # Not a pass. A gate that reports success over zero items is exactly the false green this file
  # was written to stop — say the denominator out loud and refuse to score it.
  echo "  SKIP no terminal sessions are open — nothing to check against."
  echo "       Open a terminal and re-run; this gate is meaningless over 0 sessions."
  exit 2   # not 0 — smoke.sh reads 2 as "skipped" and anything else as a verdict
fi
COUNT=$(printf '%s' "$JSON" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')
echo "1. every session's figures are physically possible ($COUNT sessions)"

# ── MEMORY: THE DOUBLE-COUNTING CHECK ───────────────────────────────────────────────────────
# Summed rss across a tree exceeds real usage without limit, and on a busy machine it sails past
# the RAM that physically exists. phys_footprint cannot: it is what the kernel says is resident.
OUT=$(printf '%s' "$JSON" | MEMSIZE="$MEMSIZE" python3 -c '
import json, os, sys
d = json.load(sys.stdin)
cap = int(os.environ["MEMSIZE"])
total = sum(r.get("memoryBytes", 0) for r in d)
print(f"{total} {cap} {total / cap:.2f}")
')
read -r TOTAL CAP RATIO <<< "$OUT"
if [ "$TOTAL" -le "$CAP" ]; then
  ok "all sessions together hold $((TOTAL / 1073741824)) GB of $((CAP / 1073741824)) GB — ratio $RATIO"
else
  bad "memory exceeds the RAM in the machine" \
      "$((TOTAL / 1073741824)) GB claimed against $((CAP / 1073741824)) GB physical (ratio $RATIO) — shared pages are being counted once per process"
fi

# ── CPU: THE UNIT-FACTOR CEILING ────────────────────────────────────────────────────────────
# 100% is one core. A session cannot use more cores than the machine has, so a reading above the
# ceiling means the number is not in the units it claims.
WORST=$(printf '%s' "$JSON" | python3 -c '
import json, sys
d = json.load(sys.stdin)
print(max((r.get("cpuPercent", 0) for r in d), default=0))
')
# Through the ENVIRONMENT, not spliced into the source. Both values are floats printed by
# max() today, so nothing can escape the quotes — but the same script already does this the
# right way for MEMSIZE above, and two patterns for one job is how the wrong one survives.
if WORST="$WORST" MAXCPU="$MAXCPU" python3 -c 'import os, sys; sys.exit(0 if float(os.environ["WORST"]) <= float(os.environ["MAXCPU"]) else 1)'; then
  ok "the busiest session reads $(printf '%.1f' "$WORST")%, within the $MAXCPU% this machine can produce"
else
  bad "a session claims more CPU than the machine has" \
      "$WORST% against a ceiling of $MAXCPU% — the figure is not percent-of-one-core"
fi

# ── THE TWO CALIBRATED LOADS ────────────────────────────────────────────────────────────────
# The checks above bound the numbers. These two pin them: a known load and a known allocation,
# measured through the same code path the menu uses. A wrong unit factor cannot survive either.
echo
echo "2. a known one-core load reads as one core"

# MEASURED AS A DELTA, not as an absolute. The first version read "the busiest session" while the
# load ran — which is the busiest session's WHOLE tree, agents and compilers included, not the
# load. It read 121% for one pinned core on a machine that was working, and it went red when two
# other jobs were competing for the same core. A gate that cries wolf gets ignored, which is worse
# than no gate at all. Before-and-after on the session that hosts the burn isolates the one core
# we started from everything else the machine is doing.
per_tty_cpu() {
  "$CHUTE" sessions --json 2>/dev/null | python3 -c '
import json, sys
for r in json.load(sys.stdin):
    print(r.get("tty", "?"), r.get("cpuPercent", 0))
'
}
cpu_delta() {
  python3 -c '
import sys
def load(p):
    d = {}
    for line in open(p):
        parts = line.split()
        if len(parts) == 2: d[parts[0]] = float(parts[1])
    return d
a, b = load(sys.argv[1]), load(sys.argv[2])
print(f"{max((b[k] - a.get(k, 0.0) for k in b), default=0.0):.1f}")
' "$1" "$2"
}

# BEST OF THREE. A busy-loop that loses its core to something else under-reports, and that is a
# fact about the machine rather than about the code — so a contended attempt is not evidence.
# The best attempt is the one where the loop actually got a core, which is the reading we mean.
# No attempt can over-report, so taking the maximum cannot hide the bug this is here to catch.
READING=0
for _ in 1 2 3; do
  B=$(mktemp); per_tty_cpu > "$B"
  python3 -c '
import time
end = time.time() + 2.5
while time.time() < end: pass
' &
  BURN=$!
  sleep 1.2
  A=$(mktemp); per_tty_cpu > "$A"
  wait $BURN 2>/dev/null
  THIS=$(cpu_delta "$B" "$A"); rm -f "$B" "$A"
  READING=$(A="$READING" B="$THIS" python3 -c 'import os; print(max(float(os.environ["A"]), float(os.environ["B"])))')
  # Stop as soon as one attempt lands — the rest would only cost time.
  R="$READING" python3 -c 'import os, sys; v = float(os.environ["R"]); sys.exit(0 if 80 <= v <= 130 else 1)' && break
done

# 80-130 is deliberately loose: the sampling window is not exactly the burn window. The bug this
# catches was 24x, and 24x does not fit in that band from either side.
if R="$READING" python3 -c 'import os, sys; v = float(os.environ["R"]); sys.exit(0 if 80 <= v <= 130 else 1)'; then
  ok "one pinned core moves its session by ${READING}% — in the 80–130% band"
else
  bad "a known one-core load does not read as one core" \
      "moved ${READING}%, expected 80–130%. Below: a unit factor (mach ticks are not nanoseconds — this Mac's timebase is 125/3, so the naive reading is 24x low), or the machine was too busy to give the loop a core. Above: double counting."
fi

echo
echo "3. a known 500 MB allocation moves CHUTE's OWN figure by 500 MB"

# THROUGH `chute sessions`, NOT `ps`. An earlier draft of this check read `ps -o rss=` on the
# child — which proves that ps can measure 500 MB and says nothing whatever about the code that
# ships. The number under test has to come out of the product.
#
# It also exercises the tree attribution for free: the child gets NO controlling terminal (ps
# prints "??"), so it can only land on a session by inheriting its Unix session id — the route
# that survives double-forking and reparenting. Measured while writing this: the child was
# attributed to ttys003, 494 MB → 1000 MB.
per_tty() {
  "$CHUTE" sessions --json 2>/dev/null | python3 -c '
import json, sys
for r in json.load(sys.stdin):
    print(r.get("tty", "?"), r.get("memoryBytes", 0))
'
}
BEFORE_F=$(mktemp); per_tty > "$BEFORE_F"

# Every page TOUCHED. An untouched allocation is not resident and must NOT move the footprint —
# that is the difference between virtual size and what the machine is actually holding.
python3 -c '
import time
buf = bytearray(500 * 1024 * 1024)
for i in range(0, len(buf), 4096): buf[i] = 1
time.sleep(4)
' &
HOG=$!
sleep 1.5
AFTER_F=$(mktemp); per_tty > "$AFTER_F"
wait $HOG 2>/dev/null

# The LARGEST per-session delta, not the total: the other sessions on this machine are live
# agents whose own figures drift by tens of megabytes while we look. Isolating to one session
# keeps that drift out of the measurement instead of adding it in.
DELTA=$(python3 -c '
import sys
def load(p):
    d = {}
    for line in open(p):
        parts = line.split()
        if len(parts) == 2: d[parts[0]] = int(parts[1])
    return d
a, b = load(sys.argv[1]), load(sys.argv[2])
print(max((b[k] - a.get(k, 0) for k in b), default=0) // (1024 * 1024))
' "$BEFORE_F" "$AFTER_F")
rm -f "$BEFORE_F" "$AFTER_F"

if [ "$DELTA" -ge 400 ] && [ "$DELTA" -le 600 ]; then
  ok "500 MB allocated and touched moved a session by ${DELTA} MB — within ±20%"
else
  bad "a known 500 MB allocation does not measure 500 MB" \
      "moved ${DELTA} MB, expected 400–600. Far above: shared pages counted once per process (summed rss ran x1.78–x1.93 high). Far below: the child was never attributed to a session, so the tree walk is broken."
fi

echo
echo "check-metrics: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
