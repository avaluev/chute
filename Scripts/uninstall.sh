#!/usr/bin/env bash
set -euo pipefail
# $HOME MUST BE SANE BEFORE ANY rm -rf. `set -u` catches an UNSET variable; it does nothing for
# one set to the empty string, and a sanitised environment hands exactly that — a .pkg
# postinstall, a LaunchAgent, `env -i`, some Automator actions. With HOME="" the line below
# collapses to `rm -rf /Applications/Chute.app`: the very path the DMG tells customers to drag
# Chute into, deleted system-wide, on a machine where the per-user copy never existed.
[ -n "${HOME:-}" ] && [ "$HOME" != "/" ] && [ -d "$HOME" ] \
  || { echo "$(basename "$0"): \$HOME is not usable ('${HOME:-}') — refusing to touch anything" >&2; exit 1; }

pkill -x ChuteApp 2>/dev/null || true
# Legacy: Chute <=0.1.0 wired hooks into ~/.claude/settings.json. Current Chute never writes
# there, but an uninstall must not leave dead hooks behind either. `hooks uninstall` removes
# exactly the chute-marked blocks (backup first) and is a byte-for-byte no-op when none exist.
# It must run while the CLI still exists — the binary is inside the app bundle removed below.
#
# TWO FIXES, 2026-08-29. `--force`: `hooks uninstall` previews by default now, like the other
# destructive commands, so this line removed nothing and then deleted the only binary that could
# — leaving legacy hook blocks in a file with no tool left to clean them. And the binary is
# resolved rather than assumed: install.sh stopped creating ~/.local/bin/chute (Homebrew owns the
# CLI), so on any recent install this pointed at nothing and the `|| true` hid it. The copy inside
# the bundle is the one that is certainly present at uninstall time.
for CLI in "$HOME/Applications/Chute.app/Contents/MacOS/chute" \
           "/opt/homebrew/bin/chute" "/usr/local/bin/chute" "$HOME/.local/bin/chute"; do
  [ -x "$CLI" ] || continue
  "$CLI" hooks uninstall --force 2>/dev/null || true
  break
done
pluginkit -r "$HOME/Applications/Chute.app/Contents/PlugIns/ChuteFinder.appex" 2>/dev/null || true
rm -rf "$HOME/Applications/Chute.app"
rm -f "$HOME/.local/bin/chute"
rm -rf "$HOME/.chute"
# Legacy: v0.1 installed Automator Quick Actions. Removed here so old installs clean up.
find "$HOME/Library/Services" -maxdepth 1 -name "Chute*" -exec rm -rf {} + 2>/dev/null || true
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
echo "Chute removed."
