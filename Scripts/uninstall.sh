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
# $CHUTE_APP_DIR SCOPES THIS SCRIPT TO ONE FOLDER — and is what makes it testable at all.
# `install.sh` has honoured it since it was written; this script did not, so the only way to
# exercise uninstall was against the founder's real install. An agent verifying every install
# path on 2026-09-09 correctly REFUSED to run it for that reason and reported the gap instead.
# A test you cannot run safely is a test nobody runs.
#
# Scoped mode touches that folder and nothing else: no ~/.chute, no ~/.local/bin, no hook
# cleanup, no Services sweep. A scratch install never created any of them, and deleting a real
# one while testing is precisely the accident this is meant to prevent.
SCOPED=0
if [ -n "${CHUTE_APP_DIR:-}" ]; then
  SCOPED=1
  # Feeds `rm -rf`, so it is asserted rather than assumed — the same guard install.sh applies.
  case "$CHUTE_APP_DIR" in
    /) echo "$(basename "$0"): refusing to uninstall from \"/\"" >&2; exit 1 ;;
    /*) : ;;
    *) echo "$(basename "$0"): refusing to uninstall from \"$CHUTE_APP_DIR\" — not an absolute path" >&2; exit 1 ;;
  esac
  set -- "$CHUTE_APP_DIR"
else
  set -- "$HOME/Applications" "/Applications"
fi
# NOT IN SCOPED MODE. `chute hooks uninstall` rewrites the user's REAL ~/.claude/settings.json,
# and it would find a real install to do it with even when this run is meant to touch only a
# scratch folder — the loop searches absolute paths, not $CHUTE_APP_DIR.
if [ "$SCOPED" -eq 0 ]; then
  for CLI in "$HOME/Applications/Chute.app/Contents/MacOS/chute" \
             "/Applications/Chute.app/Contents/MacOS/chute" \
             "/opt/homebrew/bin/chute" "/usr/local/bin/chute" "$HOME/.local/bin/chute"; do
    [ -x "$CLI" ] || continue
    "$CLI" hooks uninstall --force 2>/dev/null || true
    break
  done
fi
# BOTH LOCATIONS. `install.sh` puts the app in ~/Applications, but the DMG ships a symlink to
# /Applications and tells the customer to drag it there — so the only install path a STRANGER
# ever takes was the one path this script did not clean. It removed nothing, said "Chute removed."
# and left a registered Finder extension behind.
#
# The literal "/Applications/Chute.app" is safe where "$HOME/Applications/Chute.app" needed a
# guard: there is no variable in it to collapse to the empty string.
for APPDIR in "$@"; do
  [ -d "$APPDIR/Chute.app" ] || continue
  pluginkit -r "$APPDIR/Chute.app/Contents/PlugIns/ChuteFinder.appex" 2>/dev/null || true
  rm -rf "$APPDIR/Chute.app" 2>/dev/null \
    || echo "$(basename "$0"): could not remove $APPDIR/Chute.app — try: sudo rm -rf '$APPDIR/Chute.app'" >&2
done
if [ "$SCOPED" -eq 0 ]; then
  rm -f "$HOME/.local/bin/chute"
  rm -rf "$HOME/.chute"
  # Legacy: v0.1 installed Automator Quick Actions. Removed here so old installs clean up.
  find "$HOME/Library/Services" -maxdepth 1 -name "Chute*" -exec rm -rf {} + 2>/dev/null || true
  /System/Library/CoreServices/pbs -flush 2>/dev/null || true
  echo "Chute removed."
else
  echo "Chute removed from $CHUTE_APP_DIR (scoped — nothing outside it was touched)."
fi
