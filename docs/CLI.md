# The command-line tool

**Free and MIT, forever. The same engine as the app, for people who prefer a terminal to a
right-click.**

It is not a second product competing with Chute's two surfaces — it is the objection-handler:
read the source, run it, and decide for yourself before you trust an app built on top of it.
The app is documented in [the README](../README.md); this page is the terminal reference.

```bash
brew install avaluev/tap/chute
```

```bash
# context in — select files in Finder, or name them
chute paths src/*.ts                 # clean absolute paths → clipboard
chute bundle src/ --format xml       # every file's contents in one blob + token count
chute tokens src/                    # will this fit the window?

# work safely
chute checkpoint .                   # snapshot everything, including untracked files
chute sandbox spike-auth --yolo      # folder + git + CLAUDE.md + terminal running claude

# artifacts out
chute basket add src/*.ts            # collect files across folders
chute basket copy --format context   # hand them over to the agent
chute new                            # clipboard → a correctly named, correctly typed file
chute diff . --copy                  # what did the agent actually change?
```

### Every command

| Command | Does |
|---|---|
| `chute paths <files…>` | Absolute paths for a prompt. `--format posix\|quoted\|relative\|at` |
| `chute bundle <files…>` | Files + contents in one blob. `--format xml\|md` |
| `chute tokens <files…>` | Estimated token cost, per file and total |
| `chute tree [dir]` | Directory skeleton, junk excluded. `--depth N` |
| `chute new` | Clipboard → new file, named from its `# heading`, extension from its syntax |
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
| `chute basket add\|list\|copy\|clear` | Collect files across folders, hand them over once — `copy` gives `@mentions` or the files themselves |
| `chute prompt decompose\|ponytail` | Prompt templates: split work into 15-min tasks; cut over-engineering |
| `chute env inject [dir]` | Keychain → `.env`. Refuses unless `.env` is gitignored |
| `chute sessions` | Every terminal session, grouped by state. `--json` |
| `chute focus <key\|project\|N>` | Bring that session to the front. Asks when a name matches several |
| `chute hooks status\|snippet\|merged\|uninstall` | Agent status hooks. `merged` prints your settings with them added; Chute never writes that file — the command it gives you does |
| `chute resume [key\|N]` | The command to pick that conversation up again. `--tmux` |
| `chute doctor` | Check the install and say how to fix what fails. `--fix --json` |
| `chute onboard` | What Chute is, and the first thing to try |

Add `--no-copy` to any command to keep the clipboard untouched.

### Sessions and hooks, from a terminal

The menu bar's session list and its hook wiring are both one command away, for anyone who would
rather check a terminal than open the menu:

```bash
chute sessions          # → 9 session(s), 2 need you
chute focus studylock   # by project name — asks if several match, never guesses
chute focus 3           # or by the number sessions printed
chute doctor            # what is not wired up yet, and the exact fix
```

```bash
chute hooks status            # read-only: what is wired now
chute hooks snippet           # prints the JSON, AND the one command that merges it for you
chute hooks merged            # your whole settings.json with the hooks added — on STDOUT.
                              # Chute never writes that file; the command `snippet` prints
                              # pipes this into place, backing yours up first
chute hooks uninstall         # removes exactly the blocks OLD Chute versions added (≤0.1.0
                              # wrote them) — backs up first, touches nothing of yours
```

The hook commands themselves only ever write to `~/.chute/sessions/` and always exit 0, so a
Chute failure can never break an agent session.

Every command, with what it does: `chute help` in your terminal, or the reference at
[chutedev.com/docs](https://chutedev.com/docs).

---

