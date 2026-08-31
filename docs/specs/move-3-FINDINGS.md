# FINDINGS — Move 3: a stale CLI must be able to say so

Spec: `/Users/sxope/Documents/2026/Development/37.chute/docs/specs/move-3-version-stamp.md`
Owned files touched: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift`,
`/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/CoreSuites.swift`.
Not touched (correctly): `/Users/sxope/Documents/2026/Development/37.chute/Scripts/release.sh`
(see item 3 — reading and reporting was the complete, correct outcome).

## 1. `chute --version` prints the build stamp

`/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift:59-65` — new `versionLine`
constant, built from `ChuteVersion.current` + `Diagnostics.installedBuild()`, reusing the existing
mechanism (no new type, no new file):

```swift
let versionLine = "chute \(ChuteVersion.current) · app build "
    + (Diagnostics.installedBuild() ?? "not stamped — rebuild with ./Scripts/build-app.sh")
```

Wording copied verbatim from `chute doctor`'s non-json line at
`/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/DoctorCommand.swift:31-32`
(`"chute \(ChuteVersion.current) · app build " + (Diagnostics.installedBuild() ?? "not stamped —
rebuild with ./Scripts/build-app.sh")`) so the two surfaces agree exactly. Used at both places that
print the version: the early `--version`/`-V` check
(`/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift:69-72`) and the
`switch` case for the bare `version` command
(`/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift:109-110`). Could not be
factored into one shared function in `ChuteCore` — `Diagnostics.swift` is outside my three owned
files — so the formula is duplicated once, in the test (see item 4), exactly as it appears here.

## 2. No-args: exit 0, stdout

`/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift:73-76`. Changed
`exit(argv.isEmpty ? 1 : 0)` to a flat `exit(0)` — the other branch through that `guard` (an
unrecognized `--flag`) already exited 0, so the ternary collapsed to one value.

Correction to the spec's problem description: the help text was **already going to stdout**, not
stderr — `print(helpText)` is Swift's plain `print`, which targets stdout by default, and no
override exists anywhere in the tree (`grep -rn "func print("` found nothing). Verified directly:
running `.build/release/chute` with stdout and stderr redirected to separate files put all 2838
bytes on stdout, 0 on stderr. The only real defect was the exit code (1 for no-args); that's what I
fixed. Did not touch the case where the first arg is an unrecognized `--flag` — it already exited 0
and prints the same help.

**smoke.sh**: grepped for `unknown exits non-zero` and related assertions before touching anything,
per the spec's instruction — I do not own `smoke.sh`.
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/smoke.sh:555` has:
```
"$CHUTE" definitelynotacommand >/dev/null 2>&1 && bad "unknown exits non-zero" "exit 0" || ok "unknown exits non-zero"
```
That asserts on an **unknown command** (`definitelynotacommand`), which I left untouched and still
exits non-zero (verified below). **No assertion in smoke.sh exercises the no-args case** — I
grepped the whole file for `no-args`, `no arguments`, and any bare `"$CHUTE"` invocation with no
following argument and found none. **Nothing for the parent to change in smoke.sh.**

## 3. `Scripts/release.sh` — read in full, changed nothing

Read `/Users/sxope/Documents/2026/Development/37.chute/Scripts/release.sh` end to end before
touching anything. What it does today, step by step:

1. **Preflight** (lines 30-47): refuses if the git tree is dirty; refuses if the tag `v$VERSION`
   (read from `Sources/ChuteCore/Version.swift`) already exists, unless `--dry-run`; refuses if no
   `Developer ID Application` signing identity is in the keychain; refuses if no `notarytool`
   keychain profile is configured.
2. **Gate** (lines 50-52): runs `swift run chutetests` then `./Scripts/smoke.sh` — must both pass
   before anything is built or published.
3. **Build** (lines 55-56): runs `./Scripts/build-app.sh` with the signing identity. This is the
   exact script that stamps `ChuteBuild` (git short SHA + `-dirty` + UTC minute) into both
   Info.plists — i.e. `release.sh` already produces a build whose `chute doctor` / `chute
   --version` output (after this change) would correctly show the true installed build.
4. **Codesign verify** (lines 58-60): confirms the bundle is signed with a Developer ID.
5. **Package** (line 67): builds the DMG via `Scripts/package-dmg.sh`.
6. **Notarise** (lines 72-80): submits the DMG to Apple, waits, requires `status: Accepted`.
7. **Staple** (lines 82-84): staples both the `.app` and the DMG.
8. **Prove it** (lines 89-93): runs `spctl` and `stapler validate` as a machine that has never seen
   the app would.
9. **`--dry-run` stops here** (lines 97-100), before tagging — exit 0.
10. **Publish** (lines 102-131): `git tag -a vVERSION`, `git push origin vVERSION`, then `gh release
    create vVERSION dist/Chute-VERSION.dmg`. Each step has its own rollback on failure (untags
    locally, or untags + un-pushes) so a failed publish never looks like a half-finished release.

**What release.sh does NOT do, and this is the real finding**: it never touches the Homebrew tap.
`brew install avaluev/tap/chute` installs from a *separate* repo,
`avaluev/homebrew-tap` — documented in
`/Users/sxope/Documents/2026/Development/37.chute/packaging/homebrew/README.md` and
`/Users/sxope/Documents/2026/Development/37.chute/docs/11-PHASE-0-RUNBOOK.md:420-426` — and bumping
it is a fully manual, separate procedure: clone the tap repo, copy
`packaging/homebrew/chute.rb`, hand-edit the version and sha256 of the new tagged tarball, commit,
push. `release.sh` cuts a notarised `.app`/DMG GitHub release; it was never scoped to also publish
the CLI to Homebrew, and nothing in the repo automates that second step.

This is why "Homebrew chute is 54 commits behind HEAD" can be true even on a Mac where
`release.sh` runs cleanly every time: the DMG/GitHub-release half of shipping is one command: the
Homebrew half is a manual runbook step (`docs/11-PHASE-0-RUNBOOK.md` step 7) that, per that same
doc, was done once for the 0.1.0 → 0.2.0 jump and evidently not repeated since.

**Verdict, per the spec's own instruction**: `release.sh` already does the right thing for what
it's scoped to do (a signed, notarised, stamped app release), and the "smallest change that lets
the owner cut a release whose installed CLI matches HEAD" is not a code change here — it is running
the existing, documented Homebrew-tap-bump procedure
(`/Users/sxope/Documents/2026/Development/37.chute/packaging/homebrew/README.md`) every time
`release.sh` is run, which today the owner is not doing. **I changed nothing in `release.sh`.**
Automating the tap bump into `release.sh` would mean scripting a push to a *second* repo
(`avaluev/homebrew-tap`) with no way for me to test it (I'm barred from tagging/pushing/publishing,
and don't have that repo checked out) — that's a real feature, not the smallest fix, and inventing
it untested would be worse than reporting the gap honestly.

**What the owner should run** (not run by me):
```
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/release.sh --dry-run
```
to prove the pipeline, then a real `./Scripts/release.sh`, then the Homebrew tap bump per
`/Users/sxope/Documents/2026/Development/37.chute/docs/11-PHASE-0-RUNBOOK.md:420-426`.

## 4. Test

`/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/CoreSuites.swift:262-286` — new
`T.suite("VersionLine")`. Rebuilds the same string formula `main.swift` uses (can't import an
executable target from the test target, so the formula is necessarily duplicated — same as it
already is between `main.swift` and `DoctorCommand.swift`), using `Diagnostics.installedBuild
(appPath:)` against a nonexistent path (absent → "not stamped") and against a fake stamped
`Chute.app/Contents/Info.plist` built the same way `DiagnosticsSuite.swift:196-213` does (present →
stamp appears verbatim in the string). Tests the STRING, not plist-reading — `DiagnosticsSuite`
already owns that.

## Real verification output

```
$ cd /Users/sxope/Documents/2026/Development/37.chute && swift build -c release && swift run -c release chutetests
Build complete! (5.12s)
✅ 986 assertions passed

$ cd /Users/sxope/Documents/2026/Development/37.chute && .build/release/chute --version
chute 0.2.0 · app build ffe364b 2026-08-28T19:44Z
exit=0

$ cd /Users/sxope/Documents/2026/Development/37.chute && .build/release/chute; echo "no-args exit=$?"
[full help text on stdout]
no-args exit=0

$ cd /Users/sxope/Documents/2026/Development/37.chute && .build/release/chute nosuchcommand; echo "unknown exit=$? (MUST be non-zero)"
chute: unknown command 'nosuchcommand' — run `chute help`
unknown exit=1 (MUST be non-zero)
```

**Baseline discrepancy — 986 vs. the spec's stated 996, 0 failed either way.** Not a regression I
introduced: `git status --porcelain` shows `Sources/ChuteCore/FinderActions.swift` and
`Sources/chutetests/FinderActionsSuite.swift` both modified (`M`) by the other agent working
concurrently, per this task's own instructions — a net -2 lines in that diff plausibly accounts for
the assertion-count drop. My change added exactly 2 assertions (one `T.ok`, one `T.eq`) to the
count. Zero failures either way; I did not touch either FinderActions file.

## Anything the spec got wrong

The claim that no-args "writes the full help to stderr" — it doesn't, and never did; it uses plain
`print()`, which is stdout. Only the exit code was wrong. Fixed the exit code; left the (already
correct) stdout destination alone.
