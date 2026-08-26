#!/usr/bin/env bash
# Generates Finder Quick Actions (Automator .workflow bundles) into ~/Library/Services.
# These appear under right-click → Quick Actions ▸ — the submenu Finder actually shows.
set -euo pipefail
DEST="$HOME/Library/Services"
CH="$HOME/Applications/Chute.app/Contents/MacOS/chute"
mkdir -p "$DEST"

# $1 menu title · $2 UTI (public.item | public.folder) · $3 shell body ("$@" = selection)
make_action() {
  local title="$1" uti="$2" body="$3"
  local dir="$DEST/$title.workflow"
  rm -rf "$dir"
  mkdir -p "$dir/Contents/Resources"

  cat > "$dir/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$title</string>
  <key>CFBundleIdentifier</key><string>dev.valuev.chute.$(echo "$title" | tr -cd '[:alnum:]')</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>NSServices</key>
  <array>
    <dict>
      <key>NSBackgroundColorName</key><string>background</string>
      <key>NSIconName</key><string>NSActionTemplate</string>
      <key>NSMenuItem</key><dict><key>default</key><string>$title</string></dict>
      <key>NSMessage</key><string>runWorkflowAsService</string>
      <key>NSRequiredContext</key>
      <dict><key>NSApplicationIdentifier</key><string>com.apple.finder</string></dict>
      <key>NSSendFileTypes</key><array><string>$uti</string></array>
    </dict>
  </array>
</dict>
</plist>
PLIST

  # Multi-select insurance: if only one item arrives as an argument, ask Finder for the live
  # selection instead. Correct whether or not the service passes the whole selection.
  local preamble=""
  if [[ "$body" == *'"$@"'* ]]; then
    preamble='if [ "$#" -le 1 ]; then
  SEL=$(osascript -e '"'"'tell application "Finder"
    set out to ""
    repeat with i in (get selection)
      set out to out & POSIX path of (i as alias) & linefeed
    end repeat
    return out
  end tell'"'"' 2>/dev/null)
  if [ -n "$SEL" ]; then
    set --
    while IFS= read -r L; do [ -n "$L" ] && set -- "$@" "$L"; done <<< "$SEL"
  fi
fi
'
  fi

  # Notify on completion — a Quick Action is otherwise silent, which reads as "nothing happened".
  local script="CH=\"$CH\"
$preamble
MSG=\$(\"\$CH\" $body 2>&1 >/dev/null)
[ -z \"\$MSG\" ] && MSG=\"done\"
MSG=\$(printf '%s' \"\$MSG\" | tr -d '\"' | tail -1)
osascript -e \"display notification \\\"\$MSG\\\" with title \\\"Chute\\\"\""

  python3 - "$dir/Contents/document.wflow" "$script" <<'PY'
import plistlib, sys, uuid
out, script = sys.argv[1], sys.argv[2]
doc = {
    "AMApplicationBuild": "523",
    "AMApplicationVersion": "2.10",
    "AMDocumentVersion": "2",
    "actions": [{
        "action": {
            "AMAccepts": {"Container": "List", "Optional": True,
                          "Types": ["com.apple.cocoa.string"]},
            "AMActionVersion": "2.0.3",
            "AMApplication": ["Automator"],
            "AMParameterProperties": {"COMMAND_STRING": {}, "CheckedForUserDefaultShell": {},
                                      "inputMethod": {}, "shell": {}, "source": {}},
            "AMProvides": {"Container": "List", "Types": ["com.apple.cocoa.string"]},
            "ActionBundlePath": "/System/Library/Automator/Run Shell Script.action",
            "ActionName": "Run Shell Script",
            "ActionParameters": {"COMMAND_STRING": script,
                                 "CheckedForUserDefaultShell": True,
                                 "inputMethod": 1,          # 1 = pass selection as arguments
                                 "shell": "/bin/zsh",
                                 "source": ""},
            "BundleIdentifier": "com.apple.RunShellScript",
            "CFBundleVersion": "2.0.3",
            "CanShowSelectedItemsWhenRun": False,
            "CanShowWhenRun": True,
            "Category": ["AMCategoryUtilities"],
            "Class Name": "RunShellScriptAction",
            "InputUUID": str(uuid.uuid4()).upper(),
            "Keywords": ["Shell", "Script", "Command", "Run", "Unix"],
            "OutputUUID": str(uuid.uuid4()).upper(),
            "UUID": str(uuid.uuid4()).upper(),
            "UnlocalizedApplications": ["Automator"],
            "arguments": {},
            "isViewVisible": 1,
            "location": "309.000000:253.000000",
            "nibPath": "/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib",
        },
        "isViewVisible": 1,
    }],
    "connectors": {},
    "workflowMetaData": {
        "serviceApplicationBundleID": "com.apple.finder",
        "serviceApplicationPath": "/System/Library/CoreServices/Finder.app",
        "serviceInputTypeIdentifier": "com.apple.Automator.fileSystemObject",
        "serviceOutputTypeIdentifier": "com.apple.Automator.nothing",
        "serviceProcessesInput": 0,
        "workflowTypeIdentifier": "com.apple.Automator.servicesMenu",
    },
}
with open(out, "wb") as f:
    plistlib.dump(doc, f)
PY
  cp "$dir/Contents/document.wflow" "$dir/Contents/Resources/document.wflow"
  plutil -lint "$dir/Contents/document.wflow" >/dev/null
  plutil -lint "$dir/Contents/Info.plist" >/dev/null
  echo "  ✓ $title"
}

echo "installing Quick Actions:"
make_action "Chute – Copy Paths for Prompt"  "public.item"   'paths "$@"'
make_action "Chute – Bundle Context (XML)"   "public.item"   'bundle "$@"'
make_action "Chute – Copy Redacted"          "public.item"   'redact "$@"'
make_action "Chute – New File from Clipboard" "public.folder" 'new --dir "$1" --reveal'
make_action "Chute – Unpack Markdown Here"   "public.folder" 'unpack --dir "$1"'
make_action "Chute – Checkpoint Before Agent" "public.folder" 'checkpoint "$1"'
make_action "Chute – Sandbox + Agent (yolo)" "public.folder" 'sandbox --dir "$1" --yolo'
make_action "Chute – Open Terminal Here"     "public.folder" 'open "$1"'

/System/Library/CoreServices/pbs -flush 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "$DEST"/Chute*.workflow 2>/dev/null || true
killall Finder 2>/dev/null || true
echo
echo "Installed. Right-click a file or folder → Quick Actions ▸ Chute – …"
