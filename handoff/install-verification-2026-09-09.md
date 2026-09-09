# Chute install-path verification — 2026-09-09

All commands actually run (not read-only review). HEAD at test time:
`git -C /Users/sxope/Documents/2026/Development/37.chute rev-parse --short HEAD` → `f2ca34b`
(tree was dirty: 3 modified screenshot files, unrelated to install code).

Scratch root used for every install:
`/private/tmp/claude-502/-Users-sxope-Documents-2026-Development-37-chute/96f157e0-a3c8-458c-9f4d-ceb3ca5cf15f/scratchpad/installtest`

Safety: `/Applications/Chute.app` and `~/Applications/Chute.app` were never written to. Verified
before and after: real `/Applications/Chute.app` mtime stayed `Sep 9 08:14:48 2026` throughout
(`stat -f "%Sm %N" /Applications/Chute.app`); `~/Applications/Chute.app` does not exist on this
machine. Every scratch-launched `ChuteApp` process was killed with a path-scoped `pkill -f`
matching only the scratch binary, never `pkill -x ChuteApp`. No DMG was left mounted
(`hdiutil info | grep -i chute` → empty after each test).

## Results table

| # | Path | Command (abs paths) | Result | ChuteBuild stamp | Matches HEAD (f2ca34b)? | Wall time |
|---|---|---|---|---|---|---|
| 1 | curl-pipe installer (`Scripts/get.sh`, pointed at local repo) | `CHUTE_SRC="$SCRATCH/src1" CHUTE_REPO=/Users/sxope/Documents/2026/Development/37.chute CHUTE_APP_DIR="$SCRATCH/app1" sh /Users/sxope/Documents/2026/Development/37.chute/Scripts/get.sh` | PASS | `f2ca34b 2026-09-09T02:50Z` | Yes (clean clone of HEAD, no `-dirty` suffix since `git clone --depth 1` takes only the committed tree) | 48s |
| 2 | Repo script, stale-`dist/` trap | `CHUTE_APP_DIR="$SCRATCH/app2" /Users/sxope/Documents/2026/Development/37.chute/Scripts/install.sh` | **FAIL (by design of the script, not a crash)** — installed a stale build and reported success | `3dbe1ed-dirty 2026-09-09T02:48Z` | **No** — 3dbe1ed is 4+ commits behind f2ca34b | 3s |
| 3 | DMG (local build) | `/Users/sxope/Documents/2026/Development/37.chute/Scripts/package-dmg.sh` then `hdiutil attach dist/Chute-0.2.1.dmg -mountpoint $MOUNT -nobrowse -quiet` | PASS (mounts; `Chute.app` present; `Applications` symlink → `/Applications` present; bundled `chute` executable runs and prints its version) | `3dbe1ed-dirty 2026-09-09T02:48Z` (packaged from the same stale `dist/Chute.app` left by test #2 — `package-dmg.sh` does not rebuild unless called with `--build`, and the task's specified invocation omits it) | No — same stale build | 8s |
| 4 | Real release DMG (v0.2.1, what a stranger downloads) | `gh release download v0.2.1 --dir "$SCRATCH/rel" --clobber`; `shasum -a 256 -c Chute-0.2.1.dmg.sha256`; `hdiutil attach Chute-0.2.1.dmg -mountpoint $MOUNT -nobrowse -quiet` | PASS on checksum (`Chute-0.2.1.dmg: OK`) and mount; **Gatekeeper rejects the app** — see below | `31031f7 2026-09-08T11:48Z` | No — this is a released artifact, expected to lag `HEAD`; 31031f7 is the commit the v0.2.1 release was cut from, not a bug | 2s download, <1s checksum |
| 5 | `Scripts/reinstall-if-stale.sh --check` (non-destructive) | `/Users/sxope/Documents/2026/Development/37.chute/Scripts/reinstall-if-stale.sh --check` | Correctly reports staleness, exit 1, makes no changes | reads real `/Applications/Chute.app` → `778be6f` | No — `778be6f != f2ca34b-dirty` (tree has uncommitted changes) | <1s |

### Test 4 detail — Gatekeeper on the actual release artifact

```
codesign -dvv <mounted Chute.app>
  Authority=Chute Local Dev
  TeamIdentifier=not set

spctl -a -vv <mounted Chute.app>
  <path>: rejected
  origin=Chute Local Dev
```

The DMG a stranger downloads from GitHub Releases is **ad-hoc signed, not notarized**, and macOS's
own Gatekeeper assessment (`spctl -a -vv`) actively **rejects** it. This is the same thing
`Scripts/package-dmg.sh` prints for a local build ("NOT notarised … that needs the Apple Developer
ID"), but nothing in the README, the release page, or the DMG itself tells a downloader this is
coming or how to get past it (right-click → Open, or System Settings → Privacy & Security → Open
Anyway). A stranger who downloads and double-clicks the DMG will very likely see "Chute.app is
damaged and can't be opened" or "cannot be opened because Apple cannot check it for malicious
software" and have zero guidance.

### Test 2 detail — the stale-`dist/` trap, reproduced live

`Scripts/install.sh` contains `[ -d "$APP" ] || "$ROOT/Scripts/build-app.sh"` — it only builds when
`dist/Chute.app` is **absent**. Before this run, `dist/Chute.app` already existed on disk (stamped
`3dbe1ed-dirty`, built 2026-09-09T02:48Z, itself already 4+ commits behind the current tree HEAD
`f2ca34b`). Running `install.sh` exactly as documented in the README (`./Scripts/install.sh`) took
3 seconds, printed the full "Chute installed." success banner, and silently shipped code from
`3dbe1ed`, not `f2ca34b`. A user has no way to tell this happened from the script's own output —
the banner is identical whether it just built fresh code or copied a week-old bundle. This is
exactly the trap the task description warned about, confirmed with a live stamp mismatch, not
just by reading the script.

`Scripts/reinstall-if-stale.sh` (undocumented in the README's Install section) is the fix: it
builds unconditionally and then re-reads the stamp to prove the fix worked. `install.sh` itself
has no such guard.

## THE STRANGER'S EXPERIENCE — README.md § Install

Read as a non-engineer with zero context on this repo, and separately as an agent given only the
GitHub URL.

1. **No `git clone` step.** The Install section opens straight at `./Scripts/install.sh`. It never
   says to clone the repo first, or where to put it. A reader who has never used a terminal for
   anything but `cd Downloads` has no idea a `git clone` is the missing first line. An agent given
   only the repo URL would probably infer it correctly, but it's an inference the doc should not
   require.
2. **No mention of the actual, easiest path for most people — the DMG.** The v0.2.1 GitHub Release
   has a ready-built `Chute-0.2.1.dmg` + `.sha256` sidecar. Nothing in the README's Install section
   links to it, mentions it exists, or explains how to verify the checksum. A non-engineer reading
   only the README would never discover that a drag-to-Applications download exists at all — they
   would be routed straight at a shell script that clones a repo and compiles Swift, which is a
   much higher bar than "download a DMG."
3. **No mention of the curl-pipe one-liner either.** `Scripts/get.sh`'s own header comment says
   `curl -fsSL https://chutedev.com/install.sh | sh` is the intended zero-clone path and that it is
   mirrored to the website — but the README doesn't say this exists. Three different install
   surfaces exist (curl-pipe, repo script, DMG) and the README's Install section names exactly one
   of them.
4. **No prerequisite list before the command.** `./Scripts/install.sh` will itself invoke
   `build-app.sh`, i.e. `swift build -c release`, the first time. The README's Install section says
   nothing about needing Xcode Command Line Tools, a Swift toolchain, or `git`. (`get.sh` checks
   for `git` and `swift` and fails with an actionable message — `xcode-select --install` — but that
   safety net lives in a script the README never points a reader at directly for this exact flow.)
   A reader who lacks the CLT and runs `install.sh` directly gets a `swift: command not found` or a
   worse half-finished compiler error with no README guidance to fall back on.
5. **No macOS version floor stated in the README.** `get.sh` hard-checks for macOS 13+ before
   doing anything; the README's Install section says nothing about a minimum OS version. A reader
   on macOS 12 or older gets no warning until the build (or `get.sh`, if they found it) fails.
6. **No first-run permission expectations.** The Install section doesn't warn that macOS will ask
   for Automation permission on first hotkey/Finder-action use (this is mentioned only in
   `install.sh`'s own runtime output, not in the README a reader reads *before* running anything).
   A cautious non-engineer, mid-install, seeing an unfamiliar "Chute wants to control Finder"
   system prompt with zero prior warning in the docs, may reasonably decline it and end up with a
   silently broken Finder menu.
7. **No Gatekeeper guidance anywhere for the DMG path** (see Test 4 above) — this compounds with
   finding #2: the README doesn't mention the DMG, so it also never has to (and doesn't) explain
   that Gatekeeper will reject it and what to do about that.
8. **"Remove it completely at any time" oversells `uninstall.sh` slightly for the two-copies
   case** — see the Uninstall note below; not tested end-to-end for safety reasons, but reading it
   shows it removes both `~/Applications/Chute.app` and `/Applications/Chute.app` unconditionally,
   which is correct for "remove everything" but means a reader with only one install and one they
   didn't intend to touch has no dry-run option before running it.
9. **The build time isn't set as an expectation.** `get.sh` prints "about a minute, no dependencies
   to fetch" — measured here at 48s wall clock end-to-end including the clone. The README's Install
   section gives no time expectation at all, so a reader running the bare `install.sh` (which also
   triggers a build the first time) has no idea whether a 40-second silent-ish pause is normal or a
   hang.
10. **What "installed" actually did is invisible from the README.** The script restarts Finder
    (`killall Finder`), registers a Finder-extension appex, and opens the app — all real, visible,
    somewhat startling side effects (every Finder window's state resets) that a first-time reader
    is not warned about anywhere in the README before they run the command.

### What a reader cannot know from the README page alone
- That Xcode Command Line Tools / a Swift toolchain are required for the repo-script and curl-pipe
  paths (only the DMG path avoids this, and the DMG path isn't mentioned).
- That macOS 13 (Ventura) is the floor.
- That a Finder-extension permission / Automation permission prompt is coming.
- That Gatekeeper will reject the DMG (ad-hoc signed, not notarized — confirmed live in Test 4)
  and that the fix is right-click → Open (or System Settings → Privacy & Security → Open Anyway).
- Whether `brew install avaluev/tap/chute` (mentioned later, under "The command-line tool")
  installs the app or only the CLI — reading the whole README clarifies it's CLI-only, but a
  reader who stops at the Install section and later sees the brew line elsewhere could easily
  assume brew is a full alternative install path for the app itself.

## Uninstall script — not run against a live copy (per safety instructions)

`Scripts/uninstall.sh` was read, not executed against a real or scratch install. It does **not**
honor `CHUTE_APP_DIR` — it hardcodes exactly two targets, `$HOME/Applications/Chute.app` and the
literal `/Applications/Chute.app`, with no environment-variable override anywhere in the script.
Per the task's safety rule ("read the script first to confirm it honours CHUTE_APP_DIR — if it
does NOT, skip that test"), this test was **skipped**. Running it as-is, even pointed at a "scratch
copy," would require putting that scratch copy at one of those two real, hardcoded locations, which
is exactly the machine-wide blast radius the safety rule is guarding against.

## Roadmap

**Done** — all 5 requested paths run for real with evidence (stamps, timings, checksums,
Gatekeeper assessment); README Install section critiqued line-by-line; uninstall.sh read and
correctly skipped per safety rule.

**In progress** — none; this was a one-shot verification pass, no code changed.

**Remaining** (for whoever picks this up next):
1. `Scripts/install.sh` has no built-in staleness check of its own — it happily ships a `dist/`
   left over from an earlier build. Either make `install.sh` call `reinstall-if-stale.sh`'s stamp
   check itself, or have the README instruct `reinstall-if-stale.sh` as the canonical install
   command instead of bare `install.sh`.
2. README Install section rewrite: add the DMG path with a checksum-verify step, add the
   curl-pipe one-liner, add prerequisites (CLT/Swift, macOS 13+), and add a one-line Gatekeeper
   warning + fix for the DMG path.
3. `Scripts/uninstall.sh` could accept `CHUTE_APP_DIR` the same way `install.sh` does, so a full
   uninstall/reinstall cycle can be tested against scratch without touching real install
   locations.
