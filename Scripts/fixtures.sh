#!/usr/bin/env bash
# Builds a deliberately hostile directory tree for exercising every Finder action.
#
# Everything in here is a real thing a real Mac allows and a real developer has. A filename may
# contain a newline, a quote, a leading dash, a NUL-free emoji, or 255 bytes of Cyrillic. A repo
# has symlink loops, unreadable files, a 10 MB log and a venv with 40,000 files in it. Code that
# only ever saw `src/a.ts` has not been tested; it has been demonstrated.
#
#   ./Scripts/fixtures.sh [dir]     default: /tmp/chute-fixtures
#   ./Scripts/fixtures.sh --clean [dir]
#
# IDEMPOTENT: it removes and rebuilds. Which is exactly why it refuses to run anywhere it was not
# explicitly pointed, and why the guard below is not decoration — this script's whole job is to
# `rm -rf` a directory, and a typo in $1 is a very bad afternoon.
set -uo pipefail

CLEAN=0
[ "${1:-}" = "--clean" ] && { CLEAN=1; shift; }
ROOT="${1:-/tmp/chute-fixtures}"

# A fixture root must be an absolute path, must not be the filesystem root, must not be $HOME, and
# must live under a temp directory or be named for what it is. Anything else is refused.
case "$ROOT" in
  /) echo "fixtures: refusing to touch /" >&2; exit 1;;
  "$HOME"|"$HOME"/) echo "fixtures: refusing to touch \$HOME" >&2; exit 1;;
  /tmp/*|/private/tmp/*|/var/folders/*|*/chute-fixtures*) ;;
  *) echo "fixtures: '$ROOT' is not under a temp dir and is not named chute-fixtures — refusing" >&2; exit 1;;
esac
[ "${ROOT#/}" = "$ROOT" ] && { echo "fixtures: need an absolute path" >&2; exit 1; }

# Unreadable dirs from a previous run block rm; loosen before removing.
[ -d "$ROOT" ] && chmod -R u+rwX "$ROOT" 2>/dev/null
rm -rf "$ROOT"
[ "$CLEAN" = "1" ] && { echo "fixtures: removed $ROOT"; exit 0; }
mkdir -p "$ROOT"

say() { printf '  %s\n' "$1"; }

# ── 1. NAMES macOS ALLOWS AND CODE FORGETS ──────────────────────────────────────────────────
N="$ROOT/names"; mkdir -p "$N"
printf 'space\n'        > "$N/a file with spaces.txt"
printf 'dquote\n'       > "$N/say \"hello\".txt"          # ends an AppleScript literal early
printf 'squote\n'       > "$N/it's here.txt"              # ends a shell single-quote early
printf 'backslash\n'    > "$N/back\\slash.txt"            # escapes the escape
printf 'newline\n'      > "$N/two"$'\n'"lines.txt"        # LEGAL on macOS; breaks any line-based protocol
printf 'dash\n'         > "$N/-rf.txt"                    # reads as a flag to anything not using --
printf 'ddash\n'        > "$N/--force.txt"
printf 'dollar\n'       > "$N/\$(whoami).txt"             # command substitution if ever eval'd
printf 'backtick\n'     > "$N/\`id\`.txt"
printf 'semicolon\n'    > "$N/a;b.txt"
printf 'glob\n'         > "$N/star*.txt"
printf 'bracket\n'      > "$N/[0-9].txt"
printf 'question\n'     > "$N/what?.txt"
printf 'pipe\n'         > "$N/a|b.txt"
printf 'amp\n'          > "$N/a&b.txt"
printf 'newlinetab\n'   > "$N/tab"$'\t'"ped.txt"
printf 'emoji\n'        > "$N/🚀 rocket 🎉.txt"
printf 'cyrillic\n'     > "$N/Файл_Проекта.txt"
printf 'cjk\n'          > "$N/日本語のファイル.txt"
printf 'rtl\n'          > "$N/عربى.txt"
# NFC vs NFD: "é" as one codepoint and as e + U+0301. APFS stores both; they LOOK identical.
printf 'nfc\n'          > "$N/café-nfc.txt"
printf 'nfd\n'          > "$N/cafe"$'́'"-nfd.txt"
printf 'dots\n'         > "$N/...txt"
printf 'trailingspace\n' > "$N/trailing .txt"
printf 'longname\n'     > "$N/$(printf 'x%.0s' $(seq 1 250)).txt"   # near the 255-byte limit
say "names/ — 25 hostile filenames"

# ── 2. CONTENT ──────────────────────────────────────────────────────────────────────────────
C="$ROOT/content"; mkdir -p "$C"
: > "$C/zero-byte.txt"
printf 'no trailing newline' > "$C/no-eol.txt"
printf 'line1\r\nline2\r\n'  > "$C/crlf.txt"
# The XML sentinel. `bundle` wraps files in <file path="…">…</file>; a file CONTAINING </file>
# can close the wrapper early and corrupt everything after it.
printf 'before\n</file>\nafter\n' > "$C/xml-escape-hatch.txt"
printf 'attr " and & and < \n'    > "$C/xml-attr-chars.txt"
head -c 4096 /dev/urandom > "$C/binary.bin"                       # NUL bytes ⇒ must be SKIPPED
printf 'text\0with-nul\n'  > "$C/nul-in-text.txt"                 # binary by the NUL rule
python3 -c "import sys; sys.stdout.buffer.write(b'valid\n\xff\xfe invalid utf8\n')" > "$C/bad-utf8.txt"
python3 -c "print('x'*1024*1024*10)" > "$C/ten-megabytes.txt"     # 10 MB of one line
printf '%s\n' "$(python3 -c "print('a'*100000)")" > "$C/one-very-long-line.txt"
say "content/ — 10 files incl. binary, bad UTF-8, 10 MB, and a </file> sentinel"

# ── 3. STRUCTURE ────────────────────────────────────────────────────────────────────────────
S="$ROOT/structure"; mkdir -p "$S/empty-dir"
DEEP="$S/deep"; mkdir -p "$DEEP"
P="$DEEP"; for i in $(seq 1 30); do P="$P/level$i"; mkdir -p "$P"; done
printf 'bottom\n' > "$P/at-the-bottom.txt"
mkdir -p "$S/many"; for i in $(seq 1 500); do printf 'f%s\n' "$i" > "$S/many/file$i.txt"; done
say "structure/ — empty dir, 30 levels deep, 500 files in one folder"

# ── 4. LINKS ────────────────────────────────────────────────────────────────────────────────
L="$ROOT/links"; mkdir -p "$L/real"
printf 'target\n' > "$L/real/target.txt"
ln -s real/target.txt        "$L/link-to-file"
ln -s real                   "$L/link-to-dir"
ln -s /nowhere/at/all        "$L/broken-link"
ln -s ..                     "$L/real/loop"            # A REAL LOOP: links/real/loop -> links.
                                                       # The first version of this line was `ln -s ../links`,
                                                       # which from inside real/ resolves to links/links and does
                                                       # not exist — a broken link masquerading as a loop test.
                                                       # Verified: `readlink -f` on this one returns links/.
ln "$L/real/target.txt"      "$L/hardlink.txt"
ln -s "/etc/passwd"          "$L/link-outside.txt"      # must never be followed out of the tree
say "links/ — file, dir, broken, LOOP, hardlink, and one pointing outside"

# ── 5. WHAT A REAL REPO CARRIES, i.e. what must be EXCLUDED ─────────────────────────────────
R="$ROOT/repo"; mkdir -p "$R/src" "$R/node_modules/left-pad" "$R/__pycache__" "$R/venv/lib" \
                        "$R/.git/objects" "$R/build" "$R/.github/workflows" "$R/dist"
printf 'export const a = 1\n' > "$R/src/a.ts"
printf 'export const b = 2\n' > "$R/src/b.ts"
printf '# Readme\n'           > "$R/README.md"
printf 'junk\n'               > "$R/node_modules/left-pad/index.js"
printf 'junk\n'               > "$R/__pycache__/mod.cpython-310.pyc"
printf 'junk\n'               > "$R/venv/lib/site.py"
printf 'junk\n'               > "$R/.git/objects/deadbeef"
printf 'junk\n'               > "$R/build/out.o"
printf 'junk\n'               > "$R/dist/bundle.js"
printf 'name: ci\n'           > "$R/.github/workflows/ci.yml"     # the ONE dotdir that is kept
printf 'hidden\n'             > "$R/.env"
printf 'hidden\n'             > "$R/.DS_Store"
say "repo/ — node_modules, __pycache__, venv, .git, build, dist + .github (kept) and .env"

# ── 6. PERMISSIONS ──────────────────────────────────────────────────────────────────────────
# Last, because chmod 000 makes the tree awkward to walk — including for this script.
M="$ROOT/permissions"; mkdir -p "$M/unreadable-dir"
printf 'secret\n' > "$M/unreadable-file.txt"; chmod 000 "$M/unreadable-file.txt"
printf 'inside\n' > "$M/unreadable-dir/inside.txt"; chmod 000 "$M/unreadable-dir"
printf 'ok\n'     > "$M/readable.txt"
say "permissions/ — an unreadable file and an unreadable directory"

echo
echo "fixtures: $ROOT"
echo "  $(find "$ROOT" -type f 2>/dev/null | wc -l | tr -d ' ') files, $(find "$ROOT" -type d 2>/dev/null | wc -l | tr -d ' ') dirs, $(du -sh "$ROOT" 2>/dev/null | cut -f1) on disk"
echo "  clean up with: $0 --clean $ROOT"
