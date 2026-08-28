# Security review — c1178d8..ef27363 (`git diff 7f2f701..HEAD`)

Scope: the 6 commits enumerated in the task. Build: `swift build -c release` (clean),
`.build/release/chutetests` → `992 assertions passed`. All exploit attempts below were run
against the real `.build/release/chute` binary in scratch directories under
`/private/tmp/claude-502/.../scratchpad/`, never against real `~/.env`/home data. One throwaway
Keychain item (`chute:CHUTE_SECURITY_REVIEW_KEY`) was created and deleted after use.

**No CRITICAL or HIGH exploitable security issue was found.** One PROVEN reliability bug (fails
*closed*, not open — but on the exact safety message this session is meant to be trusted) and one
PROVEN defense-in-depth gap are reported below, plus a full list of what was tried and found safe.

---

## 1. HIGH (reliability / false-positive on the escape guard) — PROVEN

`Sources/ChuteCore/MarkdownUnpack.swift:63-71` (`staysInside`, not touched this session, but now
hit far more often by the new `pathFromBody` fallback at `Sources/ChuteCore/MarkdownUnpack.swift:119-130`,
since a nested path like `src/a.ts` — the shape the commit message says agents actually emit — is
exactly the case that trips it).

**Exploit path (none — this is a false REFUSAL, not an escape):** when the `--dir` target resolves
through macOS's `/tmp → /private/tmp` (or `/var → /private/var`) BSD compatibility symlink — i.e.
any dir under the default `$TMPDIR`, or any dir the user names starting with `/tmp` — and the
proposed file's parent subdirectory does not exist yet, `staysInside` refuses the write and prints
"refusing to write outside ‹dir›: ‹path› resolves elsewhere", even though nothing is escaping.
Cause: `root = URL(fileURLWithPath: dir).resolvingSymlinksInPath()` resolves an *existing* `dir`
and Foundation collapses it to the short `/tmp/...` form, while `parent =
full.deletingLastPathComponent().resolvingSymlinksInPath()` resolves a *non-existent* subdirectory
and returns the long `/private/tmp/...` form — the two normalized strings never share a prefix.

Proved directly:
```
$ printf '```\n# notes/hello.md\nhello world\n```\n' | chute unpack --stdin --dir /private/tmp/.../t1 --force
refusing to write outside /private/tmp/.../t1: notes/hello.md resolves elsewhere
```
Standalone repro of the exact two `URL` calls (`/private/tmp/claude-502/.../installedbuild-fuzz.swift`
sibling script) confirms `root.path` = `/tmp/...` vs `parent.path` = `/private/tmp/...` for the
identical inputs. Pre-creating the subdirectory first makes it succeed (`t4/notes` case), and a
flat filename with no subdirectory also succeeds (`t3/hello.md` case) — isolating the bug to
"nested path + not-yet-existing parent + root resolved through /tmp or /var".

**Impact:** every nested file in a multi-file agent response is silently dropped (`continue`, no
partial write, no crash) whenever the user unpacks into a temp/scratch/CI/sandbox directory — a
very common location for exactly the "drop an agent's output" workflow this tool exists for — and
the user sees the tool's own safety message on a completely legitimate write, which teaches them
to distrust or work around that message on the day it fires for a real escape.

**Fix:** don't resolve `root` and `parent` independently. Walk `full`'s ancestors up to the
nearest one that already exists, resolve *that* directory's symlinks (so it goes through the exact
same Foundation code path `root` does), and compare against `root` resolved the same way — e.g.
resolve `dir` itself lazily too, or normalize both sides with the same `/private/tmp` ⇄ `/tmp`
(and `/private/var` ⇄ `/var`) collapsing before comparing.

---

## 2. LOW (defense-in-depth) — PROVEN, not currently exploitable on stock macOS

`Sources/chute/Commands/GitCommands.swift:147` (`cmdGist`, unchanged in this diff — the redaction
timing changed, the staging directory creation did not).

```swift
let stage = NSTemporaryDirectory() + "chute-gist-\(UUID().uuidString)"
try FileManager.default.createDirectory(atPath: stage, withIntermediateDirectories: true)
```

No `attributes:` is passed, so `stage` is created at the process umask default. Verified directly:
`755` (world-readable + world-executable). Non-text files (images, archives) are copied into
`stage` **unredacted** ("Not UTF-8 text … upload as-is", `GitCommands.swift:160-162`), and this
staging happens unconditionally — even in dry-run — before the `defer` cleanup at function return.

Not currently exploitable: `NSTemporaryDirectory()` on this Mac is `/var/folders/.../T/`, which is
`700` owned by the user (`stat -f "%A %Su" $TMPDIR` → `700 sxope`), so another local account
cannot traverse into it regardless of `stage`'s own mode. But that protection is incidental to
`$TMPDIR`'s default, not to this code. If `TMPDIR` is ever `/tmp` itself (world-readable, sticky
bit only blocks deletion) — plausible in a CI runner, a Docker container, or a shell profile that
exports `TMPDIR=/tmp` — the staged files, for the full duration of the `gh gist create` network
upload, become readable by any other local user who can list `/tmp` and guess/observe the
`chute-gist-<uuid>` name.

**Fix:** `withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700]` on that one
`createDirectory` call.

---

## 3. INFORMATIONAL, pre-existing — not verified as exploitable

`Sources/chute/Commands/AgentCommands.swift` (`cmdEnv`, near the end): `mergedText.write(toFile:
atomically: true, ...)` is followed by a separate `setAttributes([.posixPermissions: 0o600], ...)`
call. `atomically: true` writes to a temp file at the process umask default (commonly `644`) then
renames over the target; the `chmod 0600` only applies after that rename. There is a narrow window
where a `.env` holding live secrets is briefly more permissive than 0600. This pattern is
unchanged by this session's diff (only the surrounding merge logic is new) and I did not attempt
to race it — flagging since the task asked specifically to verify final mode, which I did confirm
is `0600` on every completed run (see §5 below).

---

## Areas run and PROVEN safe

**§4 `Scripts/build-app.sh` build stamp** — no injection possible. `$BUILD` is only ever
`git rev-parse --short HEAD` output (hex, optionally `-dirty`) or the literal `unknown`; `$BUILT_AT`
is a fixed `date -u +%Y-%m-%dT%H:%MZ` format. Neither can contain XML metacharacters, and branch/ref
*names* are never interpolated into the heredoc at all — only the resolved commit SHA is, so a
"crafted branch name" has no path into this stamp. Confirmed the safety net that would catch it
anyway works: fed `plutil -lint` a plist with an unescaped `&`, got `exit 1` with a parse error, and
`build-app.sh` runs under `set -euo pipefail` with `plutil -lint` immediately after each heredoc —
a malformed plist aborts the build rather than shipping.

**§2 `env inject`** — ran dry-run, `--force`, and replace-in-place (same key re-injected after
rotating the Keychain value) end-to-end with a real throwaway Keychain item, plus a pre-existing
`.env` containing an unrelated line and a stale key not present in the Keychain this run. Verified:
secret value never appeared in stdout/stderr on any path (dry-run, force-write, missing-.gitignore
failure), never touched the clipboard, never touched `~/.chute/buffer`; unrelated existing line
(`EXISTING_UNRELATED=keepme`) and the untouched stale key were both preserved byte-for-byte; the
new/rotated key replaced its line in place with no duplicate line; final file mode was `600` on
every write.

**§3 `chute gist` redaction preview** — ran the dry-run path (no `--force`, which still executes
staging+redaction, only skips the actual `gh gist create`) against a file containing fake
Anthropic- and AWS-shaped key strings. Preview output was file paths and "secrets redacted in:
‹path›" only — the raw matched secret text never appeared in stdout, clipboard, or buffer. Did not
run the real upload (`gh` was authenticated to the operator's actual GitHub account; creating a
real gist was out of scope and would leave an external artifact).

**§5 `ContextBuffer` / `paste-image` / `Out.deliver(record:)`** — `Sources/ChuteCore/ContextBuffer.swift`
itself is unchanged this session and still enforces `0700` on `~/.chute/buffer` and `0600` on each
entry file (confirmed live: `stat -f "%A" ~/.chute/buffer` → `700`). The new writes in this diff
(`Sources/chute/Commands/ImageCommands.swift`, the `record: false` flag in `Sources/chute/Args.swift`)
only ever store filesystem paths (pasted-image path) or already-public data (a gist URL) — nothing
newly written there is a secret. The `record: false` addition on `buf all`/`flush` fixes a
duplication bug (a buffer flush re-filing itself), not a security issue.

**§6 `Diagnostics.installedBuild`** — `appPath` is only ever `Bundle.main.bundlePath` (system-
supplied) or a test fixture (`Sources/chutetests/DiagnosticsSuite.swift:201-211`); no current
caller passes user-controlled input, so there is no live path-traversal surface today. Fuzzed the
exact `NSDictionary(contentsOfFile:) → dict["ChuteBuild"] as? String` logic
(`Sources/ChuteCore/Diagnostics.swift:194-201`) against six hostile `Info.plist` files — empty,
5 KB random bytes, wrong root type (array), wrong value type (nested dict), 20,000-deep nested
`<array>`, and a 50 MB oversized `<string>` — all six returned `nil` or a harmless (if large)
string with no crash, hang, or excessive resource use (worst case parsed in under a second).

**§1 `MarkdownUnpack.pathFromBody` — actual escape attempts** — all of the following either hit
`validate()` (`Sources/ChuteCore/MarkdownUnpack.swift:49-57`) or landed as a harmless literal
filename inside the target dir, with **no write outside the target directory in any case**:
`~sxope/pwned.txt` (rejected — leading `~`), `//etc/pwned.txt` (rejected — leading `/`),
`a\..\..\..\etc\pwned.txt` (backslash is not a POSIX separator — written as one literal, ugly,
in-bounds filename), `./pwned.txt` (normalized to `pwned.txt`, in-bounds), a Unicode fullwidth-dot
lookalike for `..` (`．．/pwned.txt` — filesystems don't special-case it; written as a literal
folder named `．．`, in-bounds), and a NUL byte followed by `../../etc/pwned.txt` (the full string,
NUL included, is still scanned by `validate`'s `/`-split, so the `..` component after the NUL is
still caught — rejected). The symlink-escape guard was verified for **both** an existing path
source and the new `pathFromBody` source: a symlink `evil → outside-dir` pre-placed in the target
directory, with the path proposed via a leading `// evil/pwned.txt` comment inside the fenced body,
was correctly refused and nothing was written outside. The shebang guard added this session
(`!s.hasPrefix("!")`, `MarkdownUnpack.swift:81`) was verified live: a fenced `#!/bin/bash` script no
longer creates a directory named `!`. `--files-from` is not wired to `cmdUnpack` at all
(`Sources/chute/Commands/FileCommands.swift:48-94` — no such flag is read there) — not applicable.

---

## Files touched by this review

Read only. Findings file: `/Users/sxope/Documents/2026/Development/37.chute/docs/specs/review-security-FINDINGS.md`.
No source file was edited; no commit was made.
