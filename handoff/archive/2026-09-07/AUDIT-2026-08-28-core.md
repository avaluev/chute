# AUDIT — ChuteCore untouched subsystems — 2026-08-28

**VERDICT: not clean.** `chute redact` (and therefore `chute gist`, which uploads) misses
common real-world secret formats including GitHub's own recommended `github_pat_` token and
any lowercase/mixed-case `.env` password line; `LocalServers.parseProcessTable` mis-parses any
process path containing a space (Application Support, iCloud Drive, "Google Drive", any
folder with a space in it — all routine on macOS) and silently defeats the "climb to the
runner root and kill the whole tree" guarantee the file's own comments say was hard-won.
`Shell.run` has no timeout anywhere and has a provable stdin/stdout pipe deadlock.
`MarkdownUnpack`/`staysInside` and `HookInstaller` are the two areas that came back clean —
both were pressure-tested and held.

All fixes below are estimated at one to a few lines each. Existing suite (`swift run
chutetests`) is green at 639/639 before and after this audit (nothing here was fixed, only
found — no repo files were modified).

---

## CRITICAL

### C1 — `LocalServers.parseProcessTable` truncates any process path at the first space, silently breaking the kill-the-whole-tree guarantee
**File:** `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/LocalServers.swift:198-200`

```swift
let full = parts[2...].joined(separator: " ")
let head = full.split(separator: " ").first.map(String.init) ?? full   // BUG: drops everything after the first space
let name = head.split(separator: "/").last.map(String.init) ?? head
```

`ps -axo comm=` reports the full executable **path**, and on a real Mac that path routinely
contains a space — confirmed live on this machine:
`/Applications/Google Chrome.app/Contents/Frameworks/.../Google Chrome Helper (Renderer)`,
`/Library/Application Support/RedShieldVPN/bin/rsvd`, `/Applications/Sublime Text.app/...`.
Any dev server whose `node_modules/.bin/next` (or `npm`, `node`, etc.) lives under a path with
a space anywhere in it — Application Support, iCloud Drive
(`~/Library/Mobile Documents/com~apple~CloudDocs/...`), "Google Drive", any project folder
someone named with a space — gets its `command` field truncated to the first path segment
before the space, so it never matches `runnerCommands`, and `killSet`'s climb up the process
tree stops one level too early.

**Proven with the real code** (via a standalone SwiftPM probe at
`/private/tmp/claude-502/-Users-sxope-Documents-2026-Development-37-chute/f07c4b4f-d920-44f9-825e-9d876e0a5668/scratchpad/audit_probe`,
depending on this repo's `ChuteCore` product, `swift run audit_probe`):

```
table: [502: (ppid: 501, command: "node"), 501: (ppid: 1, command: "My")]
BUG CONFIRMED: expected command 'next', got Optional("My")
...
kill set for listener 503: [503]
BUG CONFIRMED: climb stopped early, npm parent (pid 501) NOT included — orphaned parent would respawn the server
```

This is exactly the failure class the surrounding docblock (`LocalServers.swift:139-166`)
says was already fixed once ("lsof returns the LEAF... the npm parent is still alive and
still supervising, so it respawns the child") — the space-in-path case reopens it. `Stop It`
would kill the `next-server` leaf, the `npm` root under it in `parseProcessTable` survives
because its `ppid`'s command name got mangled, and `npm` respawns the server — from the menu
this reads as "I clicked Stop It and nothing happened," which is the exact user report the
original fix was written to eliminate.

**Not covered by the existing suite** — `Sources/chutetests/LocalServersSuite.swift` has no
case with a space in any `comm` value.

**Smallest fix:** match the sibling implementation that already does this correctly one file
over (`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/SystemVitals.swift:64`,
`let command = (cols[5...].joined(separator: " ") as NSString).lastPathComponent`). Replace the
two-line truncate-then-basename with one line:
```swift
let name = (full as NSString).lastPathComponent
```

---

## HIGH

### H1 — `Redact` misses GitHub's own recommended token format and every lowercase/mixed-case `.env`-style secret
**File:** `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Redact.swift`

Verified end-to-end through the real `chute redact` CLI (built at
`/Users/sxope/Documents/2026/Development/37.chute/.build/arm64-apple-macosx/debug/chute`) and
against `Redact.apply` directly. Every line below survives redaction verbatim and would be
uploaded as-is by `chute gist` (`Sources/chute/Commands/GitCommands.swift:158`, which calls
`Redact.apply` then hands the result to `gh gist create`):

```
github_pat_<redacted-example>
db_password=hunter2
Db_Password=hunter2
aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Server=myServerAddress;Database=myDataBase;Uid=root;Pwd=hunter2;
```

Two distinct root causes, both at `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Redact.swift`:

1. **`github_pat_` fine-grained PAT — line 8.** `gh[pousr]_` only matches the five *classic*
   prefixes (`ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`). GitHub's current recommended token type,
   `github_pat_…`, is a completely different shape and is never matched. Given the task
   explicitly names `github_pat_` as a format to check, this is the headline miss.
   **Fix:** add `#"github_pat_[A-Za-z0-9_]{20,}"#` to `patterns`.

2. **`envAssignment` is case-sensitive — line 23.** `[A-Z0-9_]*(?:KEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL)[A-Z0-9_]*` requires the
   key to be uppercase. Real `.env` files, docker-compose files, and JSON/YAML-derived env
   dumps routinely use lowercase or mixed-case keys (`db_password`, `Db_Password`,
   `aws_secret_access_key`) — none of these are redacted.
   **Fix:** add `(?i)` to the pattern (drop the now-redundant `A-Z` character class or keep it
   and add the flag — either works since `(?i)` makes `A-Z` match lowercase too).

3. **Connection-string `key=value;key=value;` format (SQL Server/ODBC style) — no line-start
   assumption.** `Server=x;Uid=root;Pwd=hunter2;` is a single line with multiple
   semicolon-delimited assignments; `envAssignment`'s `(?m)^` anchor only ever looks at what
   starts a *line*, so only the first `key=value` pair on a line is ever a candidate, and here
   that's `Server=x` — the `Pwd=hunter2` further along the same line is never reached. This is
   one of the two connection-string formats the task explicitly calls out.
   **Fix:** drop the `^` anchor (or add an alternation that also matches after `;`/whitespace)
   so the key/value pattern isn't restricted to line starts.

---

## MEDIUM

### M1 — `Redact` misses Stripe secret keys and password-only (`redis://:pass@host`) URLs
**File:** `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Redact.swift`

- `sk_live_<redacted-example>` (Stripe live secret key) survives —
  the `sk-` pattern (line 7) requires a hyphen; Stripe's prefix uses an underscore
  (`sk_live_`/`sk_test_`), a completely different family from OpenAI's `sk-`. **Fix:** add
  `#"sk_(live|test)_[A-Za-z0-9]{20,}"#`.
- `redis://:hunter2@cache.example.com:6379/0` survives — `urlCredentials`
  (`://[^\s:/@]+:[^\s/@]+@`, line 20) requires at least one character before the colon for the
  username; Redis/Heroku-style URLs with no username (just `:password@`) have zero characters
  there and never match. **Fix:** change `[^\s:/@]+` (the username group) to `[^\s:/@]*` to
  allow an empty username.
- `ASIA<redacted-example>` (AWS **temporary** access key ID, `ASIA…`) survives — only the
  long-term `AKIA…` prefix (line 9) is matched. **Fix:** widen to
  `#"A[SK]IA[0-9A-Z]{16}"#`.

None of these are catastrophic on their own (an access-key-*ID* or a Stripe key alone still
needs an account to exploit), but they're squarely inside the set of formats the product
promises to catch, and Stripe keys in particular are extremely common in local `.env`/log
output during development.

### M2 — `Shell.run` has no timeout anywhere, and has a provable pipe deadlock for any future caller with `input:`
**File:** `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Shell.swift`

1. **No timeout, ever.** `p.waitUntilExit()` (line 40) and both `readDataToEndOfFile()` calls
   (lines 37-38) block forever if the child never exits or never closes its pipes. There is no
   `Process.terminationHandler`, no watchdog, nothing — confirmed by grepping the whole repo
   for `timeout`/`asyncAfter` near any `Shell.run` call site; the only timeout-flavored code in
   the tree is unrelated UI code in the excluded `ChuteApp`/`ChuteFinder` targets.
   `Shell.run` backs `LocalServers.discover()` (`LocalServers.swift:109,113`),
   `SystemVitals.sample()` (`SystemVitals.swift:116`), `TerminalAppAdapter.discover()`
   (`TerminalAppAdapter.swift:45`), `HookState.liveTTYs()` (`HookState.swift:74`), and
   `Diagnostics.liveEnv()` (`Diagnostics.swift:161-170`, an `osascript … tell application
   "Finder"` call). A concrete real-world trigger: on a machine where Automation permission for
   Finder or Terminal hasn't been granted yet, `osascript` can block indefinitely on the
   permission-prompt dialog rather than returning immediately — every one of these call sites
   would hang the whole menu-bar refresh with no way out short of force-quit.
   **Fix:** wrap the wait/read in a `DispatchQueue` + `asyncAfter` watchdog that calls
   `p.terminate()` (and `kill -9` if that doesn't land) after a fixed deadline (a few seconds is
   plenty for `lsof`/`ps`/`pluginkit`/`osascript`), and return a synthetic non-zero
   `ShellResult` on timeout instead of hanging the caller.

2. **Provable stdin/stdout deadlock.** `Shell.run` writes the *entire* `input` string
   synchronously (`Shell.swift:30`) **before** it starts draining the child's stdout
   (`Shell.swift:37-38`). If `input` is larger than the pipe buffer (~64 KB) and the child needs
   to write output back before it has consumed all of stdin, both processes block forever:
   the child is stuck writing output nobody is reading, and `Shell.run` is stuck writing input
   the child isn't yet reading. Proven directly against the real function (same probe harness):
   `Shell.run("cat", [], input: <20 MB string>)` never returns (still hung past an 8s
   watchdog). The only current caller of `input:` in production code is
   `Clipboard.write` → `Shell.run("pbcopy", …)` (`Shell.swift:62`), and `pbcopy` produces no
   stdout, so this specific deadlock is not reachable today — but it is a landmine baked into
   shared infrastructure for the next caller that pipes input into anything that also writes to
   stdout (e.g. a future `| jq`, `| grep`, or similar). **Fix:** move the input write onto the
   same background queue used for stderr (or its own queue) so all three of stdin-write,
   stdout-drain, and stderr-drain run concurrently, matching the comment already at
   `Shell.swift:32-34` that explains why stderr had to be handled this way.

---

## LOW

### L1 — `MarkdownUnpack.validate` aborts the *entire* batch on the first unsafe path, even in preview/dry-run
**Files:** `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/MarkdownUnpack.swift:49-57`,
called from `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/FileCommands.swift:58-59`

`validate` throws on the *first* bad path across the whole `[UnpackedFile]` array, and the
caller's `catch { Out.fail(...) }` calls `exit(1)` — so one `../escape.txt` code block
anywhere in an LLM's answer prevents every other, perfectly safe file in the same paste from
being written or even previewed. Not a security bug (fail-safe direction), but a usability
trap: a big multi-file agent answer with one adversarial or accidentally-bad path silently
loses all the good ones. **Reproduced:** a two-block paste (one `src/passwd.txt`, one
`../escape.txt`) produces only `chute: refusing to write outside the target directory:
../escape.txt` and writes nothing, including the safe block. **Smallest fix:** have
`validate` filter out (and report) only the unsafe entries rather than throwing on the whole
batch — or have the caller catch per-file instead of calling `validate` on the full array.

### L2 — `AWS_SECRET_ACCESS_KEY`-shaped values are only caught via the `.env` heuristic, not a dedicated pattern
**File:** `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Redact.swift`

The actual AWS secret (the 40-char base64-ish string paired with an `AKIA…`/`ASIA…` access key
ID) has no distinctive shape of its own, so it can only ever be caught incidentally by
`envAssignment` matching a line like `AWS_SECRET_ACCESS_KEY=...` — which (per H1) only works
for uppercase keys, and not at all if the secret appears bare (e.g. pasted into chat without
its variable name, or as a positional CLI argument). No general fix is realistic without an
unacceptable false-positive rate on random base64 strings; flagging as a known, low-priority
gap rather than a code defect.

### L3 — Slack `xapp-…` app-level tokens not covered
**File:** `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Redact.swift:12`

`xox[baprs]-…` covers bot/user/legacy/refresh/other Slack token families but not the newer
`xapp-1-…` app-level token format. Low volume in practice (app-level tokens are rarer in
day-to-day pastes than `xoxb-`), but a one-line addition (`#"xapp-[0-9]-[A-Za-z0-9\-]{10,}"#`)
would close it.

---

## Areas checked with NO findings

- **`MarkdownUnpack.swift` path-escape resistance (hunt item 2):** CLEAR. Reproduced live
  against the real `chute unpack --force` binary from
  `/private/tmp/claude-502/-Users-sxope-Documents-2026-Development-37-chute/f07c4b4f-d920-44f9-825e-9d876e0a5668/scratchpad/unpack_test`:
  a symlinked `src -> <outside dir>` with a `src/passwd.txt` code block was refused
  ("resolves elsewhere"), a `../escape.txt` path was refused by `validate` before any write,
  a `~/pwned.txt` path was refused, and an absolute `/tmp/absolute_pwn.txt` path was refused
  and confirmed not created on disk. The double `staysInside` check (before and after `mkdir`,
  `FileCommands.swift:77` and `:83`) genuinely does what its comment says. A literal newline
  inside a path is not reachable through the parser at all — every path is extracted from an
  already `\n`-split line, so there is no code path that could hand a multi-line string to
  `validate`/`staysInside` as a single "path." (Backslash-based `..\..\` traversal is not
  meaningful on macOS/APFS since `\` isn't a path separator there, so it was not pursued
  further.)

- **`HookInstaller.swift` crash/corruption resistance (hunt item 4):** CLEAR. Reproduced live
  against the real `chute hooks uninstall` binary at
  `/Users/sxope/Documents/2026/Development/37.chute/.build/arm64-apple-macosx/debug/chute`
  (scratch files under
  `/private/tmp/claude-502/-Users-sxope-Documents-2026-Development-37-chute/f07c4b4f-d920-44f9-825e-9d876e0a5668/scratchpad/hook_test`):
  invalid JSON is refused untouched (file byte-for-byte unchanged); a non-object `hooks` key is
  refused untouched; a normal settings file with one Chute block and one unrelated user block
  is edited correctly — only the exact Chute-authored `Stop` block is removed, the user's
  `SessionStart` block and the unrelated top-level key both survive, and a timestamped backup
  is written *before* the real file is touched. The real write path
  (`HookInstaller.swift:195-198`) writes to a `.chute-tmp` sibling file and only then calls
  `FileManager.replaceItemAt`, which performs an atomic rename — so a crash before that call
  leaves the original untouched, and a crash during it cannot produce a half-written
  `settings.json` (the original is either still the pre-write version or the fully-written
  post-write version, never a torn mix). `HookInstaller` never writes anything beyond the one
  backup file it explicitly reports (`HookReport.backupPath`) and the settings file itself.

- **`LocalServers.parse(lsof:)` malformed-input resistance:** CLEAR of crashes. Empty input,
  header-only input, too-few-columns lines, and lines with a malformed address all resolve to
  an empty result via `guard`/`continue`, never a trap. A pid of `999999999999` parses fine
  (`Int` is 64-bit). Real `lsof -nP -iTCP -sTCP:LISTEN` output on this machine truncates
  `COMMAND` to ≤9 characters with no embedded spaces, so the "process name with a space" risk
  that's real for `parseProcessTable` (see C1) does not apply to this function.

- **`SystemVitals.parse(ps:)` malformed-input resistance:** CLEAR. Empty input, absurdly large
  cpu/rss values, and a negative pid (accepted as a value but not a crash) all pass through
  without trapping. Process names with embedded spaces/parentheses (e.g.
  `next-server (v16.1.1)`, the exact case the file's own comment calls out) are handled
  **correctly** here — `cols[5...].joined(separator: " ")` then `lastPathComponent` preserves
  the full name. This is the correct pattern that C1 should be made to match.

- **`TerminalAppAdapter.parse` malformed-input resistance:** CLEAR. A non-numeric window ID,
  too few US-delimited fields, and empty input all yield `[]` via `compactMap`/`guard`, no
  crash.

- **`HookState.parse` malformed-input resistance:** CLEAR. Empty data, non-JSON data, a JSON
  array instead of an object, missing fields, and wrong field types all return `nil`. An
  absurd/overflowing `ts` (`1e300`) and a negative `ts` are both accepted as *parsed* (not a
  crash), but `StateResolver.resolve`'s existing `age >= 0` guard
  (`StateResolver.swift:36-38`) already treats any hook timestamped in the future as
  untrustworthy, so a garbage `ts` cannot pin a false state — this is exactly the defense the
  file's own comment describes.

- **hunt item 6 (`try!`/`as!`/force-unwrap/unguarded index):** none found in any of the 11
  in-scope files. Every array index and dictionary/JSON cast in this file set is behind a
  `guard`/`?`/`??`. (`Diagnostics.swift:90`'s `all[0]` fallback is the one bare index, but
  `all` is a fixed non-empty static literal, so it cannot trap.)

---

## Verification

- `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests` →
  `✅ 639 assertions passed` (green before and after this audit; no repo files were touched).
- Throwaway probes used, all under `/private/tmp` and none committed:
  - `/private/tmp/claude-502/-Users-sxope-Documents-2026-Development-37-chute/f07c4b4f-d920-44f9-825e-9d876e0a5668/scratchpad/secrets_corpus.txt`,
    `dotenv_corpus.txt` — fed through the real `chute redact` binary.
  - `/private/tmp/claude-502/-Users-sxope-Documents-2026-Development-37-chute/f07c4b4f-d920-44f9-825e-9d876e0a5668/scratchpad/unpack_test/` —
    symlink/`..`/`~`/absolute-path escape attempts fed through the real `chute unpack --force`.
  - `/private/tmp/claude-502/-Users-sxope-Documents-2026-Development-37-chute/f07c4b4f-d920-44f9-825e-9d876e0a5668/scratchpad/hook_test/` —
    malformed/normal settings.json fixtures fed through the real `chute hooks uninstall`.
  - `/private/tmp/claude-502/-Users-sxope-Documents-2026-Development-37-chute/f07c4b4f-d920-44f9-825e-9d876e0a5668/scratchpad/audit_probe/` —
    a standalone SwiftPM package (`.package(path: "/Users/sxope/Documents/2026/Development/37.chute")`)
    that links the real `ChuteCore` library and calls its pure parsing functions directly
    (`parseProcessTable`, `killSet`, `LocalServers.parse`, `SystemVitals.parse`,
    `HookState.parse`, `TerminalAppAdapter.parse`, `Redact.apply`, `Shell.run`) with the
    adversarial inputs cited above.
