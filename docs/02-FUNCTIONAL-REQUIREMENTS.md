# FR — Chute v0.1

One CLI (`chute`) is the product. Every frontend (Quick Actions, menu-bar HUD, future FinderSync
extension, Raycast) shells out to it. All commands read a Finder selection or the clipboard,
transform, and write to the clipboard or disk.

Legend: **T1** = tier 1 (ship first) · **T2** = tier 2 · dry-run = destructive commands preview by default.

| FR | JTBD | Command | Behaviour |
|---|---|---|---|
| FR-01 | 1 | `chute paths <files…> [--format posix\|quoted\|relative\|at] [--sep line\|space]` | **T1** Absolute POSIX paths to stdout + clipboard. `quoted` shell-escapes; `relative` is relative to the common ancestor; `at` prefixes `@`. Appends a token badge. |
| FR-02 | 2 | `chute bundle <files…> [--format xml\|md]` | **T1** Emits `<file path="…">content</file>` per file (or fenced markdown). Skips binaries. Appends a token badge. |
| FR-03 | 24 | `chute tokens <files…>` | **T1** Estimated token count, total + per file. |
| FR-04 | 3 | `chute new [--name N] [--dir D] [--ext E]` | **T1** Creates a file from the clipboard. Name derived from the first `# heading`; extension from detected syntax. Never overwrites — de-duplicates with `-2`, `-3`. |
| FR-05 | 4 | (library) `LanguageDetect` | **T1** Maps content → extension: json, py, swift, ts, js, sql, sh, yaml, html, css, rb, go, rs, java, md, txt. Powers FR-04 and FR-06. |
| ~~FR-06~~ | ~~9~~ | RETIRED 2026-08-31 | Was the unpack command: fenced blocks with a path hint → a file tree. Removed when the ICP was settled as Claude Code / Cursor users, whose agent writes files to disk itself, so the job never occurs for them. `MarkdownUnpack` and its `validate`/`staysInside` guards went with it. See `docs/specs/move-5-delete-unpack.md`. |
| FR-07 | 8 | `chute open <dir> [--with terminal\|editor\|auto]` | **T1** Opens the folder in the detected terminal (Ghostty → iTerm → Warp → Terminal.app) or editor (Cursor → VS Code). |
| FR-08 | 6 | `chute sandbox <name> [--dir D] [--agent claude\|codex\|gemini] [--yolo]` | **T1** mkdir → `git init` → seed README + CLAUDE.md → open terminal → run the agent. `--yolo` adds the agent's skip-permissions flag. |
| FR-09 | 12 | `chute checkpoint [dir]` | **T1** Commits all current work onto `chute/checkpoint-<ts>`, then returns HEAD to the original branch. Never discards anything. |
| FR-10 | 5 | `chute tree <dir> [--depth N]` | **T2** ASCII tree honouring `.gitignore` + junk denylist. |
| FR-11 | 7 | `chute seed <dir> [--rules claude,cursor,agents,ponytail,scratchpad]` | **T2** Writes agent rule files. Never overwrites an existing file. |
| FR-12 | 10 | `chute latest <dir> [--quicklook]` | **T2** Reveals the most recently modified non-junk file in Finder. |
| FR-13 | 11 | `chute diff <dir> [--copy]` | **T2** `git diff --stat` summary; `--copy` puts the full patch on the clipboard. |
| FR-14 | 13 | `chute clean <dir> [--force]` | **T2** Lists junk/untracked scratch files. **Deletes only with `--force`.** |
| FR-15 | 15 | `chute ports [--kill PORT]` | **T2** Lists dev-server ports in use; `--kill` terminates the holder. |
| FR-16 | 16 | `chute note "<text>" [--dir D]` | **T2** Appends a timestamped block to `SCRATCHPAD.md`. ADHD anchor: Goal / Blockers / Next. |
| FR-17 | 17 | `chute prompt decompose [file]` | **T2** Puts a 15-minute-task decomposition prompt on the clipboard. |
| FR-18 | 18 | `chute prompt ponytail` | **T2** Puts an anti-over-engineering counter-prompt on the clipboard. |
| FR-19 | 19 | `chute redact [files…]` | **T2** Masks `sk-ant-`, `sk-`, `ghp_`, `gho_`, `AKIA`, Bearer tokens, JWTs and `.env` values. |
| FR-20 | 20 | `chute gist <files…>` | **T2** `gh gist create --secret`, URL to the clipboard. |
| FR-21 | 21 | `chute sandbox --each <dirs…>` | **T2** Launches an agent in each selected folder. |
| FR-22 | 22 | `chute basket add\|list\|copy\|clear` | **T2** The Context Basket at `~/.chute/buffer` — collect files across folders, hand over once. Stores PATHS, not copies of content, so `copy` reads them fresh: `--format mentions` (default) gives `@src/a.ts @lib/b.ts` for an agent, `--format context` gives the same bundle `chute bundle` produces. `buf` is a kept alias. |
| FR-23 | 23 | `chute dataurl <image>` | **T2** Base64 data URL / markdown image to the clipboard. |
| FR-24 | 14 | `chute env inject <dir> [--keys A,B]` | **T2** Reads keys from the macOS Keychain only. Aborts unless `.env` is gitignored. Prints key **names**, never values. |

## Frontends
| ID | Requirement |
|---|---|
| FE-01 | Finder context menu via a `FIFinderSync` extension embedded in `Chute.app` — top level, works on empty background. Supersedes the withdrawn Automator Quick Actions and app `NSServices` attempts (see `docs/superpowers/specs/2026-08-26-findersync-context-menu-design.md`). |
| FE-02 | `Chute.app` — `LSUIElement` menu-bar app, global hotkey `⌥⌘N`. |
| FE-03 | `Scripts/uninstall.sh` removes the app, the extension, `~/.chute`, and any stale `.workflow` bundles from earlier installs. |
| FE-04 | Menu bar shows the **agent session switcher**: every terminal window/tab, grouped by state, coloured per project, with a badge counting sessions that need you; click a row to focus it, or `chute focus <n>` (the ⌥1…⌥8 key equivalents were removed — AppKit matches on the character a keystroke PRODUCES, and ⌥1 produces "¡", so they could never fire) (see `docs/superpowers/specs/2026-08-26-session-switcher-design.md`). |
| FE-05 | `chute hooks install\|uninstall\|status` wires Claude Code hooks that report session state. Append-only, backed up, idempotent, reversible. |
