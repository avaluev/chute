#!/usr/bin/env bash
# Installs Chute for the current user: app in ~/Applications, CLI in ~/.local/bin,
# Finder right-click entries registered with the Services system.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/dist/Chute.app"
[ -d "$APP" ] || "$ROOT/Scripts/build-app.sh"

mkdir -p "$HOME/Applications" "$HOME/.local/bin"
rm -rf "$HOME/Applications/Chute.app"
cp -R "$APP" "$HOME/Applications/Chute.app"
ln -sf "$HOME/Applications/Chute.app/Contents/MacOS/chute" "$HOME/.local/bin/chute"

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
  echo "the Finder extension did not start — clearing its stale sandbox container"
  osascript -e "tell application \"Finder\" to delete POSIX file \"$CONTAINER\"" >/dev/null 2>&1 || true
  killall Finder 2>/dev/null || true
  if wait_for_extension; then
    echo "fixed — the Chute menu is back"
  else
    echo
    echo "⚠️  The Finder extension still will not start. Two things to try, in order:"
    echo "      sudo rm -rf $CONTAINER   (then run this installer again)"
    echo "      $ROOT/Scripts/sign-identity.sh   (stops it recurring on every rebuild)"
    echo
  fi
fi



cat <<EOF

Chute installed.

  app   $HOME/Applications/Chute.app   (menu bar ⤓, hotkey ⌥⌘N)
  cli   $HOME/.local/bin/chute         (add ~/.local/bin to PATH if needed)

Finder right-click → Chute ▸ …

  check $HOME/.local/bin/chute doctor    (what is not wired up yet, and how to fix it)
  agents $HOME/.local/bin/chute sessions  (every terminal session, grouped by state)

The menu bar badge only counts BLOCKED and WAITING sessions once Claude Code hooks are wired:

  $HOME/.local/bin/chute hooks status     (what is wired now)
  $HOME/.local/bin/chute hooks install    (appends to ~/.claude/settings.json, backs it up first)

First use of the hotkey or a Finder action will ask for Automation permission. That prompt is
macOS asking whether Chute may read your Finder selection. Nothing leaves your machine.
EOF
