# Readiness audit — is this ready for a professional developer to accept — 2026-09-01

> **STATUS 2026-09-01, after the fix session.** Nine of the ten items below are CLOSED; see the
> DONE table in `handoff/NEXT.md` for the proof line on each. Still open: **item 1** (mint the
> production licence key — founder only) and **item 9** (splitting `AgentCommands.swift`, which
> was deliberately declined: 247 lines is inside this repo's own 200-400 guideline and its five
> commands are all agent-adjacent, exactly as `FileCommands.swift` groups new/seed/note).
>
> Two corrections to what is written below, found by doing it:
> · Area 5 says `Trial.recordPath` should be internal. It cannot be — it is the default-argument
>   expression of PUBLIC functions, and Swift resolves those at every call site. It stays public
>   with a comment saying so.
> · Area 2 finding 3 counted THREE AppleScript-escape copies. There were FOUR — `Notify.swift:114`
>   was missed, and it carried the same drifted `"` -> `'` mapping. All four now call
>   `ChuteCore/AppleScript.swift`.
>
> The audit also missed two things this session found: `marketing/` was outside every gate (five
> assets sold a command deleted on 2026-08-31), and `site/public/media/` served three recordings
> of deleted features at live URLs. Both are now gated, not noted.

Method: read-only. Every finding below carries a `file:line` or a command whose output proves it.
Where a prior audit (`handoff/AUDIT-2026-08-28-*.md`, `docs/specs/review-*-FINDINGS.md`) made a
claim, it was re-checked against the CURRENT tree rather than trusted — several were already fixed
since Aug 28-31; those are called out explicitly so the next session does not re-spend time on them.

**Gates run, both green, exact match to the expected tallies:**

```
$ swift build -c release && swift run -c release chutetests
✅ 898 assertions passed

$ CHUTE_HEADLESS=1 ./Scripts/smoke.sh
smoke: 137 passed, 0 failed
```

---

## 1. TESTABILITY GAP

`Package.swift:18` — `chutetests` depends on `["ChuteCore"]` only. `Sources/ChuteApp` (10 files,
1,720 lines) and `Sources/ChuteFinder` (1 file, 227 lines) carry **zero** unit coverage — not
"low," zero: no test file imports `ChuteApp` or `ChuteFinder`, and `Package.swift` gives no target
a path to do so (`chutetests` is a plain executable, not a `.testTarget` — XCTest is unavailable
on this Command-Line-Tools-only toolchain, per the comment at `Package.swift:4-5`).

**Quantified.** Counting decision points (`if`, `guard`, `switch`, `case`, `for`, `while`, `&&`,
`||`) per file:

| File | Decision points |
|---|---|
| `Sources/ChuteApp/main.swift` | 34 |
| `Sources/ChuteApp/SessionMenu.swift` | 22 |
| `Sources/ChuteFinder/ChuteFinderSync.swift` | 19 |
| `Sources/ChuteApp/Onboarding.swift` | 17 |
| `Sources/ChuteApp/RequestInbox.swift` | 16 |
| `Sources/ChuteApp/FirstRunWindow.swift` | 16 |
| `Sources/ChuteApp/Notify.swift` | 11 |
| `Sources/ChuteApp/SettingsWindow.swift` | 9 |
| `Sources/ChuteApp/ResultHUD.swift` | 5 |
| `Sources/ChuteApp/ServersMenu.swift` | 4 |
| `Sources/ChuteApp/Panel.swift` | 1 |
| **Total, 1,947 lines** | **154** |

154 untested decision points is the real number — every one of them can only be exercised by
opening the app and clicking, which the gate command (`smoke.sh`) explicitly cannot do for GUI
surfaces (`CHUTE_HEADLESS=1` skips them by design).

**Named functions that carry real logic, not just AppKit wiring, and cannot currently be tested:**

- `ChuteFinderSync.run(_:)` — `Sources/ChuteFinder/ChuteFinderSync.swift:179-212` — decides, per
  click: is the selection empty, can the target folder be resolved, did the write to `ActionInbox`
  succeed, and (async, 3s later) was the request ever picked up. Four branches, each choosing a
  different user-facing message.
- `RequestInbox` (whole file) — `Sources/ChuteApp/RequestInbox.swift` — 16 decision points,
  0 test coverage. This is the code that turns a Finder click into a confirmation dialog, decides
  dry-run vs. force wording for destructive actions, and drains `ActionInbox`. It is pure decision
  logic wrapped in `NSAlert` calls, not logic that needs AppKit to exist.
- `SessionMenu` row-building — `Sources/ChuteApp/SessionMenu.swift:98-162` (65 lines, one
  function) — decides which rows retitle on the 2-second timer and how.
- `Onboarding` step navigation — `Sources/ChuteApp/Onboarding.swift:75-144` (70 lines) — decides
  which step is "done," "next," or blocked, duplicating logic that already has a `ChuteCore`
  counterpart (`OnboardingSteps.swift`, which IS tested) but re-derives some of it inline.
- `FirstRunWindow` permission-gate branching — `Sources/ChuteApp/FirstRunWindow.swift:80-137`.

**Smallest fix.** Not a `.testTarget` — the toolchain constraint in `Package.swift:4-5` (no XCTest)
means the whole suite would have to move to `swift-testing` or accept an Xcode dependency the repo
explicitly avoids; that is a bigger change than the payoff justifies right now. The proven, cheap
pattern already exists in this codebase: `Sources/ChuteCore/StatusMenu.swift` is exactly this kind
of "decide what to show" logic extracted out of `ChuteApp`, and `Sources/chutetests/StatusMenuSuite.swift`
covers it with zero AppKit dependency. Do the same for `RequestInbox`'s decision logic first (it is
the highest-value target: destructive-action confirmation text) and `SessionMenu`'s row-retitling
rule second. `ChuteFinderSync.run`'s four-way branch is smaller and could move almost as-is — it
already delegates the actual work to `ChuteCore.ActionInbox`/`ActionRequest`, so only the message
selection needs to move.

**Already good:** the pattern is proven, not theoretical — `StatusMenu.swift`/`StateResolver.swift`/
`ActionRequest.swift`/`OnboardingSteps.swift` show the team already knows how to do this extraction
and has done it four times. This is a matter of continuing a known move, not inventing one.

---

## 2. CODE DESIGN

Worst five, by file:line:

**1. `Sources/chute/Commands/DoctorCommand.swift:4-129` — `cmdDoctor`, 126 lines, one function.**
Four output modes (`--report`, `--json`, `--fix`, plain text) and the fix-orchestration branch all
live in one body. Nesting reaches 4 deep in the `--fix` branch (`if a.has("fix")` → `if
!toFix.isEmpty` → `guard a.has("force") else`). Worth splitting `--report` and `--json` rendering
into their own functions; the `--fix` orchestration is legitimately entangled with the rest since
it re-runs the same checks afterward (see Area 3 — this is also the command's best safety property,
so don't split re-verification away from the branch it guards).

**2. `Sources/chute/Commands/AgentCommands.swift` — still "four features in one file"** (five, by
FR tag): `cmdOpen`/`launchTerminal` (FR-07, lines 14-77), `cmdSandbox` (FR-08/21, lines 81-122),
`cmdPorts` (FR-15, lines 126-159), `cmdEnv` (FR-24, lines 163-226, 64 lines — the longest single
command body here), `cmdPrompt` (FR-17/18, lines 230-247). Every other multi-feature area in this
CLI already gets its own file (`FileCommands.swift`, `GitCommands.swift`, `SessionCommands.swift`)
— this is the one file that never got split after the fact.

**3. Three separate, hand-kept implementations of "escape a string for an AppleScript literal" —
one of them already disagrees.**
`Sources/ChuteCore/FinderReveal.swift:13-16` (`FinderReveal.escape`, replaces `"`→`\"`),
`Sources/chute/Commands/AgentCommands.swift:39-40` and `:44-45` (the SAME two-line escape inlined
twice in the same function, for Terminal.app and iTerm respectively, instead of calling
`FinderReveal.escape` which `AgentCommands.swift` could reach — it already `import`s `ChuteCore`),
`Sources/ChuteFinder/ChuteFinderSync.swift:217-219` (a third, local `escape` — this one replaces
`"`→`'`, not `\"`). Three copies of a security-relevant string-escaping routine, kept in sync by
hand, and one has already drifted. Low blast radius today (the divergent copy only feeds a
notification's `display notification` string, not a `do script`), but this is precisely the "two
places, one truth" shape the codebase's own comments warn against elsewhere (e.g.
`DoctorCommand.swift:131-135`).

**4. `Sources/chute/Commands/GitCommands.swift:20-110` — `cmdCheckpoint`, ~91 lines, one function.**
Private-index setup, `git add -A --ignore-errors`, empty-tree detection, author-identity fallback,
`commit-tree`, and branch-creation-with-race-recovery (`pointsAtOurCommit()`, a nested function) all
in one body. Each piece is well-commented and individually correct (see PASS notes in Area 3), but
the function is doing five distinct git operations that could be five named steps.

**5. `Sources/chute/Commands/DoctorCommand.swift:140-204` — `repair(_:dryRun:)`, 65 lines, one
switch with 5 cases**, each shelling out to 1-6 subprocesses inline (`ext-started` alone runs 7).
Not hard to follow, but adding a 6th repair means growing this switch rather than adding a file.

**Already good, do not touch:** no duplicated *business* logic found beyond the escape functions
above — `ContextBundle.assemble` is the single formatter both `chute bundle` and the context basket
call (verified: `grep -rn "ContextBundle.assemble" Sources/` → 2 call sites, both delegating, no
second implementation); `HookInstaller`'s uninstall path validates-before-write and backs up before
mutating, in one well-organized 240-line file that earns its length.

---

## 3. ERROR HANDLING

The 2026-08-28 audit's "8 CLI commands fail silently at exit 0" claim could not be reproduced at
that count — several of those were inside `chute unpack`, which was deleted entirely on 2026-08-31
(`docs/specs/move-5-delete-unpack.md`). Re-checked from scratch against the current 26-command
surface. Confirmed, still present:

**1. `Sources/chute/Commands/SessionCommands.swift:10-30` — `chute sessions` exits 0 on a real
permission failure.** `discoverSessions()` (lines 10-23) catches a Terminal-Automation denial,
prints the reason to stderr via `Out.info`, and sets `hadError = true` — but `cmdSessions` (lines
25-30) only checks `hadError` to decide whether to print "no terminal sessions"; it never calls
`Out.fail`. The process exits 0 either way. A script checking `$?` cannot tell "no sessions" from
"Automation access denied."

**2. `Sources/chute/Commands/FileCommands.swift:69-70` — `cmdSeed` swallows per-file write
failures and still exits 0.** Inside the `for rule in rules` loop, a write failure is caught and
reported via `Out.info` (line 70), then `continue`s. If every rule fails to write — disk full,
permission denied, whatever — the command still finishes normally and prints `"→ 0 file(s)
seeded"` to stderr, exit 0. Nothing distinguishes "nothing to do" from "everything failed."

**3. `Sources/ChuteCore/ContextBuffer.swift:125-126` + `Sources/chute/Commands/ContextCommands.swift:116-120`
— `chute basket add` claims success it never verified.** `ContextBuffer.add()` calls
`fm.createFile(atPath:contents:attributes:)` and discards its `Bool` return (line 125-126) — that
call fails silently on a full disk or bad permissions. `cmdBasket`'s `"add"` case (lines 116-120)
does `paths.forEach { buf.add($0) }` without checking any of the returned `Entry?` values, then
unconditionally prints `"→ added \(paths.count) — \(buf.entries().count) in the basket"`, which is
also not actually cross-checked against what `paths.count` claims.

**Already good — verify before "fixing":**
- `Out.fail` (`Sources/chute/Args.swift:71-74`) is used consistently everywhere else and always
  exits 1; the CLI's no-args/`--help`/`--version` paths correctly exit 0 by design
  (`Sources/chute/main.swift:69-76`, commented as deliberate: "no-args is the product's front
  door").
- `cmdDoctor --fix` (`DoctorCommand.swift:59-62`) never reports success without re-running every
  check afterward — `repair()`'s own internal `_ = Shell.run(...)` calls (ignored results,
  `DoctorCommand.swift:165-172`) look like the same anti-pattern but are NOT: the final exit code
  comes from the post-repair re-verification, not from `repair()`'s own claims.
- `smoke.sh` no longer uses `set -e` (now `set -uo pipefail`, `Scripts/smoke.sh:3`) and its final
  line, `[ "$FAIL" -eq 0 ]`, correctly gates the exit code on the tallied failure count. A
  previously-documented footgun ("green with zero failures can still be a broken run,"
  `handoff/HANDOFF-2026-08-31-icp.md:78-80`) is fixed.
- The Aug 28 claim that `chute doctor` prints a false all-clear because there was "deliberately no
  hooks check" is **fixed**: `Sources/ChuteCore/Diagnostics.swift:104-110` now has a `.note`-severity
  `hooks` check that reports "not wired — badge stays dark" without blocking, so the false-positive
  is gone.

---

## 4. SECURITY

**1. CRITICAL for release, not for a code-read: `Sources/ChuteCore/License.swift:28` —
`productionPublicKey = "REPLACE_ME_BEFORE_RELEASE"`.** This string contains `_`, which is not a
valid base64 character. `License.verify()` (`License.swift:35-48`) does
`Data(base64Encoded: publicKey)` against this constant at line 46 — that call returns `nil` for
this specific value, so the `guard` fails and `verify()` returns `nil` for **every** key, including
a correctly-signed, correctly-minted real one. The $19 unlock is currently 100% non-functional in
a release build. **This is invisible to the test suite by design**:
`Sources/chutetests/LicenseSuite.swift:7` uses its own `testPublicKey`
(`private let testPublicKey = "DbB2..."`) and never touches `License.productionPublicKey` at all —
898/898 passing gives zero signal here. Matches the open item already tracked in
`handoff/HANDOFF-2026-08-31-icp.md:111` ("Phase 0 — still blocking money").

**2. `Resources/ChuteFinder.entitlements:14` — the sandbox's read-write exception is scoped to `/`,**
not to the one path the code actually writes: `com.apple.security.temporary-exception.files.absolute-path.read-write`
→ `<string>/</string>`. The comment right above it (line 13) says this exists for "Writing the
request file into `~/.chute/requests`" — a single directory, not the filesystem root. Broader than
what App Review or defense-in-depth calls for; narrow it to `~/.chute` (or the literal
`/Users/<user>/.chute` the code uses, per `ActionRequest.swift:26`).

**3. `CHUTE_BUFFER_DIR` — ALREADY FIXED since the 2026-08-31 security review.** The prior finding
(`docs/specs/review-security-2-FINDINGS.md:16-51`) was that this env override was unguarded.
Current code, `Sources/ChuteCore/ContextBuffer.swift:69-80`: `defaultDirectory` now resolves both
the override and `NSTemporaryDirectory()` through `.resolvingSymlinksInPath()` and refuses (with a
stderr message) any value that doesn't land under the system temp dir. Re-verified by reading the
guard directly — closes the "silent redirection" gap. No further action needed.

**4. Basket TOCTOU / symlink-swap — unchanged, still reachable, still an accepted, documented
design decision.** `ContextBuffer.entries()`/`add()` store `{ts, path}` only (`ContextBuffer.swift:87-131`);
content is read fresh at flush time. A same-uid attacker who can swap a file for a symlink between
`basket add` and `basket copy` can launder a read through the victim's clipboard — but that attacker
already has same-uid write access, which means they could read the target file directly with no
dependency on the basket at all. This was reviewed and judged low-value-to-attacker before; nothing
in the current code changes that judgment. No fix recommended, same as the prior review's
conclusion — flagging only so it stays an explicit decision.

**5. Already good — subprocess construction.** `Shell.run` (`Sources/ChuteCore/Shell.swift:13-44`)
always builds `Process` with an argument array, never a shell string — grepped every
`Process()`/`Shell.run`/`Shell.launch` call site in the repo (49 sites) and found no string
concatenation into a shell command anywhere. Every AppleScript payload that embeds
user-influenced text is escaped before interpolation (see Area 2 finding #3 for the one place that
escaping is duplicated three ways, not the one place it's missing).

**6. Already good — the sandboxed-extension → unsandboxed-app privilege boundary is well built.**
`ActionInbox.isTrustworthy` (`Sources/ChuteCore/ActionRequest.swift:82-90`) checks the dropped
request file is a regular file (rejects symlinks — `FileManager.attributesOfItem` reports
`.typeSymbolicLink` for a symlink, which fails the `.typeRegular` check), owned by the invoking
uid, and has no group/other write bits, before `ChuteApp` ever acts on it. The write itself is
atomic (temp file + `replaceItemAt`, `ActionRequest.swift:58-61`). This is a genuine
confused-deputy defense, not an afterthought.

**7. Already good — file permissions are set AND repaired, not just created-with.** Every sensitive
write locks itself down explicitly rather than trusting umask or create-time defaults:
`ContextBuffer.swift:113-118` (0700 dir / 0600 files, with an explicit repair pass over pre-existing
stale files), `ActionRequest.swift:44-48` (0700, tightened even on a dir created by an older
version), `RequestInbox.swift:135` (0600), `AgentCommands.swift:223` (0600 on `.env`).

---

## 5. PUBLIC API SURFACE

225 `public func`/`struct`/`enum`/`class` declarations in `Sources/ChuteCore/*.swift` (plus ~175
more `public let`/`var` data members not separately counted — those are mostly plain struct fields,
not independently interesting surface). Cross-referenced every one of the 225 against the whole
repo (every `.swift` file under `Sources/`, tests included) for a reference outside its own
declaring file.

**Root cause worth stating up front:** a meaningful share of this 225 is public *because it has to
be* — `chutetests` is a plain `import ChuteCore`, not `@testable import` (no XCTest on this
toolchain, see Area 1), so anything the test suite touches must already be `public`. That inflates
the count; it does not make the individual findings below wrong, but it explains why the number is
225 and not smaller.

**Genuinely dead — zero references anywhere, not even self-use:**
- `SessionPhrasing.elide` — `Sources/ChuteCore/SessionPhrasing.swift:68`. Not called from any file,
  including its own.

**Public, but the only caller is in the same file (should be `internal`, not `public`):**
- `ProcessMetrics.allPIDs()` — `Sources/ChuteCore/ProcessMetrics.swift:393`, only used at line 183
  in the same file.
- `Diagnostics.endToEndProbe()` — `Sources/ChuteCore/Diagnostics.swift:275`, only used at line 231
  in the same file.
- `Trial.recordPath(home:)` — `Sources/ChuteCore/TrialState.swift:46`, only used as another
  function's default-parameter expression, in the same file.

**Type names never spelled outside their declaring file — a softer version of the same finding.
Their VALUES are consumed cross-file via type inference (so this is real surface a maintainer must
keep source-compatible), but nothing outside `ChuteCore` ever writes the type's name, meaning it
could plausibly be `internal` with zero call-site changes elsewhere:**
- `Severity` — `Diagnostics.swift:5` (consumed via `.blocker`/`.note` in `DoctorCommand.swift`,
  `FirstRunWindow.swift`, tests — never named).
- `HookReport` / `HookInstallError` — `HookInstaller.swift:3` / `:8` (consumed via `r.changed`,
  `r.backupPath` in `SessionCommands.swift:204-214` and tests — never named).
- `ChuteAction.Scope` — `FinderActions.swift:14` (consumed via `.selection`/`.folder` in
  `ChuteFinderSync.swift:187` and tests).
- `ChuteActions.Row` — `FinderActions.swift:234` (its producer, `ChuteActions.rows()`, IS called
  externally — `FinderActionsCommand.swift:38,49` — but the `Row` type name itself never is).
- `ProcessMetrics.Listing` — `ProcessMetrics.swift:222` (its producer, `ProcessMetrics.listing()`,
  IS called externally — `SystemVitals.swift:312`, tests — but `Listing` itself never is).

**Smallest fix:** drop `public` → `internal` on the four "same-file-only" symbols first (zero risk,
nothing outside `ChuteCore` references them by any spelling); delete `SessionPhrasing.elide`
outright. The five type names are lower priority — narrowing them requires confirming chutetests
doesn't need the bare name (it currently reaches them only through inferred values, so it likely
doesn't, but verify per-symbol before changing).

**Already good:** the vast majority of the 225 — everything not listed above — has a real,
name-referenced caller in `chute`, `ChuteApp`, `ChuteFinder`, or (for the harder-to-reach internals)
in `chutetests`. This is not a library with a bloated, speculative API; it is a small, mostly-used
surface with about a dozen loose ends.

---

## 6. WHAT A BUYER WOULD ASK FIRST

**(a) Is there CI, and does it actually run the gates? Yes, `.github/workflows/macos-matrix.yml`.**
Matrix over macOS 13/14/15, three real gate steps in order: `swift build -c release`, `swift run
chutetests`, `CHUTE_HEADLESS=1 ./Scripts/smoke.sh`, then it assembles the .app
(`./Scripts/build-app.sh`) and asserts the appex's Mach-O entry point exists (`nm -u ... | grep -q
_NSExtensionMain`). Both test gates propagate real exit codes (see Area 3 — `T.report()` and
`smoke.sh`'s tally-gated exit are both correct), so this is a CI that can actually go red. One real
gap: the CI's "Unit suite" step runs `swift run chutetests` — a **debug** build — while the gate
command this audit was asked to verify, and the README's own `## Development` section, both use
`swift build -c release` first. CI never runs the unit suite against a release-configuration
binary; it only smoke-tests the release build (`smoke.sh` runs against `.build/release/chute`,
`Scripts/smoke.sh:5`). Narrow, but real: a bug that only manifests under `-O` optimization would
pass CI's unit suite and only get caught by smoke.sh's narrower CLI coverage.

**(b) Is there a LICENSE, and is it consistent with "MIT CLI, paid app"? There is a LICENSE, and it
is NOT consistent.** `/Users/sxope/Documents/2026/Development/37.chute/LICENSE` is a single,
unscoped MIT license, full stop — no per-directory carve-out, no NOTICE file, no header comment in
`Sources/ChuteApp/*.swift` or `Sources/ChuteFinder/*.swift` narrowing its scope. As written, it
covers the entire repository, including the Finder-menu and menu-bar app source that's sold at $19.
README.md's prose ("This CLI is free and MIT, forever... The Finder right-click menu and the
menu-bar session switcher are the paid app," `README.md:54-55`) is marketing copy; it grants
nothing and restricts nothing on its own. As the repo stands today, anyone who clones it has an MIT
license to the paid app's source too. Fix is cheap either way: add a second `LICENSE`-equivalent
(a short proprietary NOTICE, or a per-directory `LICENSE` under `Sources/ChuteApp/` and
`Sources/ChuteFinder/`) that actually says what the README claims.

**(c) Can a stranger build this from a clean clone? Mostly yes — verified, not assumed — with one
real documentation bug found.** `swift build -c release && swift run -c release chutetests` and
`CHUTE_HEADLESS=1 ./Scripts/smoke.sh` both ran clean against this tree and matched the exact
expected tallies (898/0, 137/0 — see the top of this document). `./Scripts/build-app.sh` uses
`swiftc` directly for the `ChuteFinder` appex rather than SwiftPM (documented reason,
`build-app.sh:33-36`: the appex's entry point must be the C symbol `_NSExtensionMain`, which
SwiftPM cannot produce), and grepping that script for Xcode-only tools (`xcodebuild`, `actool`,
`iconutil`) found none — README's "Builds with Command Line Tools — Xcode is not required"
(`README.md:198-200`) holds up.

**One real break: `README.md:102`'s command reference table is stale and self-contradicting.** It
lists `` `chute buf add\|list\|flush` `` — the pre-2026-08-31 command name (`buf`, now an
undocumented alias for `basket`) with a subcommand (`flush`) that no longer exists. Two sections
earlier in the *same file*, `README.md:75-76` correctly demonstrates `chute basket add ...` /
`chute basket copy --format context`. A reader who copies the table's form instead of the earlier
example gets `chute: usage: chute basket add|list|copy|clear` on their very first try — exactly the
"two places, one truth, kept in sync by hand" pattern this codebase's own comments warn against
elsewhere. (The Aug 31 review's HIGH findings about README still documenting `chute unpack` in four
places — `docs/specs/review-code-2-FINDINGS.md:54-72` — are now fixed: grepped `README.md` for
`unpack`, zero hits.)

---

## THE TEN THINGS TO FIX, IN ORDER, WITH AN HOUR ESTIMATE EACH

1. **`License.swift:28` — replace `REPLACE_ME_BEFORE_RELEASE` with a real production public key**
   (`node worker/keygen.mjs new`), re-pin `LicenseSuite` doesn't need to change (it already tests
   its own keypair) but manually verify one real key round-trips. **1h.**
2. **LICENSE scope vs. the "MIT CLI, paid app" claim** — add a NOTICE or per-directory LICENSE so
   the paid app's source isn't accidentally granted away by the root MIT license. **2h.**
3. **`README.md:102`** — fix the stale `chute buf add|list|flush` table row to
   `chute basket add|list|copy|clear`. **0.25h.**
4. **`SessionCommands.swift:10-30` — `chute sessions` silent exit-0 on Automation denial** — call
   `Out.fail` (or a distinct non-zero exit) when `hadError` is true and the session list is empty.
   **0.5h.**
5. **`ContextBuffer.swift:125-126` / `ContextCommands.swift:116-120` — `chute basket add` claims
   success it never checked** — use `createFile`'s `Bool` return / `add()`'s `Entry?` return to
   report a real count and fail (or warn) when it's short. **1h.**
6. **`FileCommands.swift:69-70` — `cmdSeed` exits 0 even when every write failed** — track
   failures, exit non-zero when `written == 0` and rules were requested. **0.5h.**
7. **Deduplicate the three AppleScript-escape implementations** (`FinderReveal.escape`,
   `AgentCommands.swift:39-40`/`:44-45`, `ChuteFinderSync.swift:217-219`) into the one `ChuteCore`
   function all three call. **1h.**
8. **`Resources/ChuteFinder.entitlements:14`** — narrow the `/` read-write exception to `~/.chute`.
   Re-test that the extension still registers and writes after narrowing. **1h.**
9. **Split `AgentCommands.swift`'s five features** (open, sandbox, ports, env, prompt) into their
   own files, matching the one-file-per-feature pattern already used for `FileCommands.swift` /
   `GitCommands.swift` / `SessionCommands.swift`. **2h.**
10. **Close the testability gap's highest-value piece** — extract `RequestInbox.swift`'s
    confirmation/dry-run decision logic into `ChuteCore`, following the already-proven `StatusMenu`
    pattern, so `chutetests` can cover it. **4h.**

**Total: ~13.25h.** Items 1-6 are the ones a buyer or App Review would actually trip over; 7-10 are
the ones that make the next six months of solo maintenance cheaper.
