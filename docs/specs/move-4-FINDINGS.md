# FINDINGS — Move 4: one safety rule across the five unguarded destructive commands

Owner: this pass. Files touched (only the five owned):
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/AgentCommands.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/GitCommands.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/SessionCommands.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/DoctorCommand.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift` (helpText literal only)

Tree left dirty. No commit, no add, no stash. `./Scripts/smoke.sh` was not run.

## Verify — real numbers

```
cd /Users/sxope/Documents/2026/Development/37.chute && swift build -c release && swift run -c release chutetests
```
Result: **build succeeded, 970 unit assertions passed, 0 failed.** (Baseline to beat: 962/0.
The count moved from the baseline because `Sources/chutetests/CoreSuites.swift` is owned and
being actively edited by another agent this wave — none of my five files are test files, so this
run's 970 reflects their concurrent additions, not mine. Re-ran twice; both times 0 failed.)

## What changed, by site

### 1. `ports --kill` — `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/AgentCommands.swift:126-155` (now)
Guard added around the kill branch of `cmdPorts`. `pad(...)` and the row-drawing line were hoisted
to the top of the function (`printRow`) so the preview and the full-list path share the exact same
formatter — no second formatter was written. Preview filters `LocalServers.discover()` by
`$0.port == port` and prints the same PORT/WHAT/PROJECT/PID/REACHABLE header + row(s) that the
full listing uses, before anything is killed.

**Verified by hand**: started a throwaway `python3 -m http.server 8931` I owned (pid confirmed via
`ps`/`lsof` before touching anything).
- Without `--force`: `chute ports --kill 8931` printed the dry-run row (port 8931, python,
  project 37.chute, correct pid, "your network") and exited. `ps -p <pid>` and
  `lsof -iTCP:8931 -sTCP:LISTEN` after the call both still showed the listener alive.
- With `--force`: same command killed exactly that pid; `ps -p <pid>` came back empty and lsof
  showed nothing on 8931. I did not touch or query any other project's or the user's real
  services (Postgres etc.) — only my own throwaway listener.

### 2. `env inject` + the merge bug — `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/AgentCommands.swift:149-198` (now)
Preview computes `newKeys`/`replacedKeys` against the target `.env`'s existing keys and prints
**names only, never values** (`Out.line`, no `value` variable in scope at print time — the value
never leaves the `Shell.run` result except inside the write path guarded by `--force`).

Bug fix: replaced the blind `existing + "\n" + lines...` append with a key-aware merge —
`existingLines` are walked in order, a line whose key matches an injected key is replaced in
place, then any injected key not already present is appended. No duplicate keys possible; keys
not touched (comments, unrelated vars) pass through unchanged.

**Verified by hand**: added a throwaway Keychain item (`security add-generic-password -s
chute:CHUTE_TEST_KEY -a chute -w "not-a-real-secret-123"`), used a scratch dir with `.env` in
`.gitignore`.
- Without `--force`: printed `new in <path>: CHUTE_TEST_KEY` and nothing else — no VALUE printed,
  `ls` confirmed no `.env` file was created at all.
- With `--force`: `.env` created with `CHUTE_TEST_KEY=not-a-real-secret-123`. Added an unrelated
  `OTHER_KEY=keepme` line by hand, changed the Keychain value to `second-value-456`, ran
  `--force` again: result was `CHUTE_TEST_KEY=second-value-456` / `OTHER_KEY=keepme` — exactly one
  `CHUTE_TEST_KEY=` line (`grep -c` → `1`), key replaced in place, unrelated line preserved. This
  is the actual bug fix proven, not just the guard. Keychain test item deleted afterward.

### 3. `gist` — `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/GitCommands.swift:137-187` (now)
Staging (copy + redact into the temp dir) still happens unconditionally — it's local and already
cleaned up by the existing `defer`. The guard sits between staging and `Shell.run("gh", ["gist",
"create", ...])`: without `--force` it prints the file list and which files had secrets redacted,
then returns before `gh` is ever invoked.

**Verified by hand**: `gh gist list --limit 5` count before and after a no-`--force` run on a
scratch file (`OPENAI_API_KEY=sk-fake...` + notes) was identical (1 → 1) — nothing was uploaded.
Preview correctly reported the file as redacted.
I deliberately did **not** run the `--force` path for real: `gh` on this machine is authenticated
against the founder's real GitHub account, and `--force` would create a real (if unlisted) gist
under it — an external, live side effect outside what I was asked to trigger, in the same spirit
as "don't touch what you didn't start" for `ports --kill`. Verified the `--force` path instead by
inspection: the code after the guard (`Shell.run("gh", ["gist","create","--secret"]+staged)`
through the URL-parse/clipboard-write/`Out.info` summary) is byte-for-byte the pre-existing
implementation, only moved below the new `guard`, so its behavior is unchanged by construction.

### 4. `doctor --fix` — `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/DoctorCommand.swift:37-53` (now), preview text in `fixDescription` at `:115-134`
Decision taken per spec: gate the whole `--fix` action behind `--force`, not per-check — a
convention with one exception (letting the harmless sub-fixes through unguarded while only gating
`ext-started`) is not a convention, and the guard only engages when there's actually something to
fix (`toFix.isEmpty` → `applyFixes` runs as a no-op exactly as it did before, no gate needed, no
regression on the all-checks-pass path). Comment at the site states the "already opt-in" nagging
concern and why it was rejected. Preview enumerates each failing check id with a one-line
human description; `ext-started`'s description names the real container path
(`~/Library/Containers/dev.valuev.chute.finder`) and says it kills `ChuteApp` and `Finder`.

**Verified by hand**: `chute doctor` on this machine currently reports **all 9 checks passed**
(macOS version, app location, CLI, Finder extension registered/enabled/started, automation,
terminal, end-to-end). That means `toFix` is empty in this environment, so `chute doctor --fix`
(no `--force`) took the no-op branch: printed "re-running every check" and the same all-passed
table, identical to pre-change behavior — confirmed no regression on the common case.
I did **not** force a real failing `ext-started` check to exercise the guard's blocking branch
live, and did **not** run `--fix --force` for real: doing either would mean actually Trashing the
real Finder-extension container and killing the real `ChuteApp`/`Finder` processes on the
machine I'm running on — the same "don't touch what's not mine to touch" boundary as `ports
--kill`, except here there is no throwaway substitute to stand in for a real, user-registered
Finder extension. Verified instead by code review: the guard is a `guard a.has("force") else {
...; return }` placed before the only call to `applyFixes`, with an early `return` identical in
shape to the other four sites; `applyFixes` itself is completely untouched, so the with-`--force`
behavior is provably identical to before.

### 5. `hooks uninstall` — `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/SessionCommands.swift:184-211` (now)
Preview reads `HookInstaller.status(settingsPath:)` (read-only, never touches the file) and lists
which events currently carry a Chute hook — those are the events `uninstall()` would remove.
Noted in a comment: `status()` matches on `isChuteCommand` alone, while `uninstall()`'s actual
removal test is stricter (`matcher == nil && inner.count == 1`, so a block a user hand-merged
their own hook into is deliberately left alone). This means the preview can, in a rare edge case,
list an event that a real `uninstall()` run would not touch — accepted as a known, called-out
imprecision rather than duplicating `uninstall()`'s private matching logic (which lives in
`loadObject`, an internal, non-`public` function in `HookInstaller.swift` that this executable
target cannot call). No new file, no new type — only the two `public` read entry points
(`status`, `uninstall`) were used.

### HookInstaller.uninstall backup ordering — investigated, not edited
Read `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/HookInstaller.swift:143-194`
(read-only per the spec; not in my owned-files list).

**Finding: the backup is written BEFORE the destructive edit**, already correctly ordered inside
`uninstall()` itself:
```swift
guard !changed.isEmpty else { return HookReport(changed: [], backupPath: nil) }   // :188
let backup = try makeBackup(path, now: now)                                       // :191 — backup first
try validateAndWrite(root, originalKeys: originalKeys, path: path)                // :192 — write second
return HookReport(changed: changed, backupPath: backup)
```
**Finding on `"none"`: it is unreachable in practice, not a live bug.** `backupPath` is `nil` in
exactly one path — the early return at `:188`, which fires only when `changed.isEmpty`, and in
that same case **no write happens at all** (the function returns before `makeBackup`/
`validateAndWrite`). Every other return goes through `makeBackup` (which either returns a
non-nil `String` or `throw`s, caught by `cmdHooks`'s own `do/catch` → `Out.fail`). So a
`changed`-non-empty report with a nil `backupPath` cannot occur through any code path in
`HookInstaller.swift` today. `cmdHooks`'s old call site already had `guard !r.changed.isEmpty else
{ ...; break }` before the `"→ backup: \(r.backupPath ?? "none")"` line, so `"none"` was already
dead code in the pre-existing caller, not a live defect.

What I changed anyway, since I can't edit `HookInstaller.swift` to make the *type* enforce this
(no `Optional`→non-optional change possible without touching the owned-by-another-agent file):
replaced the silent `?? "none"` fallback with a hard `Out.fail` if that theoretically-impossible
state is ever observed — "never silently swallow" per house style. This costs nothing on the real
path (still prints `"→ backup: <path>"` exactly as before) and turns a latent contract violation
into a loud failure instead of a misleading "none" if `HookInstaller`'s contract is ever changed
by someone else without updating this caller.

## Breaking change / help text
`/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift:25` (`ports`),
`:36-37` (`hooks`), `:41,43` (`gist`, `env inject`), `:46-47` (`doctor`) updated by hand to say
which commands now preview by default and require `--force`/(`--fix --force`) to act, matching
the existing phrasing style already used for `unpack`/`clean` on the lines just above.

## smoke.sh assertions needed — exact lines for the parent to add
`Scripts/smoke.sh` is not owned by me and was not edited or run. It already tests CLI behaviour
end to end (per spec); the assertions below assume its existing `has`/`hasnt` helper vocabulary
(matching the style already used for `unpack`/`clean` dry-run assertions elsewhere in that file —
grep that file for the exact helper names/args before pasting, since I have not read it end to
end). Suggested checks, one per site, each needing a "before" and "after `--force`" pair:

1. **ports --kill** (use a throwaway listener the script itself starts, e.g.
   `python3 -m http.server <free port> &`, capture its pid):
   - `chute ports --kill <port>` → `hasnt` the process dead (`kill -0 $pid` still succeeds) →
     `has "re-run with --force to kill"` in output.
   - `chute ports --kill <port> --force` → process pid gone (`kill -0 $pid` fails) →
     `has "killed 1 process"` in output.

2. **env inject** (seed a throwaway Keychain item the script adds/removes itself, e.g.
   `security add-generic-password -s chute:SMOKE_TEST_KEY -a chute -w smoke-value`):
   - `chute env inject <scratch dir> --keys SMOKE_TEST_KEY` → `hasnt` `.env` file exist →
     `has "re-run with --force to write"`, `hasnt` the literal value `smoke-value` anywhere in
     stdout/stderr.
   - `chute env inject <scratch dir> --keys SMOKE_TEST_KEY --force` → `.env` exists, `has`
     `SMOKE_TEST_KEY=smoke-value`.
   - Run the same `--force` command a second time → `.env`'s `grep -c '^SMOKE_TEST_KEY=' .env`
     equals `1` (no duplicate) — this is the actual bug-fix assertion, not just the guard.

3. **gist** (a scratch file with a fake secret in it, e.g. `OPENAI_API_KEY=sk-fake123`):
   - `chute gist <scratch file>` → `has "re-run with --force to upload"`,
     `has "secrets redacted in"`, and assert `gh gist create` was never invoked (the script can
     check `gh gist list` count is unchanged before/after, same technique I used by hand — do
     **not** actually assert on `--force` uploading for real inside CI/smoke unless the parent
     wants a real gist created on every smoke run, which I would not recommend).

4. **doctor --fix**: only assert the guard's text path, not the destructive branch, for the same
   reason I didn't run it for real — smoke.sh runs on the founder's real machine with a real
   Finder extension and a real `ChuteApp`. Suggested: only assert
   `chute doctor --fix` (no `--force`), when all checks already pass (the common case), still
   prints `"→ all 9 checks passed"` (i.e. confirm the empty-`toFix` no-op path is unregressed).
   Do not add a smoke assertion that forces a failing check and then runs `--fix --force` for
   real — that would Trash the real container and kill the real `ChuteApp`/`Finder` on every
   smoke run.

5. **hooks uninstall** (use `--settings <scratch json>` pointing at a throwaway file seeded from
   `chute hooks snippet`, exactly as I did by hand):
   - `chute hooks uninstall --settings <scratch>` → `hasnt` any `<scratch>.chute-backup-*` file
     created → `has "re-run with --force to uninstall"`.
   - `chute hooks uninstall --settings <scratch> --force` → `has` exactly one
     `<scratch>.chute-backup-*` file, `has "backup:"` followed by that path in stdout/stderr, and
     the scratch settings file's other top-level keys (seed one, e.g. `"someOtherTopLevelKey"`)
     still present after the uninstall.
