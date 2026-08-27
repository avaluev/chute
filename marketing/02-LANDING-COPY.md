# Landing page copy

## Hero
# Drop context into your agent.
### Select files in Finder. Get agent-ready context. Paste an answer back. Get real files.
**[Download for macOS — free 14-day trial]**  ·  Offline · No account · no telemetry

*20-second loop above the fold: select 8 files → right-click → Bundle Context → paste into
Claude Code → the token badge shows ~14k. No narration, no cuts.*

---

## The tax (three cards)

**25–40× a day**
You copy file paths into a prompt. Option-right-click, Copy as Pathname, fix the quoting, repeat.
→ `chute paths` — one action, any number of files, correctly escaped.

**20–30× a day**
You paste an answer into a new file. Open the editor, ⌘N, ⌘V, ⌘S, find the folder, type a name.
→ `chute new` — named from its heading, extension from its syntax, straight into the folder.

**10–20× a day**
You unpack a multi-file answer by hand, block by block.
→ `chute unpack` — the whole file tree at once. Previews first. Never writes outside the folder.

---

## Built to be trusted with a repo an agent is about to rampage through

- Destructive commands **preview by default**. Writing takes `--force`.
- `unpack` **refuses to escape** its target directory.
- `checkpoint` snapshots everything, **including untracked files**, without touching your index,
  your worktree, or `HEAD`. It can only ever add a branch.
- `clean` moves to the **Trash**, never `rm`.
- Nothing is uploaded. Ever. There is no network code except the gist command you invoke.

---

## Three surfaces, one tool
**Finder right-click** for what your hands are already doing · **`⌥⌘N`** anywhere ·
**`chute` CLI** for everything else. Same engine.

---

## Pricing
### Free for 14 days. $19 once after that.
The command-line tool is free forever. The Chute.app (Finder menu, hotkey, menu-bar switcher) is the paid surface. No subscription, no telemetry. 30-day refund, no questions.

## FAQ
**Does it phone home?** No. There is no network code except `chute gist`, which you invoke.
**Does it need Xcode?** No. It is a 2.5 MB app and a 788 KB binary, built with the Command Line Tools.
**Does it work with Cursor / Aider / Codex / Gemini?** Yes — the output is plain text and files.
`sandbox` launches claude, codex or gemini; anything else takes one flag.
**macOS version?** 13 Ventura and later, Apple Silicon and Intel.
