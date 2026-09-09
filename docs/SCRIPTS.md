# Scripts

Every script in [`Scripts/`](../Scripts), plus [`site/scripts/check-claims.mjs`](../site/scripts/check-claims.mjs).
Each entry states what it measures, how to run it, what a red run means, and — for the gates —
what it cannot catch, because each gate's own header comment says so and repeating that here
beats a reader having to find it.

`chutetests` links `ChuteCore` only ([`Package.swift`](../Package.swift)); see
[`docs/ARCHITECTURE.md`](ARCHITECTURE.md) for why several of these gates exist at all instead of
just running `swift test`.

## The gates

### `check-untested-logic.sh`

**What it measures.** Decision points (`if`, `guard`, `switch`, `case`, `for`, `while`, `&&`,
`||`) per file in `Sources/ChuteApp/` and `Sources/ChuteFinder/` — the two targets `chutetests`
cannot link — against a committed baseline
([`Scripts/untested-logic.txt`](../Scripts/untested-logic.txt)).

```bash
./Scripts/check-untested-logic.sh            # check against the baseline
./Scripts/check-untested-logic.sh --record   # re-record — ONLY when a file's count went down
```

**Red means** a file in `ChuteApp`/`ChuteFinder` grew, or a new file appeared there. The fix is
never to raise the baseline — it is to move the new branch into `ChuteCore` as a pure function
and cover it with a suite. It also fails outright if `Sources/chutetests/*.swift` is empty (the
sweep would be vacuous) or if a test constructs `ContextBuffer()` with no directory argument,
which points at the owner's real `~/.chute/buffer` basket rather than a temp one.

**Cannot catch:** anything inside the branch itself. A file can hold the same decision-point count
forever while the logic inside each branch silently changes — the count is a proxy for "how much
of this is untestable," not a correctness check on what's there. It also cannot catch code moved
*into* `ChuteCore` but never actually given a test.

### `check-focus.sh`

**What it measures.** For `README.md` and every top-level `site/src/app/*/page.tsx`: how many
CLI-shaped mentions (a `chute <command>`, "brew install", "CLI", "command line/-line") appear
*before* the first line naming "Finder" or "menu bar," and the ratio of CLI-shaped to
app-surface mentions in the file's first 60 lines — both against a committed baseline
([`Scripts/focus-baseline.txt`](../Scripts/focus-baseline.txt)).

```bash
./Scripts/check-focus.sh            # check against the baseline
./Scripts/check-focus.sh --record   # re-record — ONLY when the numbers improved
```

**Red means** a change moved CLI content above the app surfaces, or thickened the CLI:surface
ratio near the top of a file. The fix is to move the app-surface framing earlier or the CLI
reference later, not to re-record over the regression.

**Cannot catch** (from the script's own header, in full because it is unusually easy to over-trust
a green run here): it reads *source text*, not the rendered page, so JSX that renders in a
different order than it's written (a `const FAQ = [...]` array near the top rendering near the
bottom) fools it either direction. Content assembled from imported data
(`<CopyLine text={CONFIG.brew} />`) is invisible to it — it counts words in the file, not the
strings a component ultimately renders. It is a word list, not a reader: "Command Line Tools"
(Apple's Xcode toolchain) trips the same pattern as Chute's own CLI, and a sentence arguing
*against* leading with the CLI still counts as a CLI-shaped mention. It cannot see prominence — an
`<h1>` mention counts the same as one buried in a code comment. And it only walks `README.md` and
top-level `site/src/app/*/page.tsx` — nested routes, shared components, and `marketing/*.md` are
not swept. A green run means the measured proxy did not regress; it does not mean the page reads
well.

### `check-metrics.sh`

**What it measures.** Magnitudes against something physical — RAM reported by `sysctl`, logical
core count, a load of known size — rather than shape. Written after a CPU figure shipped 24×
wrong while every shape-only assertion (`cpuPercent` key exists, has a numeric type) stayed green.

```bash
./Scripts/check-metrics.sh
```

**Red means** a specific, physical claim is off by more than its check allows — e.g. a
measured CPU percentage exceeding `cores × 100`. Each check names the exact bug class it would
have caught.

**Cannot catch** anything that is shape-correct and merely wrong by an amount smaller than its
tolerance, or a magnitude bug in code this script does not exercise.

### `acceptance.sh`

**What it measures.** All nine Finder context-menu actions, driven through the real `chute`
binary (`chute finder-actions --json` prints the exact argv the extension sends) against a
deliberately hostile fixture tree (symlink loops, 10 MB files, quoted/newline filenames — built by
`fixtures.sh`).

```bash
./Scripts/acceptance.sh            # run everything
./Scripts/acceptance.sh --perf     # + a timing table
./Scripts/acceptance.sh --keep     # leave the fixtures in place afterwards
```

Safe unattended — never touches the real basket (`CHUTE_BUFFER_DIR`), never drives Finder
(`CHUTE_HEADLESS`), restores the clipboard on exit. It also cross-checks its own pass count
against the case count stated in `docs/specs/TEST-PLAN.md` and fails if they disagree, so the plan
cannot silently drift from what actually runs.

**Red means** one of the nine actions produced the wrong result against a hostile input, or the
plan's stated case count no longer matches reality.

**Cannot catch** the click itself — the FinderSync extension being invoked correctly is
`FinderTarget` in `ChuteCore`, covered by the unit suite instead, per the script's own header.

### `smoke.sh`

**What it measures.** End-to-end behaviour of the real `chute` binary against real files in a
scratch directory — paths, bundle, tokens, `new`, checkpoint (including two regression cases:
checkpointing a nested repo with no commit, and refusing a checkpoint that would hold nothing),
redact, clean, seed, and more, through the rest of the file.

```bash
CHUTE_HEADLESS=1 ./Scripts/smoke.sh   # CLI only — what CI runs, no logged-in Finder/Terminal needed
./Scripts/smoke.sh                    # + the sections that need a real desktop session
```

It also enforces the open-core removal: it fails the build if `isUnlocked`, `Trial.`, or
`License.` reappears anywhere in `Sources/`, per the licence history in the root `README.md`.

**Red means** the first failing assertion's line — it exits non-zero on the first failure, and
`FAIL` lines print what was expected versus what was got.

**Cannot catch** anything that needs a logged-in desktop when run with `CHUTE_HEADLESS=1` — those
sections are skipped, not passed, and print `SKIP … (headless)` rather than `ok`.

### `check-claims.mjs`

**What it measures.** Every published claim on the *built* site (and, per the founder's own
correction on 2026-09-08, `README.md` too — see [`check-focus.sh`](#check-focussh) for the
companion emphasis check) against the artifact that implements it: `du -sh` on the actual app
bundle for a size claim, `spctl` for a signing claim, the CLI's real dispatch table for a command
count — never against a number a human typed into a table. Enforces
[`marketing/06-FACT-SHEET.md`](../marketing/06-FACT-SHEET.md)'s "Claims that are currently FALSE"
table, which exists because three false claims ("328 KB", "28 commands", "Nothing is uploaded,
ever") reached the live site.

```bash
cd site && npx next build && npm run check:claims
```

**Red means** a specific rendered claim (visible text, or metadata like
`<meta name="description">` — it reads both, after a page shipped a stale claim only in metadata
and the check missed it because it stripped tags first) disagrees with the artifact it claims to
describe.

**Cannot catch** a claim it has no derivable ground truth for, or a claim never listed as an
assertion in the script at all — it only checks what someone wrote a check for, same limitation
`check-focus.sh` documents for itself: this script verifies truth, not emphasis.

### `reinstall-if-stale.sh`

**What it measures.** Whether the app actually installed in `/Applications` or `~/Applications`
matches `HEAD` — compares the bundle's `ChuteBuild` `Info.plist` stamp (read via `plutil`, not
`defaults read`, which caches stale values) against `git rev-parse --short HEAD`.

```bash
./Scripts/reinstall-if-stale.sh          # rebuild + reinstall only when stale; no-op when current
./Scripts/reinstall-if-stale.sh --check  # report only, exit 1 if stale — for a gate or a hook
```

It refuses to rebuild-and-install when the tree doesn't build or `chutetests` is red — a stale app
is bad, a broken one is worse — and after installing it re-reads the stamp to *prove* the install
matches rather than trusting `install.sh`'s own exit code, per the incident in its header (a
reinstall once reported success while installing a build four commits behind). It also refuses to
guess when two copies of `Chute.app` exist at once (one script silently keeping only one current
was how a previous session ended up with two menu-bar icons and no way to tell which was live).

**Red / exit 1 means** the installed bundle does not match `HEAD` (with `--check`), or the tree
would not build/pass so no reinstall was attempted, or two installs exist and neither was touched.
This script runs as a Stop hook in `.claude/settings.json` in this repo's own Claude Code setup.

**Cannot catch** anything about the app's actual behaviour — only whether the binary on disk
matches the tree. A stamp match says nothing about whether that build is correct.

### `screens.sh`

**What it measures/produces.** Nothing pass/fail by default — it renders every screen Chute has
(the menu in five scenarios: mixed, all-clear, runaway, no-hooks, truncation; plus About, Settings,
Setup) to PNG, from the actual shipping build, so a visual bug like the traffic-light dot
(`docs/ARCHITECTURE.md`) can be caught by looking rather than by a green suite. It fails only if a
scenario's binary doesn't produce the PNG it was asked for.

```bash
./Scripts/screens.sh                 # from the WORKING tree — build stamp reads "-dirty"
./Scripts/screens.sh --pristine      # from a detached worktree at HEAD — for anything published
./Scripts/screens.sh /tmp/out        # to a specific directory
```

Run it after any change to what a window shows — a passing suite says nothing about what a screen
actually looks like.

**Cannot catch** anything the five scripted scenarios don't cover, and it never evaluates the
image it produces — a human still has to look at the PNG.

## Build, install, release

| Script | What it does |
|---|---|
| [`build-app.sh`](../Scripts/build-app.sh) | Assembles `Chute.app` without Xcode: SwiftPM binaries + a hand-written `Info.plist` + ad-hoc signature. Reads the version from `Sources/ChuteCore/Version.swift` (the single source of truth) and stamps the build with `git rev-parse --short HEAD` (`-dirty` suffix if the tree has uncommitted changes) |
| [`install.sh`](../Scripts/install.sh) | Installs `Chute.app` for the current user (builds first if `dist/Chute.app` is absent) and registers the Finder extension. Installs over whichever copy already exists, `/Applications` or `~/Applications`; `CHUTE_APP_DIR` overrides |
| [`uninstall.sh`](../Scripts/uninstall.sh) | Removes Chute completely from both possible install locations and runs `chute hooks uninstall --force` against `~/.claude/settings.json` to clean up any legacy (≤0.1.0) hook blocks, backing the file up first |
| [`get.sh`](../Scripts/get.sh) | The `curl \| sh` installer — clones, builds, installs. Byte-for-byte mirrored to `site/public/install.sh`, which is what `chutedev.com/install.sh` actually serves; `check-claims.mjs` compares the two |
| [`package-dmg.sh`](../Scripts/package-dmg.sh) | Builds `dist/Chute-<version>.dmg`. Separate from `release.sh` so packaging can be tested without a Developer ID |
| [`sign-identity.sh`](../Scripts/sign-identity.sh) | Creates one stable self-signed local code-signing identity so repeated local builds don't each look like a different app to macOS. Not a Developer ID — a stranger's download still gets Gatekeeper's first-open warning |
| [`release.sh`](../Scripts/release.sh) | Build, notarise, staple, and publish a release in one command. Requires a Developer ID certificate; not run from CI on purpose (see the script's own header for why) |
| [`notarize-setup.md`](../Scripts/notarize-setup.md) | One-time setup notes for the Developer ID certificate and `notarytool` credentials `release.sh` needs |
| [`fixtures.sh`](../Scripts/fixtures.sh) | Builds the hostile fixture tree `acceptance.sh` runs against. Idempotent (removes and rebuilds), and refuses to run against a directory it wasn't explicitly pointed at |
| [`preflight-recording.sh`](../Scripts/preflight-recording.sh) | Read-only checklist run before recording a demo — app running, Screen Recording permission granted, extension current, no stray notification banner |

## Site and distribution (documented here, owned by `site/**`)

| Script | What it does |
|---|---|
| [`deploy-site.sh`](../Scripts/deploy-site.sh) | Builds and publishes `chutedev.com` to Cloudflare Pages, from a local machine (not CI — see its header for the credential-exposure reasoning) |
| [`cloudflare-setup.sh`](../Scripts/cloudflare-setup.sh) | One-time DNS setup pointing `chutedev.com` at the Cloudflare Pages project |

## Marketing/dev tooling (`.swift` scripts, run with `swift Scripts/<name>.swift`)

| Script | What it does |
|---|---|
| [`make-icon.swift`](../Scripts/make-icon.swift) | Draws the app icon at every required size natively — nothing is downscaled from a single master |
| [`marketing-board.swift`](../Scripts/marketing-board.swift) | Composes a single social-media board from `site/public/media/screens/*.png` — the same PNGs `screens.sh` renders, so the board can't drift from the shipping product |
| [`menu-shot.swift`](../Scripts/menu-shot.swift) | A fragment `screens.sh` injects into a scratch copy of `ChuteApp/main.swift` to drive the screenshot scenarios. Not compiled into the shipped app |
| [`untested-logic.txt`](../Scripts/untested-logic.txt), [`focus-baseline.txt`](../Scripts/focus-baseline.txt) | The committed baselines `check-untested-logic.sh` and `check-focus.sh` ratchet against — not scripts, but read them alongside the gate that owns each one |
