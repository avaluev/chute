# SPEC — Move 4: one safety rule across the five unguarded destructive commands

Repo root: `/Users/sxope/Documents/2026/Development/37.chute`
Owner: one agent. **You own only these files. Do not touch any other file.**

- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/AgentCommands.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/GitCommands.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/SessionCommands.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/DoctorCommand.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift` (help text ONLY)

Write your findings to `/Users/sxope/Documents/2026/Development/37.chute/docs/specs/move-4-FINDINGS.md`
before you finish — your return value dies with the parent process.

## The problem, stated exactly

`clean` and `unpack` — which only Trash and only overwrite — already dry-run by default. Five
commands that do worse things have no preview and no confirmation at all. The safety convention is
applied backwards.

## THE SHAPE TO REUSE — do not invent a second one

`/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/FileCommands.swift:61-70`
(`unpack`) and `:175-181` (`clean`):

```swift
// NFR-05 — preview by default, write only with --force.
guard a.has("force") else {
    Out.info("dry run — \(candidates.count) scratch file(s):")
    candidates.forEach { Out.line("  \($0)") }
    Out.info("→ re-run with --force to delete")
    return
}
```

Flag is `--force` (`a.has("force")`). Early `return` BEFORE any mutation. Closing line is always
`Out.info("→ re-run with --force to <verb>")`. Copy this shape verbatim; the value of a convention
is that it is the same everywhere.

## The five sites

| Command | Site | What the preview must print |
|---|---|---|
| `ports --kill <port>` | `AgentCommands.swift:127` | the exact row for each pid that would die. `AgentCommands.swift:141` already draws that row — reuse the same `pad(...)` layout, do not write a second formatter. One typo from `5432` kills the user's Postgres, so the row must name the port, the kind, the project and the pid. |
| `env inject` | `AgentCommands.swift:160-185` | key **NAMES ONLY, NEVER VALUES** — these are live secrets out of the Keychain and this output goes to a terminal that may be shared or logged. Say which keys are new and which already exist in the target `.env`. |
| `gist` | `GitCommands.swift:170` | the staged file list and what redaction removed, BEFORE `gh gist create` runs. Once it is uploaded it is on GitHub whatever happens next. |
| `doctor --fix` | `DoctorCommand.swift:112-119` (`ext-started`) | the container path it will Trash and the processes it will kill (`ChuteApp`, `Finder`). |
| `hooks uninstall` | `SessionCommands.swift:184-190` | the blocks it will remove **and the backup path BEFORE the write**, not after. |

## Two correctness bugs to fix in the same pass — these ship regardless of the guard

1. **`env inject` appends blindly** (`AgentCommands.swift:180`): `existing + "\n" + lines...`, so
   running it twice duplicates every key. Merge by key — an existing `FOO=old` is REPLACED by
   `FOO=new`, key order otherwise preserved, no duplicate keys possible. This is the actual bug;
   the guard is separate.
2. **`hooks uninstall` prints the backup path after the write, and `"none"` is possible.** Read
   `HookInstaller.uninstall` in `Sources/ChuteCore/HookInstaller.swift` (you may READ it; you may
   not EDIT it — another agent owns ChuteCore this wave). Determine whether the backup is written
   before or after the destructive edit. If a backup can genuinely be absent, `hooks uninstall`
   must refuse to write rather than print `"none"`. Report what you found either way.

## `doctor --fix` — a nuance, read carefully

`--fix` is itself already an opt-in flag, so a second `--force` on top could be read as nagging.
It is still the most destructive thing in the product (Trashes a container, kills two processes).
Resolution: `doctor --fix` PREVIEWS and requires `--force`, exactly like the others. Consistency is
the entire point of this move — a convention with one exception is not a convention. State the
decision in a comment at the site.

## BREAKING CHANGE — approved by the owner, do not re-litigate

`chute ports --kill 3000` now previews instead of killing; `--force` acts. Same for the other four.
Update the help text at `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift:4-54`
so every guarded command says so. `helpText` is a hand-written literal — edit it by hand.

## Tests

`Sources/chutetests/` is owned by another agent this wave. So prove these in
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/smoke.sh` instead — it already tests CLI
behaviour end to end, and you own no test file, so **report to the parent what smoke assertions are
needed and where**; do NOT edit smoke.sh yourself. List them as exact `has`/`hasnt` lines in your
FINDINGS file. The parent will add them.

For each guarded command state in FINDINGS how you verified by hand that:
- without `--force` nothing changed on disk / no process died, and
- with `--force` it still does exactly what it did before.

## Verify
```bash
swift build -c release && swift run -c release chutetests
```
Baseline: **962 unit assertions, 0 failed.** Report the REAL numbers. Do not run `./Scripts/smoke.sh`
— it may kill things while you are mid-edit; the parent runs it.

Do NOT commit. Leave the tree dirty; the parent commits.
