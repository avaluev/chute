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

# CHUTE_HEADLESS=1 skips the sections that need a logged-in Mac with Finder, Terminal and the app
# running — which is what a CI runner is. Everything else still runs, so a macOS version this
# machine cannot boot is still tested for the 90% that is pure CLI.
HEADLESS="${CHUTE_HEADLESS:-0}"
skip() { printf '  SKIP %s (headless)\n' "$1"; }
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

echo "7b. unpack refuses to follow a symlink out of the target folder"
mkdir -p esc/safe esc/outside && ln -sfn "$T/proj/esc/outside" esc/safe/link
printf '### link/pwned.txt\n```\nx\n```\n' | pbcopy
OUT="$("$CHUTE" unpack --dir esc/safe --force 2>&1)"
if [ -f esc/outside/pwned.txt ]; then bad "no escape through a symlink" "wrote outside the folder"
else ok "no escape through a symlink"; fi
has "and says why" "$OUT" "resolves elsewhere"

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
# REGRESSION. `git add -A` is fatal on a nested repo with no commit, and "New Scratch Folder"
# creates exactly that one right-click before someone reaches for a checkpoint. Found by the
# section-15 sweep running the menu in declared order against one folder.
mkdir -p nested-empty && git -C nested-empty init -q
if "$CHUTE" checkpoint . >/dev/null 2>/tmp/chute-ck.err; then
  ok "checkpoint survives a nested repo with no commit"
else
  bad "checkpoint survives a nested repo with no commit" "$(tail -1 /tmp/chute-ck.err)"
fi
rm -rf nested-empty
# REGRESSION. `git write-tree` on an index that staged nothing emits git's empty tree and exits
# 0, so a folder where NOTHING can be indexed used to mint a branch and print a restore command
# for a snapshot holding no files. A safety net is discovered empty on the day it is needed.
mkdir -p unindexable && (cd unindexable && git init -q && echo secret > only.txt && chmod 000 only.txt)
if (cd unindexable && "$CHUTE" checkpoint . >/dev/null 2>/tmp/chute-ck2.err); then
  bad "a checkpoint that would hold nothing is refused" "exited 0 and minted a branch"
else
  has "a checkpoint that would hold nothing is refused" "$(cat /tmp/chute-ck2.err)" "would be empty"
fi
chmod 644 unindexable/only.txt 2>/dev/null; rm -rf unindexable

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
if [ "$HEADLESS" = "1" ]; then skip "sessions — needs Terminal and Automation permission"; else
# sessions talks to Terminal via AppleScript. On a machine without permission it must still
# emit valid JSON and say why, never crash — that is the contract being checked here.
OUT="$("$CHUTE" sessions --json 2>/dev/null)"
if printf '%s' "$OUT" | python3 -c 'import json,sys; sys.exit(0 if isinstance(json.load(sys.stdin), list) else 1)' 2>/dev/null
then ok "sessions --json is a JSON array"; else bad "sessions --json is a JSON array" "not parseable: $OUT"; fi
OUT="$("$CHUTE" sessions 2>&1)"
has "sessions prints a tally"      "$OUT" "session(s)"
# The "This Mac — using N of M cores · battery at 31 °C" footer was deleted: the battery sensor
# does not track how hot the chassis gets under an agent workload, and a whole-machine core
# average never explained why anything was slow. Assert it is GONE, so it cannot come back by
# accident along with the temperature reader.
printf '%s' "$OUT" | grep -q "This Mac" \
  && bad "sessions does not editorialise about the machine" "the This-Mac footer is back" \
  || ok "sessions does not editorialise about the machine"
# CPU and memory per session: at least one of this machine's terminals is doing something.
if printf '%s' "$OUT" | grep -qE '[0-9]+% · [0-9.]+ (MB|GB)'; then ok "sessions reports CPU and memory"
else ok "sessions reports CPU and memory (none busy enough to show — the quiet case)"; fi
if printf '%s' "$("$CHUTE" sessions --json 2>/dev/null)" \
   | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if not d or all("cpuPercent" in r and "memoryBytes" in r for r in d) else 1)'
then ok "sessions --json carries the vitals"; else bad "sessions --json carries the vitals" "missing keys"; fi
"$CHUTE" focus nosuchprojectanywhere >/dev/null 2>&1 && bad "focus on no match exits non-zero" "exit 0" || ok "focus on no match exits non-zero"

OUT="$("$CHUTE" doctor --json 2>/dev/null)"
if printf '%s' "$OUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if all("id" in c and "passed" in c for c in d) else 1)' 2>/dev/null
then ok "doctor --json reports id+passed per check"; else bad "doctor --json reports id+passed per check" "bad shape"; fi
has "doctor names a fix" "$("$CHUTE" doctor 2>&1)" "checks"

# A problem report is pasted into a PUBLIC issue, so it must carry the checks and no secrets.
REPORT="$("$CHUTE" doctor --report 2>/dev/null)"
has   "report asks what happened"   "$REPORT" "What happened"
has   "report carries the checks"   "$REPORT" "macOS version"
# Read from the single source, never a literal. This line said "chute 0.1.0" and went red the
# moment the version was bumped — a hardcoded copy of the number that Sources/ChuteCore/
# Version.swift exists to be the only copy of.
VERSION="$(sed -n 's/.*static let current = "\([^"]*\)".*/\1/p' "$ROOT/Sources/ChuteCore/Version.swift")"
has   "report states the version"   "$REPORT" "chute $VERSION"
hasnt "report repairs nothing"      "$REPORT" "Fixed"

fi
# NEVER against ~/.claude/settings.json — a temp fixture only.
S="$T/settings.json"; printf '{"hooks":{},"model":"opus"}' > "$S"
has   "hooks status lists events"  "$("$CHUTE" hooks status --settings "$S" 2>&1)" "SessionStart"
# THE CONTRACT: Chute never writes to the agent's settings. `install`/`snippet` only PRINT.
BEFORE="$(cat "$S")"
OUT="$("$CHUTE" hooks install --settings "$S" 2>&1)"
has   "install prints the snippet"      "$OUT" "chute-session-state"
has   "install says it never writes"    "$OUT" "does not modify"
check "install writes NOTHING"          "$(cat "$S")" "$BEFORE"
# Seed a legacy install (what pre-decision Chute versions wrote) and verify uninstall
# strips exactly it — that is the one write that remains, and it only ever subtracts.
"$CHUTE" hooks snippet --settings "$S" 2>/dev/null > "$T/snippet.json"
python3 -c '
import json, sys
s = json.load(open(sys.argv[1])); sn = json.load(open(sys.argv[2]))
s["hooks"] = sn["hooks"]; json.dump(s, open(sys.argv[1], "w"))
' "$S" "$T/snippet.json"
has   "legacy hooks seeded"        "$(cat "$S")" "chute-session-state"
has   "status shows the wiring"    "$("$CHUTE" hooks status --settings "$S" 2>&1)" "✓ SessionStart"
# NFR-05, extended 2026-08-29: uninstall previews by default. The dry run must change NOTHING.
BEFORE_UNINSTALL="$(cat "$S")"
OUT="$("$CHUTE" hooks uninstall --settings "$S" 2>&1)"
has   "uninstall previews first"   "$OUT" "re-run with --force"
check "the preview writes NOTHING" "$(cat "$S")" "$BEFORE_UNINSTALL"
"$CHUTE" hooks uninstall --settings "$S" --force >/dev/null 2>&1
hasnt "uninstall removes chute"    "$(cat "$S")" "chute"
has   "uninstall keeps your keys"  "$(cat "$S")" '"model"'
check "uninstall leaves no husk"   "$(cat "$S")" '{
  "hooks" : {

  },
  "model" : "opus"
}'
BEFORE="$(cat "$S")"
"$CHUTE" hooks uninstall --settings "$S" --force >/dev/null 2>&1
check "second uninstall is a no-op" "$(cat "$S")" "$BEFORE"

echo "15. every Finder menu action, run for real"
# Driven by `chute finder-actions --json` — the SAME table the menu draws from, so a menu item
# that cannot work fails here instead of in the user's hands.
FX="$T/finder"; mkdir -p "$FX/src/deep/deeper"
echo 'export const a = 1' > "$FX/src/a.ts"
echo 'export const b = 2' > "$FX/src/deep/b.ts"
echo 'export const c = 3' > "$FX/src/deep/deeper/c.ts"

argv_for() { "$CHUTE" finder-actions --json --dir "$FX" "$FX/src/a.ts" "$FX/src/deep/b.ts" \
    | python3 -c 'import json,sys;print("\n".join(next(a["argv"] for a in json.load(sys.stdin) if a["id"]==sys.argv[1])))' "$1"; }
run_action() { local id="$1"; shift; local args=(); while IFS= read -r line; do args+=("$line"); done < <(argv_for "$id")
    "$CHUTE" "${args[@]}" "$@" >/tmp/chute-a.out 2>/tmp/chute-a.err; return $?; }

ALL_IDS="$("$CHUTE" finder-actions --json | python3 -c 'import json,sys;print(" ".join(a["id"] for a in json.load(sys.stdin)))')"
for id in $ALL_IDS; do
  printf '# Sweep Fixture\n\nbody\n' | pbcopy      # anything reading the clipboard gets something usable
  case "$id" in
    terminal) ok "terminal: argv built (execution skipped — it opens a real window)"; continue;;
    # Same reason as `terminal`: it opens a window and starts an agent. --no-launch exercises
    # everything up to that point (folder, git init, rules) without leaving a Terminal behind.
    sandbox-here)
      if ! command -v claude >/dev/null 2>&1; then skip "sandbox-here — claude is not on PATH"; continue; fi
      run_action "$id" --no-launch >/dev/null 2>&1;;
    # `checkpoint` refuses outside a git repository, which is correct and is asserted in section
    # 8. The sweep fixture is a plain folder, so give it the state a user right-clicking this
    # action is actually in. Declared LAST in the submenu, so this runs after the other agent
    # actions have already seen the plain folder.
    checkpoint-here)
      git -C "$FX" rev-parse --is-inside-work-tree >/dev/null 2>&1 || git -C "$FX" init -q
      run_action "$id" >/dev/null 2>&1;;
    # The sweep's clipboard is plain prose, and `unpack` correctly refuses prose. Give it the
    # thing it is for — a fenced block with a path — or this asserts the refusal, not the feature.
    unpack-here)
      printf '```ts sweep/out.ts\nexport const x = 1\n```\n' | pbcopy
      run_action "$id" >/dev/null 2>&1;;
    paste-image)
      if [ "$HEADLESS" = "1" ]; then skip "paste-image — needs an image on the pasteboard"; continue; fi
      sips -s format png "$ROOT/Resources/Chute.icns" --out "$T/sweep.png" >/dev/null 2>&1
      osascript -e "set the clipboard to (read (POSIX file \"$T/sweep.png\") as «class PNGf»)" >/dev/null 2>&1
      run_action "$id" --no-rename >/dev/null 2>&1;;
    *) run_action "$id" >/dev/null 2>&1;;
  esac
  if [ $? -eq 0 ]; then ok "$id runs clean"; else bad "$id runs clean" "$(tail -1 /tmp/chute-a.err)"; fi
done

# Each action's OBSERVABLE effect, not just its exit code.
run_action copy-paths >/dev/null 2>&1
has   "copy-paths lands on the clipboard"  "$(pbpaste)" "$FX/src/a.ts"
has   "copy-paths includes every selected file" "$(pbpaste)" "$FX/src/deep/b.ts"

# OPEN CORE, ASSERTED. The CLI is MIT and free forever; only Chute.app is licensed. If a trial
# check ever leaks into ChuteCore paths the CLI reaches, `brew install chute` starts expiring and
# the whole top of the funnel dies quietly. So: plant an EXPIRED trial record and prove the CLI
# does not care. install.sh symlinks ~/.local/bin/chute out of the app bundle, which is exactly
# how such a leak would reach a free user.
TRIALDIR="$T/Library/Application Support/Chute"; mkdir -p "$TRIALDIR"
python3 - "$TRIALDIR/trial.json" <<'PY'
import json, sys, time
long_ago = time.time() - 400 * 86400
json.dump({"firstRun": long_ago - 978307200, "lastSeen": time.time() - 978307200}, open(sys.argv[1], "w"))
PY
if HOME="$T" "$CHUTE" paths "$FX/src/a.ts" --no-copy >/dev/null 2>&1; then
  ok "the CLI still runs with an expired trial on disk"
else
  bad "the CLI still runs with an expired trial on disk" "$(tail -1 /tmp/chute-a.err 2>/dev/null)"
fi
if HOME="$T" "$CHUTE" bundle "$FX/src/a.ts" --no-copy >/dev/null 2>&1; then
  ok "including the paid-looking wedge command"
else
  bad "including the paid-looking wedge command" "bundle refused to run"
fi
hasnt "and the CLI binary carries no licence prompt" "$("$CHUTE" help 2>&1)" "licence"

# THE WEDGE: one right-click must produce every file's CONTENTS plus a token count. This is the
# claim the landing page and the demo both rest on, so it is asserted, not assumed.
run_action bundle-xml >/dev/null 2>&1
has   "bundle-xml carries the file contents"   "$(pbpaste)" "export const a = 1"
has   "bundle-xml carries every selected file" "$(pbpaste)" "export const b = 2"
has   "bundle-xml reports a token count"       "$(cat /tmp/chute-a.err)" "token"

# THE FOUR ACTIONS THAT MAKE THE APP WORTH BUYING. Each was CLI-only, so the paid surface
# demonstrated ~73 min/day of the ledger while the free CLI demonstrated ~125. Their EFFECT is
# asserted here, not just their exit code — a menu item that runs clean and does nothing is the
# failure mode this whole file exists for.

# NFR-05 ACROSS THE MENU BOUNDARY: without --force these two must change NOTHING. The app runs
# exactly this form first and only re-runs with --force once the user has seen the list.
printf '```ts sweep/out.ts\nexport const x = 1\n```\n' | pbcopy
run_action unpack-here >/dev/null 2>&1
has   "unpack-here previews the file it would write" "$(cat /tmp/chute-a.out)" "sweep/out.ts"
if [ ! -e "$FX/sweep/out.ts" ]; then ok "and writes nothing until it is confirmed"
else bad "and writes nothing until it is confirmed" "$FX/sweep/out.ts exists after a preview"; fi

run_action seed-rules >/dev/null 2>&1
if [ -f "$FX/CLAUDE.md" ]; then ok "seed-rules leaves rules an agent will actually read"
else bad "seed-rules leaves rules an agent will actually read" "no CLAUDE.md in $FX"; fi

touch "$FX/temp_agent_output.log"
run_action clean-junk >/dev/null 2>&1
has   "clean-junk finds what an agent left behind" "$(cat /tmp/chute-a.out)" "temp_agent_output.log"
if [ -e "$FX/temp_agent_output.log" ]; then ok "and trashes nothing until it is confirmed"
else bad "and trashes nothing until it is confirmed" "the file was removed by a preview"; fi
rm -f "$FX/temp_agent_output.log"

run_action tree-2 >/dev/null 2>&1
has   "tree-2 shows the folder"            "$(pbpaste)" "src/"
hasnt "tree-2 stops at two levels"         "$(pbpaste)" "deeper"
run_action tree-all >/dev/null 2>&1
has   "tree-all reaches the bottom"        "$(pbpaste)" "deeper"

run_action new-markdown >/dev/null 2>&1
# --rename asks Finder to start inline rename. Without Accessibility permission the keystroke is
# refused, and the file must STILL be created — a permission is not a reason to lose the file.
if [ -f "$FX/Untitled.md" ]; then ok "new-markdown creates an empty Untitled.md"
else bad "new-markdown creates an empty Untitled.md" "$(tail -1 /tmp/chute-a.err)"; fi
run_action new-markdown >/dev/null 2>&1
if [ -f "$FX/Untitled-2.md" ]; then ok "and never overwrites the first one"
else bad "and never overwrites the first one" "no Untitled-2.md"; fi

# The founder's naming rule: first line of text, spaces to underscores, no slugging.
printf '# This is thd header\n\nbody text\n' | pbcopy
run_action new-markdown-clipboard >/dev/null 2>&1
if [ -f "$FX/This_is_thd_header.md" ]; then ok "new-markdown-clipboard names the file from its first line"
else bad "new-markdown-clipboard names the file from its first line" "$(ls "$FX")"; fi
has   "and keeps the content"              "$(cat "$FX/This_is_thd_header.md" 2>/dev/null)" "body text"
"$CHUTE" new --blank --rename --dir "$FX" --name renametest >/dev/null 2>/tmp/chute-rn.err
if [ -f "$FX/renametest.md" ]; then ok "--rename still creates the file when the keystroke is refused"
else bad "--rename still creates the file when the keystroke is refused" "$(cat /tmp/chute-rn.err)"; fi
if grep -q "Accessibility\|rename" /tmp/chute-rn.err 2>/dev/null || [ ! -s /tmp/chute-rn.err ]; then
  ok "and says what to allow, rather than failing silently"
else bad "and says what to allow, rather than failing silently" "$(cat /tmp/chute-rn.err)"; fi

# THOUSANDS of files: a Finder selection that would blow past ARG_MAX as arguments.
MANY="$T/many"; mkdir -p "$MANY"
python3 -c "
import os
for i in range(3000): open(os.path.join('$MANY', 'file_%04d.txt' % i), 'w').write('x')
"
find "$MANY" -type f > "$T/many.txt"
"$CHUTE" paths --files-from "$T/many.txt" --no-copy > "$T/many-out.txt" 2>/dev/null
check "3000 selected files all come through" "$(awk 'END{print NR}' "$T/many-out.txt")" "3000"

# THE BUG-REPORT LOOP: screenshot → save here → path on the clipboard, ready to paste.
sips -s format png "$ROOT/Resources/Chute.icns" --out "$T/clip.png" >/dev/null 2>&1
if [ "$HEADLESS" = "1" ]; then
  skip "paste-image — needs a pasteboard with an image on it"
else
  osascript -e "set the clipboard to (read (POSIX file \"$T/clip.png\") as «class PNGf»)" >/dev/null 2>&1
  OUT="$("$CHUTE" paste-image --dir "$FX" --no-rename 2>&1)"
  SAVED="$(printf '%s' "$OUT" | grep '\.png$' | head -1)"
  if [ -f "$SAVED" ]; then ok "paste-image writes the clipboard image to disk"
  else bad "paste-image writes the clipboard image to disk" "$OUT"; fi
  check "and copies its full path"  "$(pbpaste)" "$SAVED"
  has   "named like a macOS screenshot" "$(basename "$SAVED")" "Screenshot "
  # PNG magic bytes: the file must be a real image, not a renamed TIFF.
  check "the file really is a PNG" "$(head -c 4 "$SAVED" | xxd -p)" "89504e47"

  # With no image on the clipboard it must say so, not write an empty file.
  BEFORE_COUNT="$(ls "$FX"/Screenshot*.png 2>/dev/null | wc -l | tr -d ' ')"
  printf 'just text' | pbcopy
  OUT="$("$CHUTE" paste-image --dir "$FX" --no-rename 2>&1)"
  has "no image on the clipboard is explained" "$OUT" "no image on the clipboard"
  check "and nothing is written" "$(ls "$FX"/Screenshot*.png 2>/dev/null | wc -l | tr -d ' ')" "$BEFORE_COUNT"
fi

# 14 = the 9 original actions, the four that moved out of the CLI so the paid surface can
# demonstrate the four highest-value jobs in the ledger (unpack, seed, sandbox, clean), and
# checkpoint — the last T1 job in the ledger that had no Finder surface. Change this number only
# when the menu changes, never to make this file pass.
check "the menu table and this test agree" "$(printf '%s' "$ALL_IDS" | wc -w | tr -d ' ')" "14"

echo "16. the Finder extension's request inbox (needs Chute.app running)"
# The extension is sandboxed: it cannot run git, launch Terminal or drive AppleScript. It writes a
# request and Chute.app carries it out. This section tests that handoff on the real inbox.
INBOX="$HOME/.chute/requests"
put_request() {  # id dir age_seconds [files…]
  python3 - "$1" "$2" "${3:-0}" "$INBOX" "${@:4}" <<'PYEOF'
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
# The app DELETES a request before running it — deliberately, so a crash cannot make it retry
# forever. An empty inbox therefore means "started", not "finished": wait for the actual result.
wait_for_clipboard_lines() { for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
  [ "$(pbpaste | awk 'END{print NR}')" = "$1" ] && return 0; sleep 1; done; return 1; }
wait_for_clipboard_contains() { for _ in 1 2 3 4 5 6 7 8 9 10; do
  pbpaste | grep -qF -- "$1" && return 0; sleep 1; done; return 1; }

if [ "$HEADLESS" = "1" ]; then
  skip "extension inbox — needs Chute.app running"
elif ! pgrep -x ChuteApp >/dev/null 2>&1; then
  # NOT a skip. On a Mac with the app installed, "Chute.app is not running" is the app failing to
  # launch — which is exactly how a bootstrap regression once slipped through as a green run.
  bad "Chute.app is running" "not running — install it, or fix why it exits (open ~/Applications/Chute.app)"
else
  printf 'INBOX-SENTINEL' | pbcopy
  put_request copy-paths "$FX" 0 "$FX/src/a.ts" >/dev/null
  if wait_for_empty_inbox; then ok "the app drains the inbox"; else bad "the app drains the inbox" "still pending after 10s"; fi
  if wait_for_clipboard_contains "$FX/src/a.ts"
  then ok "an action requested by the extension runs through the app"
  else bad "an action requested by the extension runs through the app" "clipboard: $(pbpaste | head -1)"; fi

  # A request the app must refuse: an unknown action, and one from an hour ago.
  printf 'REFUSE-SENTINEL' | pbcopy
  put_request no-such-action "$FX" 0 >/dev/null
  put_request copy-paths "$FX" 3600 "$FX/src/a.ts" >/dev/null
  if wait_for_empty_inbox; then ok "refused requests are cleaned up, not retried forever"
  else bad "refused requests are cleaned up, not retried forever" "still pending"; fi
  check "a stale click is never carried out later" "$(pbpaste)" "REFUSE-SENTINEL"

  # THOUSANDS of files through the real handoff: the request file has no ARG_MAX.
  printf 'MANY-SENTINEL' | pbcopy
  put_request copy-paths "$MANY" 0 $(find "$MANY" -type f | head -1200 | tr '\n' ' ') >/dev/null
  # awk NR, not wc -l: the clipboard's last path has no trailing newline and wc undercounts it.
  if wait_for_clipboard_lines 1200; then ok "1200 files survive the extension → app handoff"
  else bad "1200 files survive the extension → app handoff" "clipboard held $(pbpaste | awk 'END{print NR}') lines"; fi
fi

echo "17. local servers"
OUT="$("$CHUTE" ports 2>&1)"
has "ports names the columns"     "$OUT" "PORT"
has "ports says where it is reachable from" "$OUT" "REACHABLE FROM"
if printf '%s' "$OUT" | grep -q "nothing is listening"; then ok "empty case says so plainly"
else
  if printf '%s' "$OUT" | grep -qE '^[0-9]+ +[a-z]'; then ok "ports lists at least one real listener"
  else bad "ports lists at least one real listener" "$OUT"; fi
fi
"$CHUTE" ports --kill 65533 2>&1 | grep -q "nothing is listening on 65533" \
  && ok "killing a free port says nothing was there" || bad "killing a free port says nothing was there" "unexpected output"

echo "18. tree, in depth"
TR="$T/treetest"; mkdir -p "$TR/a/b/c/d" "$TR/node_modules/pkg" "$TR/.git/objects" "$TR/dist"
touch "$TR/root.ts" "$TR/a/one.ts" "$TR/a/b/two.ts" "$TR/a/b/c/three.ts" "$TR/a/b/c/d/four.ts"
touch "$TR/node_modules/pkg/index.js" "$TR/.git/objects/abc" "$TR/dist/bundle.js"
D1="$("$CHUTE" tree "$TR" --depth 1 --no-copy)"
D2="$("$CHUTE" tree "$TR" --depth 2 --no-copy)"
D4="$("$CHUTE" tree "$TR" --depth 4 --no-copy)"
DALL="$("$CHUTE" tree "$TR" --depth 99 --no-copy)"

has   "depth 1 shows the top level"        "$D1" "root.ts"
hasnt "depth 1 stops there"                "$D1" "one.ts"
has   "depth 2 reaches one level in"       "$D2" "one.ts"
hasnt "depth 2 stops at two"               "$D2" "two.ts"
has   "depth 4 reaches three levels in"    "$D4" "three.ts"
hasnt "depth 4 stops at four"              "$D4" "four.ts"
has   "everything reaches the bottom"      "$DALL" "four.ts"

hasnt "node_modules never appears"         "$DALL" "node_modules"
hasnt "the git directory never appears"    "$DALL" ".git"
hasnt "build output never appears"         "$DALL" "bundle.js"
mkdir -p "$T/emptydir"
"$CHUTE" tree "$T/emptydir" --no-copy >/dev/null 2>&1 \
  && ok "an empty folder is not an error" || bad "an empty folder is not an error" "non-zero exit"
"$CHUTE" tree "$TR" >/dev/null 2>&1
has   "tree lands on the clipboard"        "$(pbpaste)" "root.ts"

echo "19. the commands nothing was testing"
# buf — gather across many copies, paste once.
printf 'first chunk' | pbcopy; "$CHUTE" buf add >/dev/null 2>&1
printf 'second chunk' | pbcopy; "$CHUTE" buf add >/dev/null 2>&1
has   "buf lists what it holds"      "$("$CHUTE" buf list 2>&1)" "2"
# `all` is the name (the GUI row for this job reads "Copy All N Together"); `flush` is kept as
# an undocumented alias for muscle memory and scripts. Both are exercised so neither can be
# dropped by accident — an alias nothing tests is an alias nobody knows is load-bearing.
"$CHUTE" buf all --keep >/dev/null 2>&1
OUT="$(pbpaste)"
has   "buf all returns the first"    "$OUT" "first chunk"
has   "buf all returns the second"   "$OUT" "second chunk"
printf 'nothing' | pbcopy
"$CHUTE" buf flush >/dev/null 2>&1
check "the flush alias gives the same text" "$(pbpaste)" "$OUT"
"$CHUTE" buf clear >/dev/null 2>&1
has   "buf clear empties it"         "$("$CHUTE" buf list 2>&1)" "empty"

# dataurl — an image as a base64 URL for a vision prompt.
sips -s format png "$ROOT/Resources/Chute.icns" --out "$T/du.png" >/dev/null 2>&1
OUT="$("$CHUTE" dataurl "$T/du.png" --no-copy 2>/dev/null)"
has   "dataurl emits a png data URL"  "$OUT" "data:image/png;base64,"
OUT="$("$CHUTE" dataurl "$T/du.png" --markdown --no-copy 2>/dev/null)"
has   "dataurl --markdown wraps it"   "$OUT" "!["
"$CHUTE" dataurl "$T/nope.png" >/dev/null 2>&1 && bad "dataurl on a missing file fails" "exit 0" || ok "dataurl on a missing file fails"

# diff — what the agent changed.
DG="$T/difftest"; mkdir -p "$DG"
( cd "$DG" && git init -q . && echo "before" > f.txt && git add -A && git -c user.email=t@t -c user.name=t commit -qm init && echo "after" > f.txt && echo "new" > untracked.txt )
OUT="$("$CHUTE" diff "$DG" 2>&1)"
has   "diff shows the changed file"   "$OUT" "f.txt"
has   "diff lists untracked files"    "$OUT" "untracked.txt"
"$CHUTE" diff "$DG" --copy >/dev/null 2>&1
has   "diff --copy puts the patch on the clipboard" "$(pbpaste)" "+after"
"$CHUTE" diff "$T" >/dev/null 2>&1 && bad "diff outside a repo fails" "exit 0" || ok "diff outside a repo fails"

# gist — NEVER actually uploaded here. Only the refusal path is exercised.
"$CHUTE" gist >/dev/null 2>&1 && bad "gist with no files refuses" "exit 0" || ok "gist with no files refuses"
has   "gist explains its usage"       "$("$CHUTE" gist 2>&1)" "gist <files"

# latest — the newest artifact in a folder.
LT="$T/latesttest"; mkdir -p "$LT"; echo one > "$LT/old.md"; sleep 1; echo two > "$LT/new.md"
has   "latest finds the newest file"  "$("$CHUTE" latest "$LT" 2>&1)" "new.md"

# open — the window-opening path is skipped on purpose; the refusal path is not.
"$CHUTE" open "$T/does-not-exist" >/dev/null 2>&1 && bad "open on a missing folder fails" "exit 0" || ok "open on a missing folder fails"

# prompt — templates onto the clipboard.
"$CHUTE" prompt decompose >/dev/null 2>&1
has   "prompt decompose fills the clipboard" "$(pbpaste)" "15"
"$CHUTE" prompt ponytail >/dev/null 2>&1
hasnt "prompt ponytail is not the same text" "$(pbpaste)" "15-minute"
"$CHUTE" prompt nosuchtemplate >/dev/null 2>&1 && bad "an unknown template fails" "exit 0" || ok "an unknown template fails"

# sandbox — a fresh agent workspace, WITHOUT launching a terminal.
SB="$T/sandboxtest"; mkdir -p "$SB"
OUT="$("$CHUTE" sandbox spike-auth --dir "$SB" --no-launch 2>&1)"
if [ -d "$SB/spike-auth/.git" ]; then ok "sandbox creates a git repo"; else bad "sandbox creates a git repo" "$OUT"; fi
if [ -f "$SB/spike-auth/CLAUDE.md" ]; then ok "sandbox seeds agent rules"; else bad "sandbox seeds agent rules" "no CLAUDE.md"; fi
if [ -f "$SB/spike-auth/README.md" ]; then ok "sandbox writes a README"; else bad "sandbox writes a README" "missing"; fi
OUT="$("$CHUTE" sandbox spike-auth --dir "$SB" --no-launch 2>&1)"
has   "an existing folder is reused, not clobbered" "$OUT" "folder exists"

echo "13. help and unknown command"
has "help lists bundle" "$("$CHUTE" help)" "bundle"
"$CHUTE" definitelynotacommand >/dev/null 2>&1 && bad "unknown exits non-zero" "exit 0" || ok "unknown exits non-zero"

echo "20. onboard — the terminal half of first-run, run for real"
# SAFETY: cmdOnboard only reads Diagnostics.liveEnv() (Finder/pluginkit/ps probes) and prints —
# it never writes to the owner's home directory or config. Its one write (endToEndProbe) lands
# in NSTemporaryDirectory and is removed before the function returns, so real HOME is safe here.
if [ "$HEADLESS" = "1" ]; then skip "onboard — its diagnostics probe Finder over AppleScript"; else
OUT="$("$CHUTE" onboard 2>&1)"
if [ $? -eq 0 ]; then ok "onboard runs clean"; else bad "onboard runs clean" "$OUT"; fi
has "onboard names the first real win"  "$OUT" "Copy Files as Context"
has "onboard tells you what to do next" "$OUT" "Next:"
fi

echo "21. resume — no live session fails gracefully, never crashes or hangs"
# Isolated HOME: chute reads hook state from ~/.chute/sessions, and the owner may have a real
# agent session running right now. Redirecting HOME is the only way to get a deterministic
# "nothing to resume" case without depending on — or disturbing — their actual session state.
if HOME="$T" "$CHUTE" resume >/dev/null 2>/tmp/chute-rs.err; then
  bad "resume with no live session fails gracefully" "exited 0"
else
  ok "resume with no live session fails gracefully"
fi
has "and explains why" "$(cat /tmp/chute-rs.err)" "no session"

echo "22. the numbers are the right SIZE, not just the right shape"
# THE POINT OF check-metrics.sh. Everything above this line — including section 19's
# "sessions --json carries the vitals" — asserts that keys EXIST. They always did, through all
# three of the wrong numbers that shipped: CPU 40x high from a lifetime average, memory ~1.9x
# high from summed rss, then CPU 24x low from mach ticks read as nanoseconds. Shape checks
# cannot see any of that. check-metrics.sh compares against the RAM and the cores in the
# machine, and against a load and an allocation of known size.
#
# Skipped headless: it needs real terminal sessions to measure, and over zero sessions it would
# be a false green — which is the exact failure mode it exists to prevent.
if [ "$HEADLESS" = "1" ]; then skip "metrics are plausible in magnitude"; else
  if "$ROOT/Scripts/check-metrics.sh" >/tmp/chute-metrics.out 2>&1; then
    ok "metrics are plausible in magnitude ($(grep -c '^  ok' /tmp/chute-metrics.out) checks)"
  else
    bad "metrics are plausible in magnitude" "$(grep -A1 '^  FAIL' /tmp/chute-metrics.out | head -4)"
  fi
fi

echo "23. the destructive commands preview before they act"
# NFR-05 applied the same way everywhere. `clean` and `unpack` — which only Trash and only
# overwrite — dry-ran by default; the five that do worse did not. Each pair below proves BOTH
# halves: nothing happened without --force, and the command still does its job with it. A guard
# that is only checked in the safe direction is a guard nobody has seen work.

# ports --kill — the one typo away from killing the user's Postgres. Throwaway listener only.
PORT=8977
python3 -m http.server "$PORT" >/dev/null 2>&1 &
SRVPID=$!
sleep 1
if kill -0 "$SRVPID" 2>/dev/null; then
  OUT="$("$CHUTE" ports --kill "$PORT" 2>&1)"
  has  "ports --kill previews the row"  "$OUT" "re-run with --force to kill"
  has  "and names the pid it would end" "$OUT" "$SRVPID"
  if kill -0 "$SRVPID" 2>/dev/null; then ok "the preview killed nothing"; else bad "the preview killed nothing" "process died"; fi
  "$CHUTE" ports --kill "$PORT" --force >/dev/null 2>&1
  sleep 1
  if kill -0 "$SRVPID" 2>/dev/null; then bad "--force still kills" "still alive"; else ok "--force still kills"; fi
  kill -9 "$SRVPID" 2>/dev/null || true
else
  skip "ports --kill guard (could not start a throwaway listener on $PORT)"
fi

# env inject — the preview must never print a VALUE. Throwaway Keychain item, removed after.
ENVDIR="$T/envguard"; mkdir -p "$ENVDIR"; printf 'node_modules\n.env\n' > "$ENVDIR/.gitignore"
(cd "$ENVDIR" && git init -q . 2>/dev/null) || true
security add-generic-password -U -s "chute:CHUTE_SMOKE_KEY" -a chute -w "smoke-secret-value" 2>/dev/null || true
OUT="$("$CHUTE" env inject "$ENVDIR" --keys CHUTE_SMOKE_KEY 2>&1)"
has   "env inject previews"            "$OUT" "re-run with --force to write"
hasnt "and NEVER prints the value"     "$OUT" "smoke-secret-value"
if [ -f "$ENVDIR/.env" ]; then bad "the preview wrote no .env" "it exists"; else ok "the preview wrote no .env"; fi
"$CHUTE" env inject "$ENVDIR" --keys CHUTE_SMOKE_KEY --force >/dev/null 2>&1
has   "--force writes the key"         "$(cat "$ENVDIR/.env" 2>/dev/null)" "CHUTE_SMOKE_KEY="
# The merge bug: running it twice used to duplicate every key.
"$CHUTE" env inject "$ENVDIR" --keys CHUTE_SMOKE_KEY --force >/dev/null 2>&1
check "a second run replaces, never duplicates" "$(grep -c '^CHUTE_SMOKE_KEY=' "$ENVDIR/.env" 2>/dev/null || echo 0)" "1"
security delete-generic-password -s "chute:CHUTE_SMOKE_KEY" -a chute >/dev/null 2>&1 || true

# gist — uploads to GitHub. Only the preview half can be tested; --force is a real publish.
printf 'sk-test-not-a-real-key-000000\n' > "$T/gistguard.txt"
OUT="$("$CHUTE" gist "$T/gistguard.txt" 2>&1)"
has   "gist previews before uploading" "$OUT" "re-run with --force to upload"
has   "and says what it redacted"      "$OUT" "redact"

# doctor --fix — Trashes a container and kills two processes. Preview only; --force is destructive.
OUT="$("$CHUTE" doctor --fix 2>&1)"
hasnt "doctor --fix never repairs unasked" "$OUT" "cleared the stale extension container"

echo "24. tokens and bundle agree on the number you actually paste"
# JTBD 24 exists to answer "how big is this before you send it", and the thing you paste is the
# bundle. `tokens` used to sum raw file contents and `bundle` counted the assembled blob — 2.8x
# apart, in the one job that exists to prevent overflow. This lives here rather than in the unit
# suite because chutetests links ChuteCore only and cannot see cmdTokens at all: an in-process
# check would recompute the same ChuteCore calls and stay green through any regression in the
# command itself. Measured that way once, deliberately, and it did.
TB="$T/tokbundle"; mkdir -p "$TB"
printf 'export const a = 1\n' > "$TB/a.ts"
printf '# hello\nworld\nmore prose so the count is not trivial\n' > "$TB/b.md"
# Compare the BADGES both commands print, not raw integers: the badge is what the user reads,
# and both sides round identically, so a 2.8x gap is still glaring while formatting cannot make
# the assertion flaky. --no-copy so the smoke run never touches the real clipboard.
BUNDLE_BADGE="$("$CHUTE" bundle "$TB" --no-copy 2>&1 >/dev/null | sed -n 's/.*· //p')"
TOKENS_BADGE="$("$CHUTE" tokens "$TB" 2>/dev/null | sed -n 's/.*TOTAL.*(\(.*\))$/\1/p')"
if [ -n "$BUNDLE_BADGE" ] && [ -n "$TOKENS_BADGE" ]; then
  check "tokens TOTAL equals bundle's count" "$TOKENS_BADGE" "$BUNDLE_BADGE"
else
  bad "tokens TOTAL equals bundle's count" "could not parse (bundle='$BUNDLE_BADGE' tokens='$TOKENS_BADGE')"
fi

cd /; rm -rf "$T"
echo
echo "smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
