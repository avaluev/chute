# Review — 7f2f701..HEAD (c1178d8..ef27363)

Method: read the full diff (1724 lines), traced every call site of the five gated commands and
`Out.deliver`, read `MarkdownUnpack.swift`/`FileCommands.swift` end to end for the traversal
question, then verified by running the gates and, for the top finding, by building the release
binary and executing the exact broken code path against a scratch fixture.

Gates run, all green, matching the stated baselines:
- `swift build -c release` — builds clean.
- `swift run -c release chutetests` — `992 assertions passed`.
- `CHUTE_HEADLESS=1 ./Scripts/smoke.sh` — `146 passed, 0 failed`.
- `./Scripts/smoke.sh` — `174 passed, 0 failed`.

---

## 1. [HIGH — same shape as the "Fix These" bug, in a sibling command's sibling caller]

`Scripts/uninstall.sh:16` still calls `chute hooks uninstall` with no `--force`. `hooks uninstall`
gained the same dry-run gate as `doctor --fix` in this session
(`Sources/chute/Commands/SessionCommands.swift:243-249`, commit 8581be3), and this caller was never
updated to match — unlike `Scripts/install.sh:104` (updated for `doctor --fix --force`) and
`Scripts/smoke.sh:214/224` (updated to pass `--force`).

Failure scenario: a user with legacy Chute (<=0.1.0) hooks in `~/.claude/settings.json` runs
`./Scripts/uninstall.sh`. Line 16 now only PREVIEWS the removal (prints "dry run — would remove…",
writes nothing, exits 0); the `2>/dev/null` on that line silences even the dry-run message, so
there is no visible sign anything was skipped. The script then deletes the `chute` binary two
lines later (`rm -f "$HOME/.local/bin/chute"`) and the app bundle, so the one remaining chance to
clean the hooks is gone. The dangling `chute-session-state` hook blocks — which invoke
`$HOME/.chute/sessions`, a directory `rm -rf "$HOME/.chute"` on the next line just deleted — stay
in the user's Claude settings forever, silently, on every future Claude Code session.

Verified directly (not just read): built `.build/arm64-apple-macosx/release/chute`, seeded a
scratch `settings.json` via `chute hooks snippet` (the real marker format,
`# chute-session-state\n...`), then ran the exact call `Scripts/uninstall.sh:16` makes:

```
$ chute hooks uninstall --settings settings.json      # no --force, exactly what uninstall.sh runs
dry run — would remove Chute's hook(s) from settings.json:
  PermissionRequest
  SessionStart
  Stop
  UserPromptSubmit
→ a timestamped backup of settings.json is written before any change · re-run with --force to uninstall
$ echo $?
0
$ grep -c chute-session-state settings.json
1        # still there — nothing was removed
```

Fix: `Scripts/uninstall.sh:16` needs `--force` appended, the same edit already made to
`Scripts/install.sh:104`.

---

## Checked, found sound (no finding)

- **`Out.deliver(record:)`** (`Sources/chute/Args.swift:80`): only `buf all|flush`
  (`Sources/chute/Commands/ContextCommands.swift:133`) passes `record: false`, correctly — it is
  the one caller whose text is a join of existing buffer entries. Every other `Out.deliver` call
  site produces fresh content and keeps the default `record: true`.
- **`Diagnostics.Severity`**: `DoctorCommand.swift`'s `blocked`/exit-code/`skipped` logic all
  correctly gate on `.check.severity == .blocker`, not bare `!passed`. `FirstRunWindow.swift`
  re-filters to blockers inside `makeBody` even though `showIfNeeded` hands it the unfiltered
  failing set, so notes (`cli`, `terminal`, `hooks`) never render as alarming rows.
  `Onboarding.swift:65`'s `blockers = run.filter { !$0.passed }` is unfiltered by severity, but the
  only two `.check(id)` steps that consume it are `ext-enabled` and `cli` — matched by exact id,
  never by severity — so the stale name doesn't produce a wrong result today.
- **`MarkdownUnpack.pathFromBody`**: traced every path it can produce through `validate` (rejects
  `/`, `~`, and any `..` component) and `staysInside` (symlink-resolved parent check, applied
  before and after `mkdir`). Tried leading `/etc/passwd`, `~/x`, and `../../etc/passwd` behind each
  of the six comment markers — all caught by `validate`, matching the new unit tests. The marker
  list (`//`, `#`, `--`, `;`, `/*`…`*/`, `<!--`…`-->`) has no entry that is a literal prefix of
  another, so iteration order in the strip loop never mismatches an opener.
- **`ContextBuffer` writes from `paste-image`**: the rename-path cleanup
  (`Sources/chute/Commands/ImageCommands.swift:76`) filters by `$0.text == path`, where `path` is
  the exact, freshly `writeUniquely`-generated path this same invocation just recorded — it cannot
  match an entry it did not create.
- **Shell quoting**, `Scripts/smoke.sh` §23-24 and `Scripts/build-app.sh`'s stamp lines: all
  variable expansions are double-quoted; `BUILD`/`BUILT_AT` only ever contain
  `[0-9a-f]`/`-dirty`/ISO-8601 characters, safe inside the unquoted plist heredocs. No injection or
  word-splitting issues found.

No CRITICAL issues found. The one HIGH finding above is a real regression, not style.
