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

echo "13. help and unknown command"
has "help lists bundle" "$("$CHUTE" help)" "bundle"
"$CHUTE" definitelynotacommand >/dev/null 2>&1 && bad "unknown exits non-zero" "exit 0" || ok "unknown exits non-zero"

cd /; rm -rf "$T"
echo
echo "smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
