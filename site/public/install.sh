#!/usr/bin/env bash
# curl -fsSL https://chutedev.com/install.sh | sh
#
# Clones Chute, builds it, and installs the app. Everything it does is in this file and in the
# two scripts it calls — nothing is downloaded pre-built, which is the entire point: a binary
# your own compiler produced was never downloaded, so macOS never attaches a quarantine flag to
# it and Gatekeeper never runs. That is how a project with no Apple Developer ID ships something
# a stranger can actually open.
#
# You are piping a stranger's script into a shell. Read it first — it is 40 lines, it is served
# from the same repo as the product, and if you would rather not, the Homebrew formula does the
# same thing under `brew install avaluev/tap/chute`.
set -euo pipefail

SRC="${CHUTE_SRC:-$HOME/.chute/src}"
REPO="${CHUTE_REPO:-https://github.com/avaluev/chute}"

command -v git >/dev/null 2>&1 || {
  echo "chute: git is required. Install the Command Line Tools: xcode-select --install" >&2
  exit 1
}
command -v swift >/dev/null 2>&1 || {
  echo "chute: the Swift toolchain is required. Install the Command Line Tools:" >&2
  echo "  xcode-select --install" >&2
  exit 1
}

# macOS 13 is the floor declared in Package.swift. Fail here with a sentence rather than 200
# lines of compiler output forty seconds from now.
MAJOR="$(sw_vers -productVersion | cut -d. -f1)"
[ "${MAJOR:-0}" -ge 13 ] || {
  echo "chute: needs macOS 13 (Ventura) or later; this is $(sw_vers -productVersion)" >&2
  exit 1
}

if [ -d "$SRC/.git" ]; then
  echo "→ updating $SRC"
  git -C "$SRC" pull --ff-only
else
  echo "→ cloning into $SRC"
  mkdir -p "$(dirname "$SRC")"
  git clone --depth 1 "$REPO" "$SRC"
fi

echo "→ building (about a minute, no dependencies to fetch)"
"$SRC/Scripts/build-app.sh"

echo "→ installing"
"$SRC/Scripts/install.sh"

cat <<'EOF'

The `chute` command lives inside the app bundle. To put it on your PATH, either:

    brew install avaluev/tap/chute

or link it yourself:

    ln -sf ~/Applications/Chute.app/Contents/MacOS/chute /usr/local/bin/chute

Then wire your agent's hooks so Chute can see which session needs you:

    chute hooks snippet
EOF
