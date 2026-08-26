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

# THE FINDER MENU'S ONE FAILURE MODE, made loud.
# A sandboxed extension's container ACL pins the exact code identity that created it. An ad-hoc
# signature is a new identity on every build, so after a rebuild macOS refuses to start the
# extension — "code identity <cdhash …> not in ACL for container" — and the Chute menu simply
# stops appearing, with nothing in the UI to say why.
CONTAINER="$HOME/Library/Containers/dev.valuev.chute.finder"
CDHASH="$(codesign -dvvv "$HOME/Applications/Chute.app/Contents/PlugIns/ChuteFinder.appex" 2>&1 \
          | awk -F= '/^CDHash=/{print $2}')"
if [ -d "$CONTAINER" ] && ! grep -qa "$CDHASH" "$CONTAINER/.com.apple.containermanagerd.metadata.plist" 2>/dev/null; then
  rm -rf "$CONTAINER" 2>/dev/null || true
  if [ -d "$CONTAINER" ]; then
    echo
    echo "⚠️  The Finder menu will NOT appear until this stale sandbox container is removed:"
    echo "      sudo rm -rf $CONTAINER"
    echo "    Then run this installer again. To stop it happening on every rebuild:"
    echo "      $ROOT/Scripts/sign-identity.sh"
    echo
  fi
fi

killall Finder 2>/dev/null || true

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
