# HANDOFF — the ICP decided, and four rows deleted for it — 2026-08-31

STATE: `main` · `258f7ab → 80d7187` (9 commits) · tree clean · **pushed**
Counts live in ONE place: `marketing/06-FACT-SHEET.md` §Verification. Re-derived from the gates
this session, never copied forward.

```bash
swift build -c release && swift run -c release chutetests
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && CHUTE_HEADLESS=1 ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && ./demo/verify.sh && make -C demo/gui lint
cd /Users/sxope/Documents/2026/Development/37.chute/site && npm run check:cases && npm run check:claims
```

## ONE-LINE GOAL

Chute is for one person — a Claude Code user — and every row now survives that test.

---

## THE DECISION THAT DROVE EVERYTHING

The founder could not state the job of three of his own menu rows. Asked directly, he settled the
ICP: **Claude Code / Cursor users**, whose agent already reads and writes files. The ledger had
been costed for someone else — a person pasting between a browser chat and their disk.

The test every row was then held to: **does this survive a user who has git, an OS with terminal
shortcuts, and an agent with filesystem access?**

| Row deleted | Why it failed |
|---|---|
| `Open in Terminal` | macOS ships "New Terminal at Folder" four rows below it |
| `New Scratch Folder` | Claude Code ships its own sandboxing |
| `Move Junk to Trash` | `git status` already lists untracked files, and is trusted more |
| `Save Clipboard as Files` | the ICP's agent writes files itself — 28.5 min/day, the #2 job |

One row added: **Add to Context Basket** — the only thing left in the menu that nothing else on
the Mac ships. Maccy, Raycast and Paste hold TEXT; this holds FILES.

```
$ chute basket add src/auth.ts lib/db.ts test/spec.ts
$ chute basket copy
@src/auth.ts @lib/db.ts @test/spec.ts
```

Kept despite the ICP logic, on the founder's correction — **do not re-propose deleting these**:
`Copy Folder Tree` (a pasted tree orients an agent without it burning context on `ls -R`) and
`New File`.

---

## DONE (verified)

| Thing | Proved by |
|---|---|
| The Basket works across folders | 3 files in 3 folders → `@src/auth.ts @lib/db.ts @test/spec.ts` |
| Its bundle IS `chute bundle` | asserted byte-identical in smoke §19, one `ContextBundle.assemble` |
| Recent Copies' real defect | only 3 of 10 actions ever wrote to it; `Out.deliver` auto-record deleted |
| A stale CLI can say so | `chute 0.2.0 · app build ffe364b 2026-08-28T19:44Z` |
| Tests no longer eat the basket | real entry survived a full suite run, `CHUTE_BUFFER_DIR` |
| Docs cannot promise a ghost command | `chute teleport` in README → claims gate fails by name |
| Tapes cannot outlive their case | a live tape pointed at a retired slug → lint fails by name |

**Numbers, all re-derived from `site/src/lib/cases.ts` after the edits:**
Finder **89.0** · menu bar **4.9** · **app surface 93.9** · free CLI 75.3 · all 21 jobs 169.2.
The headline is ~90 min/day and now says why it is not 169: two thirds of the ledger is the free
MIT CLI, and a paid page must not quote a number the buyer already has for nothing.

---

## TRAPS — paid for once, do not pay again

- **A hand-kept list is not a gate.** `check:claims` passed all day while four files told people
  to run `chute unpack`, because it compared pages against a list of retired names nobody had
  updated. It asks the dispatch switch now. Same shape as the stale `RETIRED` array, the stale
  `"14"` menu count, and the stale fact-sheet tallies — all found this session.
- **A comment is not a guard.** `CHUTE_BUFFER_DIR` said "tests only" and enforced nothing.
- **Green with zero failures can still be a broken run.** Deleting `clean-junk` left
  `run_action clean-junk` in smoke.sh; under `set -e` it aborted at line 94 — exit 1, no FAILs,
  no summary. Read the tally, never the exit code.
- **A gate that proves shape passes a deleted feature.** `make -C demo/gui check` planned full
  recordings for three retired rows: `lint` proved grammar, `plan` proved fixtures, neither asked
  whether the thing existed.
- **Patching a total instead of deriving it.** The capability map said 82.1 while its own row
  table summed to 89.0 — an agent had subtracted from a stale base. Derive; never patch.
- **Delegation needs the file list AND the reason.** Every agent that hit an ownership conflict
  reported it instead of reaching outside — which is why nothing was clobbered across five
  concurrent agents. The one that put a `ContextBundle` extension in `ContextBuffer.swift` was
  right to, and it was moved afterwards by someone who owned both.

---

## NEXT — in order

1. **Rebuild and open the menu. Nothing here has been seen on a real screen.**
   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/build-app.sh && ./Scripts/install.sh
   ```
   Then the only test that matters: right-click three files in three different folders → **Add to
   Context Basket** → menu bar → **Copy Basket as @mentions** → paste into Claude Code. **If that
   is not obviously faster than typing the three paths, the Basket is wrong and should be deleted
   like the other four.** Do not polish it before answering that.
2. **The menu bar is now the only ICP-native surface and it is the least built.** Which agent is
   waiting, zombie ports, what changed, checkpoints. It has been ranked lowest all along on a
   number computed for the wrong buyer. This is the next session.
3. **Two numbers only you have** — times/day you check which agent is waiting, and how long
   finding it takes without Chute. The switcher is still `jtbd: 0` holding 2,098 lines.
4. **The stopwatch, ~3 min.** Every `demo/out/gui/*.json` has `manual: null`.
   `./demo/gui/by-hand.sh`
5. **Phase 0 — still blocking money.** CNAMEs (`dig +short chutedev.com` still empty), Apple
   enrolment ($99), Paddle, and `Sources/ChuteCore/License.swift:28` is still
   `REPLACE_ME_BEFORE_RELEASE`. Also: the Homebrew tap was never updated — `Scripts/release.sh`
   builds and notarises correctly but does not touch the tap, which is why the installed CLI ran
   54 commits behind.

---

## DECISIONS (and why) — do not re-litigate

- **`unpack` is gone, not hidden.** `MarkdownUnpack`, `validate` and `staysInside` went with it;
  grepped repo-wide first, nothing else needed them. FR-06 is struck through and marked RETIRED
  rather than deleted, so the decision is legible.
- **JTBD 22 moved from the free CLI column to the paid Finder one** when the Basket became a row.
  Left as `cli`/free it counted in the free tier while the row it describes sat in the paid one.
- **A basket entry is a PATH, not a copy of the content.** Hence no 2 MB cap, rows that name the
  file, contents read fresh at hand-over, and "— missing" when a file is gone.
- **Nothing auto-fills the basket.** `Out.deliver`'s auto-record, and the `paste-image` and
  `gist`/`diff` recordings, are all deleted. Only an explicit add files anything — that automatic
  filing is exactly what made the old list read as hardcoded.
- **`buf` is kept as an undocumented alias** for `basket`, and smoke asserts both reach it.
- **The CLI is plumbing, not a product.** It competes with free `npx repomix` and earns nothing.

## OPEN QUESTIONS FOR THE HUMAN

- `check-metrics`'s one-core assertion goes red roughly 1 run in 3 under heavy subagent load, green
  alone (confirmed twice today). **Do not widen the bound** — that is how it would stop catching
  the 24× error it was built for.
- `AgentCommands.swift` is still four features in one file, and there is still no About panel.
