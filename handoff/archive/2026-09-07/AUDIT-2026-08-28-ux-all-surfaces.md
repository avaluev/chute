# UX AUDIT — every surface — 2026-08-28

Method: three read-only agents inventoried the GUI, the CLI and the first-run journey; the
findings below were then re-derived or spot-checked by hand. Every claim carries `file:line` or a
command you can run. Nothing here came from opinion.

---

## THE SYSTEMIC FINDING

Each surface is designed well **in isolation** — the code is full of deliberate, well-argued
rejections. Nothing enforces consistency **across** them. Four consequences, each measured:

### 1. Attention is inversely proportional to value

| Surface | Cases | min/day | Share | Commits (last 60) | Lines |
|---|---|---|---|---|---|
| **Finder** | 10 | **129.1** | **59%** | 21 | 943 |
| CLI | 13 | 83.5 | 38% | — | — |
| **Menu bar** | 2 | **4.9** | **2.3%** | **26** | **2,098** |

The menu bar carries 1/26th the value with 2.2× the code and more commits. Derived from
`site/src/lib/cases.ts` against `docs/03-JTBD-LEDGER.md`; `git log --oneline -60 -- <paths>`.

`which-agent-is-waiting-for-you` — the menu bar's flagship — is `jtbd: 0`, `savedMinutes: null`.
It has **never been costed**. By the measurement doctrine's own rule 7, it needs a number or a cut.

### 2. The product cannot tell whether it is working

- `chute doctor` prints **"all 9 checks passed"** on a machine where hooks are unwired, the badge
  is permanently dark and every session reads `working`. There is deliberately no hooks check
  (`Diagnostics.swift:81-83`) — a defensible principle, silently producing a false all-clear.
- `FirstRunWindow.swift:91` announces **"2 things need your permission"** on a clean, correct,
  app-only install — over `cli` (Homebrew, which `install.sh:31-34` says the app does not need)
  and `terminal`, whose own fix text reads *"Informational only — nothing is broken."*

Same failure mode as the CPU bug this repo just spent a session on: **a plausible signal answering
a different question than the user asked.** Shape, not substance.

### 3. One job, three names

| Job | Site | Finder | CLI |
|---|---|---|---|
| 41.1 min/day | paste a whole folder into your agent | Copy Files as Context | `bundle` |
| 28.5 min/day | turn an answer back into files | Save Clipboard as Files… | `unpack` |
| — | Recent Copies | Recent Copies | `buf flush` |
| — | — | Move Junk to Trash | `clean` |
| — | — | Add Agent Rules | `seed` |
| — | — | New Scratch Folder | `sandbox` |

Ten collisions. `FinderActions.swift:10` states a naming law for the GUI ("a verb, title case, no
jargon, no abbreviations"); the CLI is governed by nothing and `buf` violates all four.
`BufferMenu.swift:58` even *documents* that "flush the buffer" is a sentence about the
implementation — and the CLI still ships it.

**Worst case, inside a single struct:** `FinderActions.swift:220-226` — the menu row says
**"New Scratch Folder"**, the comment above it explicitly rejects the phrase "Clean Room", and the
completion toast says **"Clean room ready."** One click, two names, six lines apart.

### 4. The safety convention is applied backwards

`clean` and `unpack` — which only Trash and only overwrite — **dry-run by default**
(`FileCommands.swift:176`, `:62`), and label each row `create`/`overwrite`. Excellent.

Five destructive commands have **no dry run and no confirmation**:

| Command | Does | file:line |
|---|---|---|
| `ports --kill <port>` | **SIGKILLs** with no preview — one typo from `5432` kills your Postgres | `AgentCommands.swift:127` |
| `doctor --fix` | Trashes a container, kills ChuteApp, `killall Finder` | `DoctorCommand.swift:112-119` |
| `env inject` | Writes live secrets; **appends blindly, so re-running duplicates every key** | `AgentCommands.swift:179-180` |
| `gist` | Uploads to GitHub before you see what was redacted | `GitCommands.swift:159` |
| `hooks uninstall` | Edits `~/.claude/settings.json`; prints the backup path **after** the write, and `"none"` is possible | `SessionCommands.swift:186-189` |

---

## DEFECTS FOUND BY RE-ANALYSIS (not reported by anyone)

### A. The #2 job rejects its own most common input — 28.5 min/day

`chute unpack` accepts a path **on the fence** or in a **heading before** it. It does not accept a
path as a comment on the first line **inside** the block — which is what Claude, GPT and Cursor
emit most often. Verified by hand:

| Format | Accepted |
|---|---|
| ` ```ts src/a.ts ` | ✅ |
| `**src/b.ts**` before the fence | ✅ |
| ` ```ts ` then `// src/c.ts` | ❌ |
| ` ```python ` then `# app/main.py` | ❌ |

`MarkdownUnpack.pathFrom` (`:80`) reads only the info string; `pathFromContext` (`:88`) looks only
*backwards*. Neither looks at `body[0]`. Fix is ~10 lines in one pure function that already has a
test suite.

### B. The one job that exists to prevent overflow under-reports by 2.8×

```
chute bundle src/a.ts README.md   →  ~25 tokens
chute tokens src/a.ts README.md   →  ~9 tokens
```

`ContextCommands.swift:27` counts the assembled XML blob; `:42` counts file contents only. Both
are defensible in isolation. But JTBD 24 exists to answer *"how big is this before you send it"*,
and the number you actually paste is the bundle's. `tokens` understates the thing it predicts.

### C. The Finder menu is not ordered by value — and it is 96% of paid revenue

| Slot | Row | min/day |
|---|---|---|
| 1 | Copy Full Paths | 9.1 |
| **2** | **Copy Files as Context** | **41.1** |
| 3 | Copy Folder Tree ▸ (submenu, costs a hover) | 4.5 |
| **4** | **Save Clipboard as Files…** | **28.5** |

The two biggest jobs sit at 2 and 4, the second of them below a submenu worth one-ninth as much.
Every Finder case is `paid: true`; every CLI case is `paid: false`.

### D. `chute sessions` prints numbers you cannot see, for two different lists

`SessionCommands.swift:72` prints no header and **no index column**. Yet `focus <N>` (`:167`) and
`resume <N>` (`:105`) both take a number — and resolve it against **different lists** (`resume`
filters to sessions carrying a `sessionID`). The same N can mean two terminals, and neither
numbering is ever shown. The only way to learn N is to trigger the ambiguity error.

### E. Two notification implementations; the older bug still ships

`Notify.swift:6-10` exists specifically because raw `osascript` banners are misattributed to
**Script Editor**. `ChuteFinderSync.swift:216-226` still shells raw `osascript`. Every Finder-side
failure — *"Nothing is selected."*, *"Could not tell which folder this is."*, *"Still queued…"* —
arrives under Script Editor's name and icon, with no recovery control attached.

### F. Onboarding has no way back, and marks itself done before it runs

`Onboarding.swift:34-36` sets `UserDefaults "onboarded" = true` **before** calling `show()`. Quit
mid-wizard and it never returns. `openSetup()` (`main.swift:198`) exists and is wired to nothing —
dead code. The only escape is `defaults delete dev.valuev.chute`, documented in a code comment.

### G. Dead code left by this session's own refactor

`Sources/ChuteApp/BufferMenu.swift` is now unreferenced — `StatusMenu.recentCopies` replaced it.
It still contains a near-duplicate of the menu, including its own copy of the wording.

### H. Smaller, verified

- Session row titles are unbounded (`StatusMenu.swift:181-193`); AppKit truncates natively with no
  ellipsis logic. `ContextBuffer.Entry.preview` caps at 60 chars — the menu row does not.
- Notifications denied **and** headless ⇒ the user gets **zero** feedback (`Notify.swift:65-72`).
- 8 CLI commands fail silently at exit 0, including `sessions` after an Automation denial — a
  permission failure is indistinguishable from "no sessions" to any script.
- Every `Out.deliver` command silently writes its output into `~/.chute/buffer` (`Args.swift:80`).
  Bounded, 0700, deduped — but nothing on screen says it happened.
- 29 of 53 CLI error messages fail "says what to do next". They cluster: all 5 `not a directory:`
  sites, all 6 wrapped-subprocess errors, all 4 bare `\(error)`.
- 11 flags and 2 commands (`finder-actions`, `paste-image`) exist but are undocumented.
- `README.md:42` ships an absolute path from this machine; `README.md:45` documents a CLI symlink
  `install.sh:31-34` explicitly refuses to create.

---

## WHAT IS ALREADY GOOD — do not "fix" these

- **`bundle` on a folder excludes `node_modules/`, `.git/` and `.env`**, and announces skipped
  binaries. The "trust is gone permanently" moment passes. Verified by hand.
- **`clean` and `unpack` dry-run by default**, and `unpack` labels each row `create`/`overwrite`.
- **The trial's ethics.** `StatusMenu.swift:112-116` — an expired trial keeps Settings, Report a
  Problem, Quit, and states that the MIT CLI still does every one of these jobs.
- **Notification permission is asked lazily**, attached to a real event (`Notify.swift:50-56`).
- **Onboarding beat 3 refuses to ask the impossible** when the extension is off
  (`Onboarding.swift:98-105`), and is checked above the trial gate so an expired trial cannot make
  the proof-of-value beat unreachable.
- **`env inject` refuses to write a `.env` that is not gitignored** (`AgentCommands.swift:160`) —
  the single best error message in the product.
- **The `ports` output** prints a header and the exact next command. It is the model the rest of
  the CLI should copy.
