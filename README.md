# Chute

**Drop context into your agent.**

A macOS utility for people who spend all day driving coding agents. It turns a Finder selection
into agent-ready context, and turns agent output back into files.

Offline. Zero telemetry. No account. One binary and a 328 KB menu-bar app.

---

## Why

Running agents 10 hours a day means paying a tax on every loop:

| You do this | Times a day | It costs |
|---|---|---|
| Copy file paths into a prompt | 25–40 | 20 s each, plus escaping mistakes |
| Paste an LLM answer into a new file | 20–30 | 6 steps in a text editor |
| Hand-bundle several files into one prompt | 15–20 | 2 min of tab-hopping |
| Unpack a multi-file answer back onto disk | 10–20 | 2 min of copy-paste |

That is **90–120 minutes a day**. Chute removes it. See
[`docs/03-JTBD-LEDGER.md`](docs/03-JTBD-LEDGER.md) for the full arithmetic.

---

## Install

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/install.sh
```

Installs `~/Applications/Chute.app` (menu bar `⤓`, hotkey `⌥⌘N`) and `~/.local/bin/chute`.

Remove it completely at any time:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/uninstall.sh
```

**Three ways to use it:** right-click in Finder → *Services ▸ Chute – …*, the `⌥⌘N` hotkey
anywhere, or the `chute` CLI.

---

## The loop

```bash
# context in — select files in Finder, or name them
chute paths src/*.ts                 # clean absolute paths → clipboard
chute bundle src/ --format xml       # every file's contents in one blob + token count
chute tokens src/                    # will this fit the window?

# work safely
chute checkpoint .                   # snapshot everything, including untracked files
chute sandbox spike-auth --yolo      # folder + git + CLAUDE.md + terminal running claude

# artifacts out
chute unpack                         # a multi-file answer on the clipboard → real files
chute new                            # clipboard → a correctly named, correctly typed file
chute diff . --copy                  # what did the agent actually change?
```

## Every command

| Command | Does |
|---|---|
| `chute paths <files…>` | Absolute paths for a prompt. `--format posix\|quoted\|relative\|at` |
| `chute bundle <files…>` | Files + contents in one blob. `--format xml\|md` |
| `chute tokens <files…>` | Estimated token cost, per file and total |
| `chute tree [dir]` | Directory skeleton, junk excluded. `--depth N` |
| `chute new` | Clipboard → new file, named from its `# heading`, extension from its syntax |
| `chute unpack` | Fenced code blocks → a real file tree. **Previews by default**, writes with `--force` |
| `chute seed [dir]` | `CLAUDE.md`, `.cursorrules`, `AGENTS.md`, `SCRATCHPAD.md`. Never overwrites |
| `chute note "…"` | Append to `SCRATCHPAD.md` — where you left off |
| `chute latest [dir]` | Reveal the newest artifact. `--quicklook` |
| `chute clean [dir]` | List agent scratch files. **Lists by default**, Trashes with `--force` |
| `chute sandbox [name]` | Folder + git + rules + terminal + agent. `--agent claude\|codex\|gemini --yolo --each` |
| `chute open [dir]` | Terminal or editor here. `--with terminal\|editor` |
| `chute ports` | What is listening. `--kill 3000` |
| `chute checkpoint [dir]` | Snapshot before the agent runs — never touches your worktree |
| `chute diff [dir]` | What changed. `--copy` puts the patch on the clipboard |
| `chute redact` | Mask API keys and tokens before sharing |
| `chute gist <files…>` | Secret gist, URL on the clipboard |
| `chute dataurl <image>` | Base64 data URL for vision prompts. `--markdown` |
| `chute buf add\|list\|flush` | Gather context across many copies, paste once |
| `chute prompt decompose\|ponytail` | Prompt templates: split work into 15-min tasks; cut over-engineering |
| `chute env inject [dir]` | Keychain → `.env`. Refuses unless `.env` is gitignored |

Add `--no-copy` to any command to keep the clipboard untouched.

---

## Safety

Chute is built to be trusted with a repo an agent is about to rampage through.

- **`unpack` and `clean` preview by default.** Nothing is written or deleted without `--force`.
- **`unpack` refuses to escape its target directory** — absolute paths and `../` are rejected.
- **`checkpoint` cannot lose work.** It stages into a private index file, so your real index,
  your worktree and `HEAD` are never touched. It only ever adds a branch.
- **`new` and `seed` never overwrite.** Collisions become `-2`, `-3`.
- **`clean` moves files to the Trash**, never `rm`.
- **`env inject` reads the Keychain only**, prints key names but never values, and refuses to
  create a `.env` that git would track.
- **Nothing is uploaded, ever** — except `chute gist`, when you explicitly ask for it.

---

## Development

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && swift build -c release   # build
cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests      # 52 unit assertions
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/smoke.sh        # 39 end-to-end checks
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/build-app.sh    # assemble Chute.app
```

No third-party dependencies. Builds with Command Line Tools — Xcode is not required.
`swift test` is unavailable on a CLT-only toolchain (XCTest ships with Xcode), so the suite is a
plain executable with an assert harness instead.

Specs live in [`docs/`](docs/): business requirements, FR/NFR, the JTBD ledger, the customer
journey map, and the definition of done.
