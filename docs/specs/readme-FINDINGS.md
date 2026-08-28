# README.md Correctness Audit — 2026-08-29

## Changes Made

### 1. Defect: Line 42 hardcoded absolute path

**Old:**
```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/install.sh
```

**New:**
```bash
./Scripts/install.sh
```

**Reason:** Absolute path `/Users/sxope/Documents/2026/Development/37.chute` only exists on author's machine. Replaced with relative path that works from repo root. Also fixed line 50 (uninstall) with same pattern for consistency.

---

### 2. Defect: Line 45 documented non-existent symlink

**Old:**
```
Installs `~/Applications/Chute.app` (menu bar `⤓`, hotkey `⌥⌘N`) and `~/.local/bin/chute`.
```

**New:**
```
Installs `~/Applications/Chute.app` (menu bar `⤓`, hotkey `⌥⌘N`). The CLI comes from Homebrew.
```

**Reason:** Scripts/install.sh lines 25-34 explicitly refuse to create `~/.local/bin/chute` symlink. It removes any legacy one (lines 25-29) and documents "NO NEW CLI SYMLINK. Homebrew owns the command-line tool" (line 31). Updated README to match actual behavior.

---

## Verification

**Commands tested and working:**
- `chute --version` → `chute 0.2.0`
- `chute --help` → full usage menu (20+ commands verified)
- `chute paths /path/to/file` → copies absolute paths to clipboard
- `chute tokens /path/to/file` → estimates token cost per file

**Claims that remain unverified** (not executable read-only):
- Finder menu integration (requires GUI, sandbox)
- Menu bar badge and session tracking (requires running app)
- `chute unpack` safety properties (requires test input)
- Hotkey `⌥⌘N` registration (requires running app)

---

## Notes

The repo structure assumes scripts run from the cloned directory; this is now clear from context since both lines 42 and 50 use relative paths. No additional setup instructions needed — standard for source-based installs.
