# Capability map — Finder menu ⇄ CLI ⇄ JTBD

**Written 2026-08-28**, after the Finder menu was renamed and recoloured. Three surfaces run the
same engine, and this is the one page that says which job each of them is actually doing:

| Surface | What it is | Paid? |
|---|---|---|
| **`chute` CLI** | 27 commands, MIT, free forever. Every capability lives here first. | free |
| **Finder right-click** | 13 actions in 8 rows. Every one of them shells out to the CLI. | paid |
| **Menu bar (⤓)** | Session switcher, local servers, licence, diagnostics. Uses ChuteCore in-process. | paid |

The rule that keeps them honest: **the app is a surface, never a second implementation**
(`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/main.swift:6`). Anything the
Finder menu can do, the CLI can already do. Nothing is menu-only.

---

## A. The Finder menu, row by row

This is what a right-click adds to Finder's own context menu. Reproduce it any time without
building or clicking:

```bash
swift run chute finder-actions --menu
```

```
  Copy Full Paths                  ● blue
  Copy Files as Context            ● blue
  Copy Folder Tree  ▸              ● blue
        2 Levels
        4 Levels
        All Levels
  Save Clipboard as Files…         ● red
  New File  ▸                      ● green
        Empty Markdown File
        Markdown File from Clipboard
        Image from Clipboard
  Set Up for an Agent  ▸           ● purple
        Add Agent Rules
        New Scratch Folder
  Move Junk to Trash…              ● red
  Open in Terminal                 ● indigo
```

| Row | Action id | Runs | Acts on | JTBD | Saves/day | Colour |
|---|---|---|---|---|---|---|
| Copy Full Paths (n) | `copy-paths` | `chute paths <files>` | selection | **1** Multi-file path extraction | 9.1 min | blue |
| Copy Files as Context (n) | `bundle-xml` | `chute bundle <files>` | selection | **2** Multi-file context bundle | **41.1 min** | blue |
| Copy Folder Tree ▸ 2 Levels | `tree-2` | `chute tree <dir> --depth 2` | folder | **5** Directory tree skeleton | 4.5 min | blue |
| Copy Folder Tree ▸ 4 Levels | `tree-4` | `chute tree <dir> --depth 4` | folder | **5** | ″ | blue |
| Copy Folder Tree ▸ All Levels | `tree-all` | `chute tree <dir> --depth 99` | folder | **5** | ″ | blue |
| Save Clipboard as Files… | `unpack-here` | `chute unpack --dir <dir>` | folder | **9** Markdown → filesystem | **28.5 min** | **red** |
| New File ▸ Empty Markdown File | `new-markdown` | `chute new --blank --rename --dir <dir>` | folder | **3** Clipboard → file | 12.9 min | green |
| New File ▸ Markdown File from Clipboard | `new-markdown-clipboard` | `chute new --naming underscore --ext md --rename --dir <dir>` | folder | **3** + **4** Syntax detection | ″ | green |
| New File ▸ Image from Clipboard | `paste-image` | `chute paste-image --dir <dir>` | folder | **3** (image variant) | ″ | green |
| Set Up for an Agent ▸ Add Agent Rules | `seed-rules` | `chute seed <dir>` | folder | **7** Seed agent rule files | 9.9 min | purple |
| Set Up for an Agent ▸ New Scratch Folder | `sandbox-here` | `chute sandbox --dir <dir>` | folder | **6** Agent sandbox init | 7.3 min | purple |
| Move Junk to Trash… | `clean-junk` | `chute clean <dir>` | folder | **13** Clean agent junk | 6.6 min | **red** |
| Open in Terminal | `terminal` | `chute open <dir>` | folder | **8** Open terminal here | 5.9 min | indigo |

**Total surfaced through Finder: 9 of the 24 ledger JTBDs, ≈ 126 min/day.** The two largest
savings in the whole ledger — bundle (41.1) and unpack (28.5) — are both one click, never behind a
submenu. `Sources/chutetests/FinderActionsSuite.swift` fails the build if either is demoted.

### What each one actually does, in one sentence

- **Copy Full Paths** — every selected item's absolute path on the clipboard, one per line. What
  you paste when an agent asks "which file?".
- **Copy Files as Context** — not the files: everything *inside* them, concatenated into one XML
  block with a token count, ready to paste into a chat. This is the product's wedge.
- **Copy Folder Tree** — the shape of a folder as an indented tree, with `node_modules`, `.build`
  and friends left out. Depth is a knob, not a dialog, because a context menu cannot ask.
- **Save Clipboard as Files…** — the inverse. An agent answered with five fenced code blocks and
  their filenames; this writes them to disk here. Lists them first and writes nothing until you
  press **Write Files**.
- **New File ▸ Empty Markdown File** — an empty `Untitled.md`, name selected and ready to type over.
- **New File ▸ Markdown File from Clipboard** — the clipboard saved here, filename derived from its
  first line, language detected from its content.
- **New File ▸ Image from Clipboard** — a screenshot saved here as PNG, and its full path copied,
  so the next thing you paste into the issue is the path.
- **Set Up for an Agent ▸ Add Agent Rules** — writes `CLAUDE.md`, `.cursorrules` and
  `SCRATCHPAD.md` here, skipping any that already exist. Never overwrites, so it never asks.
- **Set Up for an Agent ▸ New Scratch Folder** — a *new* folder beside this one, with git
  initialised, rules seeded, and the agent already running in it. Where you send an agent you do
  not trust yet.
- **Move Junk to Trash…** — the scratch files an agent left behind, moved to the Trash (never
  `rm`). Lists them first.
- **Open in Terminal** — a terminal already `cd`'d here.

---

## B. Every CLI capability, and where it surfaces

27 commands. Read `chute help` for the flags; this table answers only "who can reach it".

| CLI | JTBD | Finder | Menu bar | Why |
|---|---|---|---|---|
| `paths <files>` | 1 | ✅ | — | |
| `bundle <files>` | 2 | ✅ | — | Finder is XML-only; `--format md` stays CLI. |
| `tokens <files>` | **24** | ❌ | — | **Gap — see C.** Partly covered: the bundle prints a count. |
| `tree [dir]` | 5 | ✅ | — | |
| `buf add\|list\|flush\|clear` | 22 | ❌ | — | A ring needs state across clicks; a context menu has none. |
| `new` | 3, 4 | ✅ | — | |
| `unpack` | 9 | ✅ | — | |
| `seed [dir]` | 7 | ✅ | — | |
| `note "text"` | 16 | ❌ | — | Needs typed text. A context menu cannot ask a question. |
| `latest [dir]` | 10 | ❌ | — | **Gap — see C.** |
| `clean [dir]` | 13 | ✅ | — | |
| `sandbox [name]` | 6, 21 | ✅ | — | `--each` (multi-agent broadcast, JTBD 21) is CLI-only. |
| `open [dir]` | 8 | ✅ (terminal) | — | `--with editor` is CLI-only. **Half a gap — see C.** |
| `ports` | 15 | — | ✅ Local Servers | Correct: ports have no folder to right-click. |
| `prompt decompose\|ponytail` | 17, 18 | ❌ | ❌ | No file context at all. Belongs in the menu bar, not Finder. |
| `checkpoint [dir]` | **12** | ❌ | — | **Gap — see C.** |
| `diff [dir]` | 11 | ❌ | — | **Gap — see C.** |
| `redact [files]` | 19 | ❌ | — | **Gap — see C.** |
| `gist <files>` | 20 | ❌ | — | **Gap — see C.** The JTBD is literally named "from Finder". |
| `dataurl <image>` | 23 | ❌ | — | **Gap — see C.** |
| `env inject [dir]` | 14 | ❌ | — | Needs key names. Correctly CLI-only. |
| `sessions` | — (FE-01) | — | ✅ switcher | The menu bar's whole reason to exist. |
| `focus <key>` | — (FE-01) | — | ✅ click a row | |
| `hooks snippet\|status` | — | — | — | Setup. Never edits your settings itself. |
| `doctor` | — | — | ✅ Report a Problem | `doctor --report` fills the issue. |
| `finder-actions` | — | — | — | Plumbing: the menu's own table, so tests run what the menu runs. |
| `paste-image` | 3 | ✅ | — | |
| `help` / `--version` | — | — | — | |

**Menu-bar-only capabilities** (no CLI equivalent, because they are the surface itself): the ⤓
badge count, the live CPU/memory columns, the licence field, and ⌥⌘N.

---

## C. The gaps, ranked

Nine ledger JTBDs have a CLI command, fit a folder or a selection, and are not in the Finder menu.
Ranked by tier then saving:

| JTBD | CLI | Tier | Saves/day | Fits a right-click? | Verdict |
|---|---|---|---|---|---|
| **12** Pre-agent checkpoint | `checkpoint` | **T1** | 3.3 min **+ ~20 min risk-adjusted** | folder — yes | **Worth adding.** |
| **24** Token estimate | `tokens` | **T1** | prevents a full retry | selection — yes | Partly covered already. |
| 16 Scratchpad note | `note` | T2 | 8.8 min | needs typed text | Correctly absent. |
| 11 Diff snapshot | `diff` | T2 | 4.9 min | folder — yes | Defer. |
| 19 Copy redacted | `redact` | T2 | 5.8 min | selection — yes | Defer. |
| 10 Reveal latest artifact | `latest` | T2 | 4.3 min | folder — yes | Defer. |
| 20 Secret gist | `gist` | T2 | 2.8 min | selection — yes | Defer, but note the name. |
| 23 Image → data URL | `dataurl` | T2 | 2.7 min | selection — yes | Defer. |
| 8b Open in editor | `open --with editor` | T1 | part of 5.9 min | folder — yes | Defer. |

### The one recommendation

**Add `checkpoint` as a third child of "Set Up for an Agent".** It is the only T1 job with a clean
folder scope and no Finder surface, it is what makes letting an agent run feel safe, and it costs
**zero new top-level rows** — the menu stays at eight. Proposed:

```
  Set Up for an Agent  ▸           ● purple
        Add Agent Rules
        New Scratch Folder
        Save a Checkpoint First     ← chute checkpoint {dir}
```

Everything else in the table stays out for now. Eight rows added to Finder's own already-long menu
is the budget, and the six deferred jobs are worth ~23 min/day *combined* — less than half of what
"Copy Files as Context" returns on its own. A ninth row costs every user on every right-click; it
should be bought by a T1 job, not by six T2s.

**JTBD 24 is a half-truth in the ledger.** `Copy Files as Context` already prints the token count
with the bundle, so the "don't overflow the window" job is done at the moment it matters. What is
missing is only *estimate without copying* — cheap to add as a selection row, but it is a
different, smaller job than the ledger's 15×/day claims. Do not count it as an open T1.

---

## D. The rules a new action has to follow

Anything added to `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/FinderActions.swift`
inherits these, and `Sources/chutetests/FinderActionsSuite.swift` enforces every one of them.

### Naming

Apple's menu wording: **a verb, title case, no jargon, no abbreviation, and never a name that
promises something the command does not do.**

- **Banned words, enforced by the suite**: `bundle`, `unpack`, `xml`, `sandbox`, `yolo`,
  `redacted`. These are the CLI's words. A buyer who has never opened a terminal does not have
  them, and a menu is not the place to teach vocabulary.
- **No invented terms.** "Clean Room" was in this menu until today and appeared nowhere else in
  the product, the docs or the CLI — a term coined for one row is a term nobody can look up.
- **No word said twice on one path.** "New File Here ▸ New Markdown File" says *New* twice; "New
  File ▸ Empty Markdown File" says it once and uses the freed word to carry information.
- **Parallel siblings.** "2 Levels / 4 Levels / **Everything**" broke its own pattern; it is
  "All Levels" now.
- **The count belongs in the title** — `Copy Full Paths ({n})` — so you can see what you are about
  to act on before you commit to it.
- **An ellipsis if and only if it asks first.** `menuTitle` appends it from `isDestructive`, so it
  can never be forgotten or wrongly applied.

### Colour

Five colours, by **what the action does to your disk** — never by which action it is:

| Kind | Colour | Meaning |
|---|---|---|
| `.copy` | ● systemBlue | reads; writes only to the clipboard |
| `.create` | ● systemGreen | makes something new, never touches what is there |
| `.setup` | ● systemPurple | prepares a folder for an agent, additively |
| `.destructive` | ● **systemRed** | changes or removes files that exist — always asks first |
| `.open` | ● systemIndigo | leaves Finder for another app |

Colour answers *is this safe?*; the **icon and the word** carry identity. That division is
deliberate: nobody can hold "teal means bundle" in their head, but everyone holds "red means it
changes something".

> **The bug this replaced.** The table was `[SF Symbol: NSColor]` with `?? .systemBlue`, and four
> of the thirteen symbols were missing from it — including `trash.fill`. "Move Junk to Trash" was
> drawn in the same blue as "Copy Full Paths". A partial lookup with a default cannot tell you it
> is incomplete; a `switch` over an enum will not compile until it is.
> Fixed at `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteFinder/ChuteFinderSync.swift:118`.

`isDestructive` and `kind == .destructive` must agree — the suite fails the build if they drift, so
no future action can be wired to `clean` and drawn green.

### Icons

One SF Symbol each, and **no two drawn rows may share one** (submenu holders included) — an icon
that cannot distinguish is decoration. Siblings inside one submenu do share, so the holder's icon
is deterministic. They are pre-rendered to an 18pt bitmap with the colour baked in and
`isTemplate` off, because a live symbol's configuration is dropped crossing the appex → Finder
boundary and a template is forced monochrome by the system.

`shippingbox.and.arrow.backward.fill` was replaced with `folder.badge.plus` for `sandbox-here`:
at 18pt it was a near-twin of the bundle row's `shippingbox.fill`, and the action makes a folder.

### Safety

Anything that runs a `--force`-capable command **must** declare a `confirmButton`. The template
never carries `--force`; the app runs the dry run, shows the list, and only re-runs with `--force`
if the user presses the named button. Cancel is the default, so a stray Return writes nothing.

---

## E. Feedback: one surface, never two

Every completed action reports through exactly one channel.

`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/Notify.swift` used to fire both
an on-screen HUD **and** a Notification Centre banner for the same event — reported 2026-08-28 as
"full duplicated notification: old and new one". They now sit behind one branch:

```swift
func notify(_ title: String, _ body: String) {
    DispatchQueue.main.async {
        if ResultHUD.show(body) { return }
        Notify.post(title: "Chute", subtitle: ..., body: body)
    }
}
```

`ResultHUD.show` returns whether it actually drew. **The HUD wins wherever there is a screen**,
because it is the one that cannot be delayed: handing a request to `UNUserNotificationCenter`
takes 4 ms, but delivery is not display, and a Focus mode or a Scheduled Summary can hold the
banner for minutes. The notification is now the fallback and nothing else — no window server, no
`NSApp`, or `CHUTE_HEADLESS=1`. There is one code path, so both cannot fire.

All nine call sites go through that one function
(`ServersMenu.swift`, `SettingsWindow.swift`, `main.swift`, `RequestInbox.swift`), so this is the
whole guarantee, not a fix applied per caller.

---

## Verify any claim on this page

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && swift run chute finder-actions --menu
```

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && swift run chute finder-actions --json
```

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests && ./Scripts/smoke.sh
```

Expected: `✅ 623 assertions passed` and `smoke: 149 passed, 0 failed`.
