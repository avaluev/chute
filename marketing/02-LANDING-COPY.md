# Landing page copy

> Rewritten 2026-09-01 for the ICP. The old hero was "Select files in Finder. Get agent-ready
> context. **Paste an answer back. Get real files.**" Half of that sentence sold `unpack`, which
> was deleted on 2026-08-31 — a Claude Code user's agent writes its own files.

## Hero

# Your agent can read anything. You still have to tell it what.
### Select the folders. Right-click once. Every file inside is on your clipboard with a token count.
**[Download for macOS — free 14-day trial]**  ·  Offline · No account · No telemetry

*20-second loop above the fold: select three folders → right-click → Copy Files as Context →
paste into Claude Code → the badge reads 41 files · ~14k tokens. No narration, no cuts.*

---

## The tax (three cards — highest number first, always)

**17× a day · 150 s each**
You feed it the folder one file at a time. Open, ⌘A, ⌘C, switch, paste, type the filename above
it, go back for the next one.
→ **Copy Files as Context** — one right-click, every file, one blob, token count included.
**41.1 min/day.**

**32× a day**
You type a path into a prompt and get it wrong. Option-right-click, Copy as Pathname, fix the
quoting, repeat for the other two.
→ **Copy Full Paths** — any number of files, correctly escaped, absolute or relative.
**9.1 min/day.**

**Across three folders and four minutes**
The files you want are not in one place, and there is no way to hold a selection while you go
and find the rest.
→ **Add to Context Basket** — collect as you browse, hand the whole set over at once. Nothing
else on the Mac does this. **8.2 min/day.**

---

## And the one that is not about minutes

Five terminals open. One of them is waiting on you and you do not know which.
The menu bar tells you: which agent is blocked, what is still running, what is holding port 3000.

*Its cost is attention, not seconds — so there is no minutes figure here, and we are not going to
invent one.*

---

## Built to be trusted with a repo an agent is about to rampage through

- Destructive actions **preview by default** and show you the list. Writing takes a second,
  explicit click.
- `checkpoint` snapshots everything, **including untracked files** — which is exactly what an
  agent creates — without touching your index, your worktree or `HEAD`. It can only ever add a
  branch.
- `clean` moves to the **Trash**, never `rm`.
- The Finder extension is sandboxed and cannot run a command. It writes a request; the app checks
  it is a regular file, owned by you, not group-writable, before acting on it.
- Nothing is uploaded. There is no network code at all, except the `gist` command you invoke.

---

## Three surfaces, one engine
**Finder right-click** for what your hands are already doing · **`⌥⌘N`** anywhere ·
**the `chute` CLI** for everything else.

## Don't take the number on trust

```bash
brew install avaluev/tap/chute
chute bundle src/ --no-copy | head
```

Free, MIT, no trial, no account. It does the same work the paid menu row does. If the output is
not what the page just promised, do not buy the app.

---

## Pricing
### Free for 14 days. $19 once, after that.
The command-line tool is free forever. Chute.app — the Finder menu, the hotkey, the menu-bar
switcher — is the paid surface. No subscription, no telemetry, no account. 30-day refund, no
questions asked.

## FAQ

**Doesn't Claude Code already read files?** Yes, and that is the point — it reads what you point
it at. Pointing is the part you do by hand, 49 times a day between paths and contents.

**Does it phone home?** No. There is no network code except `chute gist`, which shells out to
your own `gh` when you ask it to.

**Does it need Xcode?** No. 2.9 MB app, 805 KB binary, built with the Command Line Tools, zero
third-party dependencies.

**Does it work with Cursor / Codex / Gemini / Aider?** Yes — the output is plain text and files.
`chute sandbox` launches claude, codex or gemini directly; anything else takes one flag.

**macOS version?** 13 Ventura and later. Apple Silicon and Intel.

**What happens when the trial ends?** The Finder menu and the menu bar stop. The CLI keeps
working forever — it is MIT and it is symlinked out of the same bundle.
