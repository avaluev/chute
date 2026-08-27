#!/usr/bin/env bash
set -euo pipefail
pkill -x ChuteApp 2>/dev/null || true
# Legacy: Chute <=0.1.0 wired hooks into ~/.claude/settings.json. Current Chute never writes
# there, but an uninstall must not leave dead hooks behind either. `hooks uninstall` removes
# exactly the chute-marked blocks (backup first) and is a byte-for-byte no-op when none exist.
# It must run while the CLI still exists — the binary is inside the app bundle removed below.
"$HOME/.local/bin/chute" hooks uninstall 2>/dev/null || true
pluginkit -r "$HOME/Applications/Chute.app/Contents/PlugIns/ChuteFinder.appex" 2>/dev/null || true
rm -rf "$HOME/Applications/Chute.app"
rm -f "$HOME/.local/bin/chute"
rm -rf "$HOME/.chute"
# Legacy: v0.1 installed Automator Quick Actions. Removed here so old installs clean up.
find "$HOME/Library/Services" -maxdepth 1 -name "Chute*" -exec rm -rf {} + 2>/dev/null || true
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
echo "Chute removed."
