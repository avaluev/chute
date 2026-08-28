# Chute

**Drop context into your agent.**

A macOS utility for people who spend all day driving coding agents. It turns a Finder selection
into agent-ready context, and turns agent output back into files.

Offline. Zero telemetry. No account. No launch daemon, no background service, and not one line
of network code.

![Copy files and contents from Finder, with a token count](marketing/media/bundle.gif)

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

The free, MIT command-line tool:

```bash
brew install avaluev/tap/chute
```

The Chute.app (Finder menu, menu-bar switcher, hotkey):

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/install.sh
```

Installs `~/Applications/Chute.app` (menu bar `⤓`, hotkey `⌥⌘N`) and `~/.local/bin/chute`.

Remove it completely at any time:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/uninstall.sh
```

**Three ways to use it:** right-click in Finder → **Chute ▸**, the `⌥⌘N` hotkey anywhere, or the
`chute` CLI.

The Finder menu is a sandboxed `FIFinderSync` extension inside the app. `install.sh` registers and
enables it for you; if it ever goes missing, tick it in System Settings → Privacy & Security →
Extensions → Finder → ☑ Chute, or run `pluginkit -e use -i dev.valuev.chute.finder`.

---

## The loop

![An agent's markdown answer becomes a real file tree](marketing/media/unpack.gif)


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
| `chute ports` | Every local server: port, what it is, which project, reachable from where. `--kill 3000` |
| `chute checkpoint [dir]` | Snapshot before the agent runs — never touches your worktree |
| `chute diff [dir]` | What changed. `--copy` puts the patch on the clipboard |
| `chute redact` | Mask API keys and tokens before sharing |
| `chute gist <files…>` | Secret gist, URL on the clipboard |
| `chute dataurl <image>` | Base64 data URL for vision prompts. `--markdown` |
| `chute buf add\|list\|flush` | Gather context across many copies, paste once |
| `chute prompt decompose\|ponytail` | Prompt templates: split work into 15-min tasks; cut over-engineering |
| `chute env inject [dir]` | Keychain → `.env`. Refuses unless `.env` is gitignored |
| `chute sessions` | Every terminal session, grouped by state. `--json` |
| `chute focus <key\|project\|N>` | Bring that session to the front. Asks when a name matches several |
| `chute hooks snippet\|uninstall\|status` | Agent status hooks — printed for YOU to paste; Chute never edits your settings |
| `chute doctor` | Check every prerequisite and say how to fix it. `--fix --json` |

Add `--no-copy` to any command to keep the clipboard untouched.

---

## Which agent is waiting for you

![Sessions grouped by whether they need you](marketing/media/sessions.gif)


```bash
chute sessions          # → 9 session(s), 2 need you
chute focus studylock   # by project name — asks if several match, never guesses
chute focus 3           # or by the number sessions printed
chute doctor            # what is not wired up yet, and the exact fix
```

The menu bar `⤓` carries the count of sessions that want you. Click it for the list, colour-coded
per project. Click a row to bring that terminal forward, or use `chute focus <name|N>` from
anywhere.

**The badge needs hooks to be interesting, and wiring them is your call, made by your hand.**
Without them Chute can only read the terminal title glyph and the busy flag, so every session
reads `working` and the badge stays dark. With them, Claude Code reports `blocked` (a permission
prompt) and `waiting` (your turn) as they happen.

**Chute never writes to `~/.claude/settings.json` — or to any other tool's configuration.**
Your agent setup is fragile and it is yours; no menu-bar utility should be editing it, however
carefully. So:

```bash
chute hooks status            # read-only: what is wired now
chute hooks snippet           # prints the JSON — paste it into settings.json yourself,
                              # or add the same commands via Claude Code's /hooks menu
chute hooks uninstall         # removes exactly the blocks OLD Chute versions added (≤0.1.0
                              # wrote them) — backs up first, touches nothing of yours
```

The hook commands themselves only ever write to `~/.chute/sessions/` and always exit 0, so a
Chute failure can never break an agent session.

Only live terminals count toward the badge: a hook record from a window you have since closed is
ignored, so the number never inflates behind your back.

---

## What is running locally

The menu bar lists every local server, so you never again hunt for which of six terminals holds
port 3000:

```
Local servers (8)
  :3000 · next · studylock       ▸ Open in Browser · Copy the URL · Stop It (kill 55868)
  :5432 · postgres
```

Each row names the port, what the process actually is, and the project folder it is running in.
`chute ports` prints the same list, and says whether each one is reachable from your whole network
or only from this Mac. `chute ports --kill 3000` frees a port.

macOS's own background listeners (AirPlay on 7000, `rapportd` on a random high port) are left out —
they are never what the question "what is running?" means.

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
cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests      # 751 assertions
cd /Users/sxope/Documents/2026/Development/37.chute && CHUTE_HEADLESS=1 ./Scripts/smoke.sh  # 128 passed
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/smoke.sh        # + the Finder/Terminal sections
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/build-app.sh    # assemble Chute.app
```

No third-party dependencies. Builds with Command Line Tools — Xcode is not required.
`swift test` is unavailable on a CLT-only toolchain (XCTest ships with Xcode), so the suite is a
plain executable with an assert harness instead.

Specs live in [`docs/`](docs/): business requirements, FR/NFR, the JTBD ledger, the customer
journey map, and the definition of done.
