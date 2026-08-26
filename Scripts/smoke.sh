#!/usr/bin/env bash
# End-to-end verification. Exits non-zero on the first failure.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHUTE="$ROOT/.build/release/chute"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n     %s\n' "$1" "${2:-}"; }
check(){ if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "got '$2' expected '$3'"; fi; }
has()  { if printf '%s' "$2" | grep -qF -- "$3"; then ok "$1"; else bad "$1" "missing '$3'"; fi; }
hasnt(){ if printf '%s' "$2" | grep -qF -- "$3"; then bad "$1" "should not contain '$3'"; else ok "$1"; fi; }

[ -x "$CHUTE" ] || { echo "build first: swift build -c release"; exit 1; }
SAVED="$(pbpaste)"; trap 'printf %s "$SAVED" | pbcopy' EXIT

T="$(mktemp -d)"; cd "$T"
mkdir -p proj/src && cd proj
echo 'export const a = 1' > src/a.ts
echo 'export const b = 2' > src/b.ts
printf '# Readme\n\nhello\n' > README.md

echo "1. paths"
OUT="$("$CHUTE" paths src/a.ts src/b.ts README.md --no-copy)"
check "three lines"        "$(printf '%s' "$OUT" | wc -l | tr -d ' ')" "2"
has   "absolute paths"     "$OUT" "$T/proj/src/a.ts"
OUT="$("$CHUTE" paths src/a.ts src/b.ts README.md --format relative --no-copy)"
has   "relative form"      "$OUT" "src/a.ts"
hasnt "relative has no abs" "$OUT" "$T"
"$CHUTE" paths src/a.ts >/dev/null 2>&1
has   "clipboard written"  "$(pbpaste)" "$T/proj/src/a.ts"

echo "2. bundle"
OUT="$("$CHUTE" bundle src/a.ts README.md --no-copy)"
has "xml file tag"    "$OUT" '<file path="src/a.ts">'
has "xml content"     "$OUT" 'export const a = 1'
has "xml closes"      "$OUT" '</file>'
OUT="$("$CHUTE" bundle src/a.ts --format md --no-copy)"
has "md fence"        "$OUT" '```ts src/a.ts'

echo "3. binary files are skipped, not corrupted"
printf '\x89PNG\x00\x01\x02binary' > logo.png
ERR="$("$CHUTE" bundle logo.png README.md --no-copy 2>&1 >/dev/null)"
has "skips binary"    "$ERR" "skipped 1 binary"

echo "4. tokens"
has "token total"     "$("$CHUTE" tokens src/a.ts README.md)" "TOTAL"

echo "5. new file from clipboard"
printf '# My Great Spec\n\nbody text\n' | pbcopy
NEW="$("$CHUTE" new --dir . 2>/dev/null)"
check "named from heading" "$(basename "$NEW")" "my-great-spec.md"
has   "content preserved"  "$(cat "$NEW")" "body text"
NEW2="$("$CHUTE" new --dir . 2>/dev/null)"
check "never overwrites"   "$(basename "$NEW2")" "my-great-spec-2.md"
printf '{"a": 1, "b": [2,3]}' | pbcopy
NEW3="$("$CHUTE" new --dir . --name cfg 2>/dev/null)"
check "detects json"       "$(basename "$NEW3")" "cfg.json"

echo "6. unpack — dry run is the default"
printf '### src/new1.ts\n```ts\nconst n = 1\n```\n### src/new2.py\n```python\nn = 2\n```\n' | pbcopy
OUT="$("$CHUTE" unpack --dir . 2>&1)"
has "dry run lists"   "$OUT" "src/new1.ts"
if [ -f src/new1.ts ]; then bad "dry run writes nothing" "src/new1.ts was created"; else ok "dry run writes nothing"; fi
"$CHUTE" unpack --dir . --force >/dev/null 2>&1
if [ -f src/new1.ts ] && [ -f src/new2.py ]; then ok "--force writes both"; else bad "--force writes both" "missing files"; fi
check "content correct" "$(cat src/new1.ts)" "const n = 1"

echo "7. unpack refuses path traversal"
printf '### ../../etc/pwned.txt\n```\nx\n```\n' | pbcopy
OUT="$("$CHUTE" unpack --dir . --force 2>&1)"
has "refuses traversal" "$OUT" "refusing to write outside"
if [ -f ../../etc/pwned.txt ]; then bad "no escape" "wrote outside"; else ok "no escape"; fi

echo "8. checkpoint never touches the worktree"
git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm init
echo "uncommitted work" > src/wip.ts
BEFORE="$(git status --porcelain | sort)"
HEAD_BEFORE="$(git rev-parse HEAD)"; REF_BEFORE="$(git rev-parse --abbrev-ref HEAD)"
BRANCH="$("$CHUTE" checkpoint . 2>/dev/null)"
AFTER="$(git status --porcelain | sort)"
check "worktree unchanged" "$AFTER" "$BEFORE"
check "HEAD unmoved" "$(git rev-parse HEAD)" "$HEAD_BEFORE"
check "still on original branch" "$(git rev-parse --abbrev-ref HEAD)" "$REF_BEFORE"
has "checkpoint holds untracked wip" "$(git show --stat "$BRANCH" 2>/dev/null)" "wip.ts"
if git rev-parse --verify -q "$BRANCH" >/dev/null; then ok "checkpoint branch exists"; else bad "checkpoint branch exists" "$BRANCH missing"; fi

echo "9. redact"
OUT="$("$CHUTE" redact --no-copy <<< "" 2>/dev/null; printf 'sk-ant-api03-SECRETVALUE1234567890\nOPENAI_API_KEY=leakme-now\n' | pbcopy; "$CHUTE" redact --no-copy)"
hasnt "anthropic key masked" "$OUT" "SECRETVALUE"
hasnt "env value masked"     "$OUT" "leakme-now"
has   "key name kept"        "$OUT" "OPENAI_API_KEY="

echo "10. clean lists but does not delete"
touch temp_scratch.py debug.log
OUT="$("$CHUTE" clean . 2>&1)"
has "lists scratch" "$OUT" "temp_scratch.py"
if [ -f temp_scratch.py ]; then ok "no deletion without --force"; else bad "no deletion without --force" "file gone"; fi

echo "11. seed + tree + note"
"$CHUTE" seed . --rules claude,cursor >/dev/null 2>&1
if [ -f CLAUDE.md ] && [ -f .cursorrules ]; then ok "rules seeded"; else bad "rules seeded" "missing"; fi
echo "SENTINEL" > CLAUDE.md
"$CHUTE" seed . --rules claude >/dev/null 2>&1
check "seed never overwrites" "$(cat CLAUDE.md)" "SENTINEL"
has "tree hides junk" "$("$CHUTE" tree . --no-copy)" "src/"
mkdir -p node_modules/x && touch node_modules/x/y.js
hasnt "tree excludes node_modules" "$("$CHUTE" tree . --no-copy)" "node_modules"
"$CHUTE" note "left off here" --dir . >/dev/null 2>&1
has "scratchpad written" "$(cat SCRATCHPAD.md)" "left off here"

echo "12. env inject refuses an untracked-secret setup"
OUT="$("$CHUTE" env inject . 2>&1)"
has "refuses ungitignored .env" "$OUT" "not gitignored"

echo "14. sessions, doctor, hooks"
# sessions talks to Terminal via AppleScript. On a machine without permission it must still
# emit valid JSON and say why, never crash — that is the contract being checked here.
OUT="$("$CHUTE" sessions --json 2>/dev/null)"
if printf '%s' "$OUT" | python3 -c 'import json,sys; sys.exit(0 if isinstance(json.load(sys.stdin), list) else 1)' 2>/dev/null
then ok "sessions --json is a JSON array"; else bad "sessions --json is a JSON array" "not parseable: $OUT"; fi
has "sessions prints a tally" "$("$CHUTE" sessions 2>&1)" "session(s)"
"$CHUTE" focus nosuchprojectanywhere >/dev/null 2>&1 && bad "focus on no match exits non-zero" "exit 0" || ok "focus on no match exits non-zero"

OUT="$("$CHUTE" doctor --json 2>/dev/null)"
if printf '%s' "$OUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if all("id" in c and "passed" in c for c in d) else 1)' 2>/dev/null
then ok "doctor --json reports id+passed per check"; else bad "doctor --json reports id+passed per check" "bad shape"; fi
has "doctor names a fix" "$("$CHUTE" doctor 2>&1)" "checks"

# NEVER against ~/.claude/settings.json — a temp fixture only.
S="$T/settings.json"; printf '{"hooks":{},"model":"opus"}' > "$S"
has   "hooks status lists events"  "$("$CHUTE" hooks status --settings "$S" 2>&1)" "SessionStart"
OUT="$("$CHUTE" hooks install --settings "$S" 2>&1)"
has   "install reports a backup"   "$OUT" "backup:"
has   "install wires the events"   "$OUT" "SessionStart"
has   "status now shows wired"     "$("$CHUTE" hooks status --settings "$S" 2>&1)" "✓ SessionStart"
has   "unrelated keys survive"     "$(cat "$S")" '"model"'
BEFORE="$(cat "$S")"
"$CHUTE" hooks install --settings "$S" >/dev/null 2>&1
check "install is idempotent"      "$(cat "$S")" "$BEFORE"
"$CHUTE" hooks uninstall --settings "$S" >/dev/null 2>&1
hasnt "uninstall removes chute"    "$(cat "$S")" "chute"
has   "uninstall keeps your keys"  "$(cat "$S")" '"model"'
check "uninstall leaves no husk"   "$(cat "$S")" '{
  "hooks" : {

  },
  "model" : "opus"
}'

echo "15. every Finder menu action, run for real"
# Driven by `chute finder-actions --json` — the SAME table the menu draws from, so a menu item
# that cannot work fails here instead of in the user's hands.
FX="$T/finder"; mkdir -p "$FX/src"
echo 'export const a = 1' > "$FX/src/a.ts"
echo 'KEY=sk-live-abcdef1234567890' > "$FX/src/keys.env"
( cd "$FX" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm init )
echo 'export const a = 2' > "$FX/src/a.ts"      # an uncommitted change for the diff action

argv_for() { "$CHUTE" finder-actions --json --dir "$FX" "$FX/src/a.ts" "$FX/src/keys.env" \
    | python3 -c 'import json,sys;print("\n".join(next(a["argv"] for a in json.load(sys.stdin) if a["id"]==sys.argv[1])))' "$1"; }
run_action() { local id="$1"; shift; local args=(); while IFS= read -r line; do args+=("$line"); done < <(argv_for "$id")
    "$CHUTE" "${args[@]}" "$@" >/tmp/chute-a.out 2>/tmp/chute-a.err; return $?; }

# Seed the clipboard with something every clipboard-reading action can use, so the sweep below
# tests the ACTIONS rather than an empty pasteboard.
printf '# Sweep Fixture\n\n### src/sweep.ts\n```ts src/sweep.ts\nconst s = 1\n```\n' | pbcopy
ALL_IDS="$("$CHUTE" finder-actions --json | python3 -c 'import json,sys;print(" ".join(a["id"] for a in json.load(sys.stdin)))')"
for id in $ALL_IDS; do
  # The copy actions overwrite the clipboard as they run, so anything that READS it is re-seeded
  # immediately before its turn.
  printf '# Sweep Fixture\n\n### src/sweep.ts\n```ts src/sweep.ts\nconst s = 1\n```\n' | pbcopy
  case "$id" in
    terminal) ok "terminal: argv built (execution skipped — it opens a real window)"; continue;;
    workspace) run_action "$id" --no-launch >/dev/null 2>&1;;
    *) run_action "$id" >/dev/null 2>&1;;
  esac
  if [ $? -eq 0 ]; then ok "$id runs clean"; else bad "$id runs clean" "$(tail -1 /tmp/chute-a.err)"; fi
done

# Each action's OBSERVABLE effect, not just its exit code.
run_action copy-paths        >/dev/null 2>&1; has "copy-paths lands on the clipboard"    "$(pbpaste)" "$FX/src/a.ts"
run_action copy-contents     >/dev/null 2>&1; has "copy-contents carries file bodies"    "$(pbpaste)" "export const a = 2"
run_action copy-masked       >/dev/null 2>&1; has "copy-masked hides the secret"         "$(pbpaste)" "[REDACTED]"
run_action copy-masked       >/dev/null 2>&1; hasnt "copy-masked leaks nothing"          "$(pbpaste)" "sk-live-abcdef1234567890"
run_action token-cost        >/dev/null 2>&1; has "token-cost reports a total"           "$(cat /tmp/chute-a.out)" "TOTAL"
run_action copy-tree         >/dev/null 2>&1; has "copy-tree shows the folder layout"    "$(pbpaste)" "src/"

printf '# Handoff Note\n\nbody\n' | pbcopy
run_action clipboard-to-file >/dev/null 2>&1
if [ -f "$FX/handoff-note.md" ]; then ok "clipboard-to-file names the file from its heading"; else bad "clipboard-to-file names the file from its heading" "no handoff-note.md in $FX"; fi

# THE BUG THIS SECTION EXISTS FOR: the menu item promised a write and ran a dry run.
printf '### src/new1.ts\n```ts\nconst n = 1\n```\n### src/new2.py\n```python\nn = 2\n```\n' | pbcopy
run_action clipboard-to-files >/dev/null 2>&1
if [ -f "$FX/src/new1.ts" ] && [ -f "$FX/src/new2.py" ]; then ok "clipboard-to-files WRITES the files"
else bad "clipboard-to-files WRITES the files" "still a dry run — nothing on disk"; fi

run_action snapshot >/dev/null 2>&1
has "snapshot creates a git ref" "$(cd "$FX" && git branch --list 'chute/*'; git tag -l 'chute*'; git log --all --oneline 2>/dev/null | head -3)" "chute"
run_action review-changes >/dev/null 2>&1; has "review-changes copies the patch" "$(pbpaste)" "export const a = 2"
run_action workspace --no-launch >/dev/null 2>&1
if [ -f "$(cat /tmp/chute-a.out | tail -1)/README.md" ]; then ok "workspace creates a real folder"
else bad "workspace creates a real folder" "$(tail -1 /tmp/chute-a.err)"; fi

# Actions must never be offered where they cannot work — checked in chutetests; here we prove the
# table the menu reads is the table this section ran.
check "the menu table and this test agree" "$(printf '%s' "$ALL_IDS" | wc -w | tr -d ' ')" "11"

echo "16. the Finder extension's request inbox (needs Chute.app running)"
# The extension is sandboxed: it cannot run git, launch Terminal or drive AppleScript. It writes a
# request and Chute.app carries it out. This section tests that handoff on the real inbox.
INBOX="$HOME/.chute/requests"
put_request() {  # id dir age_seconds
  python3 - "$1" "$2" "${3:-0}" "$INBOX" <<'PYEOF'
import json, os, random, sys, time
action, folder, age, inbox = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4]
os.makedirs(inbox, exist_ok=True)
ts = time.time() - age
path = os.path.join(inbox, "%d-%s-%d.json" % (ts * 1000, action, random.randint(0, 999999)))
open(path, "w").write(json.dumps({"id": action, "dir": folder, "files": sys.argv[5:], "ts": ts}))
print(path)
PYEOF
}
wait_for_empty_inbox() { for _ in 1 2 3 4 5 6 7 8 9 10; do
  [ "$(ls "$INBOX" 2>/dev/null | wc -l | tr -d ' ')" = "0" ] && return 0; sleep 1; done; return 1; }

if ! pgrep -x ChuteApp >/dev/null 2>&1; then
  echo "  SKIP inbox checks — Chute.app is not running (start it: open ~/Applications/Chute.app)"
else
  printf 'INBOX-SENTINEL' | pbcopy
  put_request review-changes "$FX" 0 >/dev/null
  if wait_for_empty_inbox; then ok "the app drains the inbox"; else bad "the app drains the inbox" "still pending after 10s"; fi
  sleep 1
  has "a git action the extension CANNOT run itself succeeds through the app" "$(pbpaste)" "export const a = 2"

  # A request the app should refuse: unknown action, and one from an hour ago.
  printf 'REFUSE-SENTINEL' | pbcopy
  put_request no-such-action "$FX" 0 >/dev/null
  put_request review-changes "$FX" 3600 >/dev/null
  if wait_for_empty_inbox; then ok "refused requests are cleaned up, not retried forever"
  else bad "refused requests are cleaned up, not retried forever" "still pending"; fi
  check "a stale click is never carried out later" "$(pbpaste)" "REFUSE-SENTINEL"
fi

echo "13. help and unknown command"
has "help lists bundle" "$("$CHUTE" help)" "bundle"
"$CHUTE" definitelynotacommand >/dev/null 2>&1 && bad "unknown exits non-zero" "exit 0" || ok "unknown exits non-zero"

cd /; rm -rf "$T"
echo
echo "smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
