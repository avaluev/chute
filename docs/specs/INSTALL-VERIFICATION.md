# Install path verification — 2026-09-08

Every documented way to install Chute, actually run, not assumed. Commit at start of this
sweep: `54457a3`. Commit at close (after other agents' concurrent commits landed, none of them
mine): `e8ecd25`. Only files touched: `Scripts/install.sh`, `packaging/homebrew/chute.rb`, this
file.

## Where the install instructions live

Found by grepping `README.md`, `site/src/**`, `marketing/**`, `Scripts/**`:

- `README.md:44` — `brew install avaluev/tap/chute`
- `README.md:50` — `./Scripts/install.sh`
- `README.md:58` — `./Scripts/uninstall.sh`
- `site/src/app/page.tsx:370` — `curl -fsSL https://chutedev.com/install.sh | sh`, served from
  `site/public/install.sh`, which is a byte-for-byte copy of `Scripts/get.sh` (confirmed with
  `diff` — 0 differences). **Not synced by any build step** — `grep -rn "get.sh\|install.sh"`
  across `site/package.json` and `site/scripts/*.mjs` found nothing. Today the copy happens to
  match; the next edit to `Scripts/get.sh` will silently diverge from what the site serves. That
  copy lives under `site/**`, not mine to fix — flagged below.
- `site/src/app/page.tsx:386` + `site/src/lib/config.ts:7` — DMG from
  `https://github.com/avaluev/chute/releases/latest`

## Results

| Path | Command | Verdict |
|---|---|---|
| Homebrew CLI | `cd /Users/sxope/Documents/2026/Development/37.chute && brew install avaluev/tap/chute` | **WORKS** |
| DMG release | `gh release view --repo avaluev/chute` + download + mount | **WORKS** |
| `install.sh` from source | `cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/install.sh` | **WORKS (1 bug fixed)** |
| `get.sh` (curl\|sh path) | `CHUTE_SRC=<tmp> CHUTE_APP_DIR=<tmp> bash /Users/sxope/Documents/2026/Development/37.chute/Scripts/get.sh` | **WORKS** |
| `uninstall.sh` then reinstall | `cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/uninstall.sh && ./Scripts/install.sh` | **HAZARD CONFIRMED REAL** (documented workaround still required) |
| `package-dmg.sh` | `cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/package-dmg.sh --build` | **WORKS** |

### 1. Homebrew — WORKS

`brew info avaluev/tap/chute` → `stable 0.2.0`, tap resolves, `Installed (on request)`.
`brew reinstall avaluev/tap/chute` rebuilt from source in 32s and succeeded. `chute --version` →
`chute 0.2.0`. **`CONFIG.brewLive = true` at `site/src/lib/config.ts:14` is not a lie** — the tap
is genuinely live.

**Note, not a broken install path:** the tap serves `0.2.0`; `Sources/ChuteCore/Version.swift`
and the GitHub release are at `0.2.1` (`gh release view --repo avaluev/chute` → tag `v0.2.1`,
asset `Chute-0.2.1.dmg`). `packaging/homebrew/chute.rb` in this repo also still said `0.2.0` with
a stale sha256 — fixed here (see "What was fixed"), but the actual publish to
`avaluev/homebrew-tap` (steps 4-6 of `packaging/homebrew/README.md`) is a separate, deliberate
push this task does not make, per "do not publish anything."

### 2. GitHub release / DMG — WORKS

`v0.2.1`, published, not a draft, carries `Chute-0.2.1.dmg` + `.sha256`. Downloaded and checked
(`shasum -a 256 -c` → `OK`), mounted with `hdiutil attach`: contains `Chute.app` and the
`Applications` symlink, `Contents/MacOS/chute --version` → `chute 0.2.1 · app build 31031f7
2026-09-08T11:48Z`, unmounted clean. Nothing was published or altered — read-only.

### 3. `Scripts/install.sh` — WORKS, one real bug found and fixed

Ran for real against the founder's actual, running `/Applications/Chute.app` (per the task's own
instruction — this is the only way to prove the "installs over whichever copy exists" chooser
logic, since it keys off the literal `/Applications` path). Chooser correctly detected the
existing `/Applications` copy and installed there, not `~/Applications`. Quarantine attribute
correctly cleared (`xattr -p com.apple.quarantine` → no such xattr). `com.apple.provenance`
persists after `xattr -dr` — confirmed it is a no-op on this macOS version (`xattr -d` reports
exit 0 but the attribute is immediately reasserted by the OS); harmless, since Gatekeeper keys off
quarantine, not provenance, and the app launched and ran fine. Not fixed — there is nothing this
script can do about a kernel-reasserted attribute.

**CRITICAL, fixed:** `pkill -x ChuteApp` (two call sites, `Scripts/install.sh:89` and the repair
retry at `:135` before the fix) matches by **process name only**, not path. Proven by testing
item 4 (`get.sh`) with `CHUTE_APP_DIR` pointed at a scratch directory, specifically to avoid
touching the founder's real install: the sandboxed install still killed the founder's real,
running `/Applications/Chute.app` process, because both processes share the name `ChuteApp`.
`pgrep -f "^/Applications/Chute.app/Contents/MacOS/ChuteApp"` went from present to absent the
moment the sandboxed `install.sh` ran. Fixed by scoping both `pkill` calls to
`pkill -f "^$APP_DIR/Chute.app/Contents/MacOS/ChuteApp"` — re-ran the same sandboxed test after
the fix and the founder's real process survived. This means `CHUTE_APP_DIR`, the variable this
script already trusts for where to *write*, was not being honoured for what to *kill* — any
install.sh run anywhere, sandboxed or not, was taking out whichever copy of Chute happened to be
running elsewhere on the machine.

### 4. `Scripts/get.sh` — WORKS

Read first (64 lines, matches its own "40 lines" claim closely enough, matches
`site/public/install.sh` byte-for-byte). Ran for real with
`CHUTE_SRC=<scratch>/src CHUTE_APP_DIR=<scratch>/Applications` — env vars are inherited by the
scripts it shells out to even though `get.sh` never re-exports them, so this fully sandboxes both
the clone and the install. Cloned the real `https://github.com/avaluev/chute` (depth 1), built,
installed into the scratch dir, app launched (`pgrep` confirmed the process). This run is what
surfaced the `pkill` bug above — it is now safe.

### 5. `Scripts/uninstall.sh` then reinstall — hazard confirmed real, not fixed

Ran uninstall.sh for real (it has no `CHUTE_APP_DIR` escape hatch — the header's stated behaviour
is to clear *both* `/Applications` and `~/Applications` unconditionally, which is deliberate per
its own comments). Confirmed:

- `/Applications/Chute.app` and `~/Applications/Chute.app` both removed.
- `pkill -x ChuteApp` here is **correctly** unscoped — uninstall's job is to kill every copy, so
  this one call site is not the bug found above.
- It also ran `chute hooks uninstall --force` against the real `~/.claude/settings.json` and
  found and removed 4 legacy Chute-marker hook blocks that were actually present there (backed up
  first, to `~/.claude/settings.json.chute-backup-<UTC timestamp>`, exactly as documented).
  Restored the file from that same auto-backup immediately after, byte-identical
  (`diff` confirmed). Flagging this plainly: **testing `uninstall.sh` for real necessarily writes
  to `~/.claude/settings.json`** if legacy Chute hooks are present — that is uninstall.sh's
  documented job, not a bug, but it collides with "never touch settings.json" for anyone testing
  this script for real. It leaves a timestamped backup, so it is recoverable, and I did recover
  it — but a future run of this same test should budget for the same restore step.

Then reinstalled with plain `./Scripts/install.sh` (no `CHUTE_APP_DIR`) — **it landed in
`~/Applications`, not back in `/Applications`**. This is exactly the hazard
`Scripts/install.sh:28-32`'s own comment describes: uninstall clears both folders, the chooser
sees neither, and defaults to `~/Applications`. **Confirmed real, not fixed** — the documented
workaround (`CHUTE_APP_DIR=/Applications ./Scripts/install.sh` when reinstalling after a full
uninstall) is still the only guard, and it worked when applied. Restored the founder's install to
`/Applications` this way, then removed the stray `~/Applications` copy via Finder (`osascript …
delete POSIX file`, no password, no `rm -rf`).

**Not owned, seen live during this test:** while the app briefly existed in both
`/Applications` and `~/Applications` during this test, another agent (not me — I do not own
`Scripts/reinstall-if-stale.sh`) added two-copy detection to that script mid-session,
citing this exact scenario. Not evaluated further here since it is outside this task's file list.

### 6. `Scripts/package-dmg.sh` — WORKS

`./Scripts/package-dmg.sh --build` → builds, then `./Scripts/package-dmg.sh` alone confirmed the
DMG mounts, contains `Chute.app` and the `Applications` shortcut, and the bundled CLI is
executable — the script's own self-check passed, matching a second manual mount/unmount I ran
independently. Correctly reports NOT notarized (no Developer ID here), which is accurate and not
a defect.

## What was fixed (files owned by this task)

- `Scripts/install.sh` — scoped both `pkill -x ChuteApp` calls to the specific `$APP_DIR` being
  installed, so a sandboxed or secondary install can no longer kill an unrelated running copy of
  Chute. Verified red (kills the wrong process) before, green (leaves it alone) after.
- `packaging/homebrew/chute.rb` — bumped `version`/`sha256` from the stale `0.2.0` to `0.2.1`,
  matching the real GitHub release and `Sources/ChuteCore/Version.swift`. Local file only —
  nothing pushed to `avaluev/homebrew-tap`.

## CRITICAL — found, not owned, not fixed

- `site/public/install.sh` is a hand-copied duplicate of `Scripts/get.sh` with no build-time sync
  and no test catching drift. It happens to match today. First edit to `get.sh` that isn't
  mirrored into `site/public/install.sh` makes the site's "you can read it first" link show
  stale/wrong content. Belongs to `site/**`.
- The live Homebrew tap (`avaluev/tap/chute`, `0.2.0`) is one release behind the GitHub release
  and the tree (`0.2.1`). Not a broken install — `brew install avaluev/tap/chute` works — but a
  buyer who reads the release notes and then brews gets the older CLI. Publishing the tap update
  is outside this task's scope ("do not publish anything").

## Final verification

```
cd /Users/sxope/Documents/2026/Development/37.chute && swift build -c release
→ Build complete! (15.14s)

cd /Users/sxope/Documents/2026/Development/37.chute && swift run -c release chutetests
→ ✅ 1265 assertions passed

cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/reinstall-if-stale.sh
→ reinstalled /Applications/Chute.app at e8ecd25-dirty
→ (re-run --check immediately after: "is current (e8ecd25-dirty)")
```

`/Applications/Chute.app` is running (`pgrep` confirmed), Finder extension registered
(`pluginkit -m -i dev.valuev.chute.finder` → `+ dev.valuev.chute.finder(0.2.1)`),
`~/.claude/settings.json` confirmed valid JSON and restored to its pre-test content.
