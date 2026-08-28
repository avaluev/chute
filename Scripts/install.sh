#!/usr/bin/env bash
# Installs Chute for the current user: app in ~/Applications. The CLI is Homebrew's job,
# Finder right-click entries registered with the Services system.
set -euo pipefail
# $HOME MUST BE SANE BEFORE ANY rm -rf. `set -u` catches an UNSET variable; it does nothing for
# one set to the empty string, and a sanitised environment hands exactly that — a .pkg
# postinstall, a LaunchAgent, `env -i`, some Automator actions. With HOME="" the line below
# collapses to `rm -rf /Applications/Chute.app`: the very path the DMG tells customers to drag
# Chute into, deleted system-wide, on a machine where the per-user copy never existed.
[ -n "${HOME:-}" ] && [ "$HOME" != "/" ] && [ -d "$HOME" ] \
  || { echo "$(basename "$0"): \$HOME is not usable ('${HOME:-}') — refusing to touch anything" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/dist/Chute.app"
[ -d "$APP" ] || "$ROOT/Scripts/build-app.sh"

mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/Chute.app"
cp -R "$APP" "$HOME/Applications/Chute.app"
# CLEAN UP THE ONE WE USED TO MAKE. Every install before this one wrote ~/.local/bin/chute, and
# leaving it means the collision outlives the fix on every existing machine. Removed only when it
# is a SYMLINK POINTING INTO Chute.app — ours, unambiguously. A real file there, or a link to
# anywhere else, is the user's and is never touched: an installer that deletes something it did
# not create is a worse bug than the one it is cleaning up.
LEGACY="$HOME/.local/bin/chute"
if [ -L "$LEGACY" ] && case "$(readlink "$LEGACY")" in */Chute.app/*) true ;; *) false ;; esac; then
  rm -f "$LEGACY"
  echo "removed the old ~/.local/bin/chute symlink — Homebrew owns the CLI now"
fi

# NO NEW CLI SYMLINK. Homebrew owns the command-line tool — `brew install avaluev/tap/chute`, which
# is what the site and the README advertise. Writing one here too put `chute` on PATH twice at
# the same version, and the app then reported that collision as a fault and offered to recreate
# it. The app keeps its own copy inside the bundle for its own use and writes nothing to PATH.

# You built this app; it was never downloaded. Clearing these stops macOS treating each rebuild as
# a suspicious new arrival.
xattr -dr com.apple.quarantine "$HOME/Applications/Chute.app" 2>/dev/null || true
xattr -dr com.apple.provenance "$HOME/Applications/Chute.app" 2>/dev/null || true

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "$HOME/Applications/Chute.app"
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
pluginkit -a "$HOME/Applications/Chute.app/Contents/PlugIns/ChuteFinder.appex" 2>/dev/null || true

pkill -x ChuteApp 2>/dev/null || true
# LaunchServices returns -600 if the old process has not finished dying yet. One retry covers it.
sleep 1
open "$HOME/Applications/Chute.app" 2>/dev/null || { sleep 2; open "$HOME/Applications/Chute.app"; }

# Registration happens when the host app is LAUNCHED (measured: pluginkit -a and lsregister do
# not do it), so this runs after `open`. The flag has three states; blank is registered-but-off.
pluginkit -e use -i dev.valuev.chute.finder 2>/dev/null || true

killall Finder 2>/dev/null || true

# THE FINDER MENU'S ONE FAILURE MODE, fixed automatically.
#
# A sandboxed extension's container pins the exact code identity that created it. An ad-hoc
# signature is a new identity on every build, so after a rebuild macOS refuses to start the
# extension:  (AppSandbox) code identity <cdhash …> not in ACL for container …
# Nothing surfaces that. pluginkit still says registered and enabled, the process still launches,
# and the Chute menu is simply absent.
#
# The extension writes a marker when it loads, so "did this build ever run?" is answerable. If it
# did not, the stale container goes to the Trash — via Finder, which needs no password — and we
# try once more.
APPEX_BIN="$HOME/Applications/Chute.app/Contents/PlugIns/ChuteFinder.appex/Contents/MacOS/ChuteFinder"
MARKER="$HOME/.chute/extension-loaded.txt"
CONTAINER="$HOME/Library/Containers/dev.valuev.chute.finder"

extension_started() { [ -f "$MARKER" ] && [ "$MARKER" -nt "$APPEX_BIN" ]; }
wait_for_extension() { for _ in 1 2 3 4 5 6 7 8 9 10; do extension_started && return 0; sleep 1; done; return 1; }

if ! wait_for_extension; then
  echo "the Finder extension did not start — repairing"
  # The exact sequence that was measured to work, in this order:
  #   1. drop the stale container (its ACL names the previous build's code identity)
  #   2. DEREGISTER the extension — after a container change macOS will not re-create one for a
  #      registration it already holds, so the menu stays dead until the plug-in is re-added
  #   3. re-register by launching the host app, which is what actually registers an appex
  #   4. restart Finder so it picks the new one up
  osascript -e "tell application \"Finder\" to delete POSIX file \"$CONTAINER\"" >/dev/null 2>&1 || true
  pluginkit -r "$HOME/Applications/Chute.app/Contents/PlugIns/ChuteFinder.appex" 2>/dev/null || true
  pkill -x ChuteApp 2>/dev/null || true
  sleep 1
  open "$HOME/Applications/Chute.app"
  sleep 2
  pluginkit -a "$HOME/Applications/Chute.app/Contents/PlugIns/ChuteFinder.appex" 2>/dev/null || true
  pluginkit -e use -i dev.valuev.chute.finder 2>/dev/null || true
  killall Finder 2>/dev/null || true
  if wait_for_extension; then
    echo "fixed — the Chute menu is back"
  else
    echo
    echo "   The Finder right-click menu is not available yet."
    echo
    echo "   macOS keeps a private folder for the extension, and it is still pinned to an older"
    echo "   copy of Chute. This clears it and restarts Finder — no password needed:"
    echo
    # --force since 2026-08-29: `doctor --fix` previews by default like the other destructive
    # commands, and the sentence above promises this CLEARS the folder. An instruction whose
    # command does not do what the sentence says is worse than no instruction.
    echo "      \"$HOME/Applications/Chute.app/Contents/MacOS/chute\" doctor --fix --force"
    echo
    echo "   Everything else is installed and working."
    echo
    # The developer's version of the same advice, printed only when this is a source tree. A
    # customer installing from the DMG has no Scripts/ directory and must never be handed
    # `sudo rm -rf` for a path they cannot check — that is how someone deletes the wrong thing
    # while trying to fix an app.
    if [ -f "$ROOT/Scripts/sign-identity.sh" ]; then
      echo "   (dev) stale container: $CONTAINER"
      echo "   (dev) $ROOT/Scripts/sign-identity.sh stops this recurring on every rebuild"
      echo
    fi
  fi
fi



cat <<EOF

Chute installed.

  app   $HOME/Applications/Chute.app   (menu bar ⤓, hotkey ⌥⌘N)
  cli   brew install avaluev/tap/chute  (free, MIT, optional — the app needs no PATH)

Finder right-click → Chute actions, inline in the context menu …

  check chute doctor    (what is not wired up yet, and how to fix it)
  agents chute sessions  (every terminal session, grouped by state)

The menu bar badge only counts BLOCKED and WAITING sessions once Claude Code hooks are wired.
Chute never edits ~/.claude/settings.json — wiring them is done by your own hand, if you want it:

  chute hooks status     (read-only: what is wired now)
  chute hooks snippet    (prints the JSON for you to paste in yourself)

First use of the hotkey or a Finder action will ask for Automation permission. That prompt is
macOS asking whether Chute may read your Finder selection. Nothing leaves your machine.
EOF
