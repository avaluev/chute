# Security review — `git diff 258f7ab..HEAD` (5 commits: 5b0bc54..4a71302)

Scope: the Context Basket rewrite (`ContextBuffer.swift`), the new `CHUTE_BUFFER_DIR` env var,
and the deletion of `MarkdownUnpack.swift`. Build: `swift build -c release` (clean, current HEAD),
`.build/release/chutetests` → `919 assertions passed, 0 failed`. All exploits below were run
against the real `.build/release/chute` binary in scratch dirs under `/tmp/chute-sec-review/`
(deleted after use), pointed there via `CHUTE_BUFFER_DIR` — the real `~/.chute/buffer` was never
touched. No real secrets were used (a throwaway string stood in for `id_rsa`).

**No CRITICAL issue found. One MEDIUM (by-design, worth a documented decision) and two LOW/
informational items below.** Item 3 in the task brief (`MarkdownUnpack.swift` deletion) is
**clean — PROVEN nothing else needed its guards.**

---

## 1. MEDIUM — `CHUTE_BUFFER_DIR` is a live, unguarded production env var, not test-only — PROVEN

`Sources/ChuteCore/ContextBuffer.swift:49` — `ContextBuffer.init` reads
`ProcessInfo.processInfo.environment["CHUTE_BUFFER_DIR"]` unconditionally, in every build
configuration, with no `#if DEBUG`, no allow-list, and no check that the value resolves under
`NSHomeDirectory()`. The doc comment above it says "Not a general setting, not documented in
`chute help`: tests only" — but nothing in the code enforces that; it is read by the exact same
`ContextBuffer()` the shipped GUI app (`Sources/ChuteApp/main.swift`, four call sites) and the
shipped CLI (`Sources/chute/Commands/ContextCommands.swift:112`) both construct with no arguments.

**Proved:** pointing `CHUTE_BUFFER_DIR` at an arbitrary `/tmp` path via the release binary silently
redirects the entire basket store there — reads, writes, `list`, `copy`, `clear`, including the
0700/0600 lockdown and the stale-file-mode repair — with zero indication in `chute basket list`
or the menu-bar UI that the store is not `~/.chute/buffer`.

**Impact, honestly scoped:** this is *not* a privilege escalation — `ContextBuffer` runs with the
invoking user's own uid, so it can only write where that uid could already write directly (a
`createDirectory` under, say, `/etc` fails the same way `mkdir` would). The real risk is **same-uid
confused-deputy / covert redirection**: anything already running as the same user (a compromised
shell profile, a malicious `postinstall` script, a tampered LaunchAgent, an IDE's "integrated
terminal env" setting) can export this var once and thereafter (a) make `chute basket clear`,
`add`, `copy` silently operate on a decoy directory while the user believes they're managing their
real basket, and (b) pre-seed that decoy directory with attacker-chosen `path` entries, so the next
time the user runs "Copy Basket as Context" and pastes into an agent chat, they exfiltrate
attacker-chosen file contents through their own action (see also §2 — same precondition, same
caveat: an attacker with same-uid code execution can already read anything the user can read
directly, so this mostly changes the exfiltration *channel* — clipboard/agent-paste instead of
direct network egress — not what is reachable).

**Fix:** either compile it out of release builds (`#if DEBUG`) as the comment already claims, or —
if it must survive in the shipped binary for `Scripts/smoke.sh` to exercise the release
binary — validate `resolvingSymlinksInPath()` on the value lands under
`(NSHomeDirectory() as NSString).appendingPathComponent(".chute")`, and/or ignore it entirely in
`ChuteApp` (the GUI process never needs it; only the CLI test harness does) so the attack surface
shrinks to "the test suite's own subprocess," which is the stated intent.

---

## 2. LOW/informational — basket entries are unpinned paths: TOCTOU/symlink-swap is REACHABLE
but low-value to an attacker who already has it — PROVEN reachable, judged not to matter much

Per the task's framing (this is explicit, accepted design — "content is read at flush time"), and
confirmed by reading `Sources/ChuteCore/ContextBuffer.swift:59-74` (`entries()`/`add()` store
`{ts, path}` only, no inode/mtime/hash pinning) and `:118-125` (`bundleText()` re-reads from disk
at flush time via `ContextBundle.assemble` → `FileScan.bundleFiles`).

**Proved, in `/tmp/chute-sec-review/toctou/`:**
1. `chute basket add notes.txt` (a harmless placeholder).
2. `rm notes.txt; ln -s fake_id_rsa notes.txt` (swap to a symlink pointing at a stand-in secret).
3. `chute basket copy --format context --no-copy` → the stand-in secret's content came back under
   `<file path="notes.txt">`, verbatim.

**Judgment (explicitly, as asked):** this reaches what the task described, but it does not raise
the bar for an attacker who can already win it: swapping a file for a symlink at just the right
moment requires the same same-uid write access that would let the attacker read the real secret
(`~/.ssh/id_rsa`, `.env`, etc.) directly and exfiltrate it themselves, with no dependence on the
victim's timing or on them ever running `basket copy`. The basket doesn't grant new *read* access;
it only launders the read through the victim's own clipboard/agent-paste action (relevant mainly if
the attacker specifically wants to avoid their own process doing outbound network exfil — see the
same caveat in §1). Given the basket's own design principle ("a path recorded once, content read
live" is stated intentionally in the source comments as the whole point of storing paths instead of
blobs), adding content-pinning would contradict that design (a file that legitimately changed
between add and copy — the common case — should show the new content, not stale content). **No fix
recommended beyond documentation** — this is a judgment call the product already made deliberately;
flagging it here so it's an explicit decision, not an unnoticed gap.

---

## 3. `MarkdownUnpack.swift` deletion — CLEAN, PROVEN by grep + full-repo review

Confirmed independently (the dev's own `docs/specs/move-5-FINDINGS.md` says the same, cross-checked
here rather than trusted blind):

```
$ grep -rn "staysInside\|MarkdownUnpack\|UnpackedFile\|UnpackError" Sources/
Sources/chutetests/CoreSuites.swift:71-72   (a comment noting the removal, not a call)
Sources/ChuteCore/FinderActions.swift:180   (a comment noting the removal, not a call)
Sources/chute/Commands/FileCommands.swift:46 (a comment noting the removal, not a call)
```

No executable code anywhere in the repo calls `.validate(`, `.staysInside(`, `MarkdownUnpack.parse`,
or references `UnpackedFile`/`UnpackError`. I additionally walked every remaining
`write(toFile:...)`/`createFile(atPath:...)` call site in the repo
(`Sources/ChuteApp/RequestInbox.swift`, `Sources/ChuteCore/ContextBuffer.swift`,
`Sources/ChuteCore/Diagnostics.swift`, `Sources/chute/Commands/{AgentCommands,FileCommands,
GitCommands}.swift`) to check whether any of them write a file to a caller-supplied *relative*
path built from untrusted free text — the exact class of bug `validate`/`staysInside` guarded
against. None do: every remaining write target is either a fixed filename
(`README.md`, `CLAUDE.md`, template names from a static `Templates.fileName(for:)` lookup) appended
to a directory the *code* chose, or a path built from `(file as NSString).lastPathComponent`
(strips any `../` the input contained) inside `cmdGist`'s staging dir. **Nothing lost its
protection because nothing else needed it — this deletion is safe.**

Separately confirmed for the new `basket add` path specifically (task item 1, sub-question "can a
path be recorded that points outside anything the user selected"): via the CLI, yes — `chute
basket add <any path>` records whatever the invoking process names, including `/etc/passwd`,
`../../../../etc/passwd` (stored literally, unresolved — proved by reading the raw JSON), or
`/dev/zero` (proved: no hang, no crash, reads back as 0 bytes since `Data(contentsOfFile:)` sizes
from `stat()`). **This is correct, not a gap**: `basket add` only ever *reads* a path the invoking
user/process already named; unlike `MarkdownUnpack`, there is no confused-deputy step where
untrusted third-party text (an LLM's answer, a pasted webpage) gets parsed into a path and then
*written to*. Via the Finder `basket-add` action specifically, `files` comes only from
`FIFinderSyncController.default().selectedItemURLs()` (`Sources/ChuteFinder/ChuteFinderSync.swift:186`)
— the live Finder selection at click time — filtered to absolute paths again in
`ActionInbox.parse` (`Sources/ChuteCore/ActionRequest.swift:75`), so a Finder click cannot name a
path outside the selection. (A separate, pre-existing, unchanged-by-this-diff trust boundary: any
process running as the *same uid* can write directly into `~/.chute/requests` and trigger any
Finder action including `basket-add` with arbitrary `files` — `ActionInbox`'s own comment already
documents this as "owner-only... nothing running as ANOTHER user can drop work in," i.e. explicitly
scoped to same-uid attackers only, same caveat as §1/§2.)

---

## Directory/file permissions — PROVEN correct, including repair of a pre-existing bad install

```
$ chmod 755 buffer/ ; chmod 644 buffer/*.json      # simulate a pre-fix install
$ chute basket add newfile.txt
$ ls -ld buffer/ ; ls -l buffer/
drwx------  .../buffer
-rw-------  ...  (both the old file AND the new one are now 0600)
```
Fresh installs land 0700/0600 directly; a pre-existing 0755/0644 install is repaired on the very
next `add`, for both the directory and every stale `.json` file already inside it — matches the
code comment's claim exactly (`Sources/ChuteCore/ContextBuffer.swift:82-91`).

## Hostile/malformed JSON in the buffer dir — PROVEN, no crash

Tried directly against the release binary: truncated JSON, a top-level JSON array instead of an
object, `"path"` present but wrong type (a number), non-JSON garbage text, raw binary bytes, and a
100,000-deep nested-array JSON file. **All were silently skipped — `basket is empty`/no crash, no
hang** (`entries()`'s `compactMap` guard at `Sources/ChuteCore/ContextBuffer.swift:66-72` fails
closed on any of these). A 50MB single entry (`path` = 50MB of repeated bytes) also parsed and
printed without crashing (`basket list` completed in 0.3s) — worth noting only as a minor,
non-blocking DoS-shaped edge case: there is no length cap on the `path` field, so a hostile file
placed directly in the buffer dir (already requires same-uid write access to get there) can bloat
`basket list`/`copy` output; low severity given the precondition, not fixed.

## What else was checked and found fine

- `PathFormat.render`/mention output for paths containing embedded newlines (`chute basket add
  "$(printf 'a\nb\nc')"`) — stores and echoes the newline literally in `basket list`; this is a
  CLI-output-formatting quirk (a maliciously-named argument can inject extra lines into `chute`'s
  own stdout), not a boundary crossing — the string only ever came from the invoking process's own
  argv, same trust level as every other CLI argument in this tool.
- `chute basket add` dedup-on-path, `keep = 10` eviction, and `clear` — all behave as documented,
  no residual files left with wrong permissions after eviction.

## Tree state

Read-only review. No files edited except this one. Not committed.
