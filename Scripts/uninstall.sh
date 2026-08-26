#!/usr/bin/env bash
set -euo pipefail
pkill -x ChuteApp 2>/dev/null || true
rm -rf "$HOME/Applications/Chute.app"
rm -f "$HOME/.local/bin/chute"
rm -rf "$HOME/.chute"
find "$HOME/Library/Services" -maxdepth 1 -name "Chute*" -exec rm -rf {} + 2>/dev/null || true
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
echo "Chute removed."
