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

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "$HOME/Applications/Chute.app"
/System/Library/CoreServices/pbs -flush 2>/dev/null || true

"$ROOT/Scripts/install-quickactions.sh"

pkill -x ChuteApp 2>/dev/null || true
open "$HOME/Applications/Chute.app"

cat <<EOF

Chute installed.

  app   $HOME/Applications/Chute.app   (menu bar ⤓, hotkey ⌥⌘N)
  cli   $HOME/.local/bin/chute         (add ~/.local/bin to PATH if needed)

Finder right-click → Quick Actions ▸ Chute – …
If the entries do not appear, toggle them on in:
  System Settings → Keyboard → Keyboard Shortcuts → Services → Files and Folders

First use of the hotkey or a Finder action will ask for Automation permission. That prompt is
macOS asking whether Chute may read your Finder selection. Nothing leaves your machine.
EOF
