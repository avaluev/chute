# Landing redesign — sell the app, free CLI as top of funnel

Written 2026-08-27. Execute in a fresh session, top to bottom. Every task carries its gate.

---

## PART A — The diagnosis

The site at https://chute.pages.dev sells a **command-line tool to people who already understand
the problem.** It should sell **relief from a specific daily pain to someone currently feeling
it.** Three findings, in order of how much they matter.

**1. The owner did not know what the product does.** `docs/03-JTBD-LEDGER.md` lists 24 jobs. All
24 were verified working on 2026-08-27 — every command runs, and the only two "failures" are
correct refusals (`env inject` refusing an ungitignored `.env`, `gist` with no arguments). The
ledger was committed 2026-08-26 in a session, and the founder's own words on reading it back were
*"I don't know about functions you described! I never see JTBDs you mentioned!"*

That is the whole problem, stated by the person with the most context in the world about this
product. **This is not a styling job. It is a legibility job.** If the author cannot list what it
does, a stranger has no chance.

**2. The demos show commands, not consequences.** A terminal recording of `chute paths` is
evidence that a command exists. It is not an argument. Nobody in pain recognises themselves in it.

**3. A demo of the product FAILING reached production.** `unpack.gif` shipped to the homepage
showing `chute: no named code blocks found` twice, captioned "a markdown answer becomes a real
file tree". Fixed in `14b43ab`, and `demo/verify.sh` now gates recording. It is listed here
because it explains why every claim in the new pages must be produced by a checked pipeline
rather than by hand.

### What the page must do instead

| Now | Instead |
|---|---|
| Lists commands | Names a pain, shows the ritual it replaces |
| Terminal GIFs | Finder and menu-bar recordings — the thing being sold |
| One flat feature order | Sorted by how much of the day it costs |
| CLI is the hero | **CLI is the free sample. The app is the product.** |

---

## PART B — Decisions locked 2026-08-27

| Decision | Value |
|---|---|
| Move CLI-only jobs into the Finder menu | **Yes** — `unpack`, `seed`, `sandbox`, `clean` |
| Demo depth | **Tiered** — 8 hero demos, 16 short ones, all 24 covered |
| Architecture | **Landing + `/cases` index + a page per case** |
| Optimise for | **Trial installs.** Primary CTA everywhere is "Download — free 14 days" |

Standing and unchanged: $19 one-time, 14-day trial, Paddle, offline Ed25519 keys, MIT CLI,
chutedev.com, dark-only, JetBrains Mono headings, one accent used once per screen.

---

## PART C — Product work first: the app must be able to demo its own value

The paid surface today covers jobs worth **~73 min/day**. Four of the highest-value jobs are
CLI-only, so the app cannot demonstrate them and the buyer never sees them.

Add four rows to `Sources/ChuteCore/FinderActions.swift` — the table already exists, and
`bundle-xml` (added 2026-08-27) is the worked example to copy.

| New action | Title | JTBD | Saved/day | Symbol · tint |
|---|---|---|---|---|
| `unpack-here` | Unpack Clipboard Here | #9 | **28.5 min** | `arrow.down.doc.fill` · `.systemPink` |
| `seed-rules` | Seed Agent Rule Files | #7 | 9.9 min | `doc.badge.gearshape.fill` · `.systemBrown` |
| `sandbox-here` | New Agent Sandbox Here | #6 | 7.3 min | `shippingbox.and.arrow.backward.fill` · `.systemYellow` |
| `clean-junk` | List Agent Junk Files | #13 | 6.6 min | `trash.fill` · `.systemGray` |

**After this the app demonstrates ~125 min/day.** That is the number the page argues.

Constraints, each learned the hard way and each pinned by an existing test:
- `Sources/chutetests/FinderActionsSuite.swift` bans the words *bundle, unpack, xml, sandbox, yolo, redacted* in menu titles. **`unpack-here` must therefore NOT be titled "Unpack".** "Unpack Clipboard Here" fails that guard — pick wording that survives it, e.g. **"Write Clipboard Files Here"**. Run the suite before choosing.
- No two inline rows may share an SF Symbol (guarded).
- `unpack` and `clean` PREVIEW by default. From Finder they must still preview — a right-click that silently writes files is the one thing that would destroy trust. Show the preview as a notification, require a second explicit action to write.
- Update the count in `Scripts/smoke.sh` ("the menu table and this test agree").
- 13 inline rows is a lot inside someone else's context menu. Consider grouping the four new ones under one submenu if the menu reads as crowded when tried by hand.

**Gate:** `swift run chutetests && ./Scripts/smoke.sh` green, then right-click by hand and confirm
each new row does what it says. `docs/07-DEFINITION-OF-DONE.md` requires the manual check.

---

## PART D — The case inventory

Every case is one row in **one data file**, `site/src/lib/cases.ts`, which generates the landing
sections, the `/cases` index and all 24 case pages. One source: a case cannot appear on the index
and be missing a page.

```ts
export interface Case {
  slug: string;            // /cases/paste-eight-files-into-your-agent
  jtbd: number;            // ledger row, for traceability
  surface: "finder" | "menubar" | "cli";
  tier: "hero" | "short";
  pain: string;            // the moment, in the reader's words — NOT the feature name
  ritual: string;          // what they do today, concretely
  fix: string;             // what Chute does instead
  seconds: { manual: number; chute: number };
  perDay: number;          // frequency
  savedMinutes: number;    // from the ledger — never invented
  demo: string;            // /media/cases/<slug>.mp4 — MUST exist, checked
  poster: string;
  command?: string;        // the CLI equivalent, when there is one
  paid: boolean;           // does the $19 buy this?
}
```

### The 8 heroes — every one is app surface, and that is the point

Heroes are what the **$19 buys**. Shorts are what is **free**. That split IS the sales argument
and it must be visible on the page.

| # | Slug | Pain, as the reader would say it | Surface | Saved/day |
|---|---|---|---|---|
| 1 | `paste-eight-files-into-your-agent` | "I need to give it these eight files and I'm doing it one at a time" | Finder | **41.1 min** |
| 2 | `turn-an-answer-back-into-files` | "It gave me four files as one blob of markdown and now I'm copy-pasting each one" | Finder * | **28.5 min** |
| 3 | `which-agent-is-waiting-for-you` | "Nine terminals. One of them stopped four minutes ago and I don't know which" | Menu bar | *attention* |
| 4 | `clipboard-straight-into-a-file` | "I have the answer on my clipboard and now I open an editor, paste, name it, save it" | Finder | 12.9 min |
| 5 | `stop-typing-file-paths` | "I keep retyping paths into prompts and getting the escaping wrong" | Finder | 9.1 min @ **32×/day** |
| 6 | `agent-rules-in-one-click` | "Every new project needs CLAUDE.md and I write it from memory each time" | Finder * | 9.9 min |
| 7 | `whats-on-port-3000` | "Something is on 3000 and I don't know which of six windows it is" | Menu bar | 4.9 min |
| 8 | `a-clean-room-for-a-risky-agent` | "I want to let it run wild without it touching anything I care about" | Finder * | 7.3 min |

`*` needs Part C.

Case 3 has no ledger row and the largest emotional weight. Do not force a minutes figure onto it —
its cost is attention, not seconds, and saying so is more honest and more persuasive than a
number invented to match the others.

### The 16 shorts — the free CLI, and the ToFu argument

`#17` decompose 15.6 · `#14` env inject 13.4 · `#18` ponytail 9.5 · `#16` scratchpad 8.8 ·
`#22` buf 8.2 · `#11` diff 4.9 · `#5` tree 4.5 · `#10` latest 4.3 · `#19` redact 5.8 ·
`#21` broadcast 5.5 · `#12` checkpoint 3.3 (+~20 risk-adjusted) · `#23` dataurl 2.7 ·
`#20` gist 2.8 · `#4` syntax 2.0 · `#24` tokens (prevents overflow) · `#8` open here 5.9

Each gets a ≤6s terminal clip and a card. Frame the whole block as **"and all of this is free"** —
it is the strongest possible argument that the paid part is worth $19, because it shows how much
is being given away.

`#12 checkpoint` carries "+~20 min/day risk-adjusted" in the ledger. On the page state the
mechanism, not the adjusted number: *"it snapshots before the agent runs, without touching your
worktree"*. An unexplained risk-weighted figure reads as inflation.

---

## PART E — Page architecture

```
/                     landing — pain-ordered, hero demos, trial CTA
/cases                all 24, filterable by surface and by cost
/cases/<slug>         × 24, generated from cases.ts
/buy /docs /support /refunds /privacy /terms /changelog    (exist, keep)
```

### Landing, in order

1. **Hero.** Keep the current H1 — it survived and it answers the killer objection. Below it, the
   `which-agent-is-waiting` demo, not a terminal recording. Primary CTA: *Download — free 14 days*.
   Secondary, small: `brew install avaluev/tap/chute`.
2. **The eight, in pain order.** Each: the pain in the reader's words → the ritual today → the
   demo → seconds saved and how often. **Pain first, product second, always.** No section may
   open with a command name.
3. **What the $19 buys vs what is free.** Two columns, explicit. This is the conversion moment.
4. **"And 16 more, free."** The shorts grid, linking to `/cases`.
5. **Trust.** Preview-by-default, never `rm`, no network except `gist`. Lift from `README.md`.
6. **Price.** Trial framing. One CTA.
7. **FAQ.** Existing, plus the objection each hero case raises.

### Each case page

`H1 = the pain`. Then: the ritual today · the demo (autoplaying, muted, looping) · what it costs
you per day · how to do it · the CLI equivalent if there is one · *"this is part of the app"* or
*"this one is free"* · next/previous case · the trial CTA.

These are the SEO surface. Someone searching *"paste multiple files into claude code"* should land
on their own demo, already in pain, with the fix on screen.

---

## PART F — Demo production

`demo/gui/record.sh` exists and handles Finder and menu-bar recording. `demo/verify.sh` proves a
command works **before** it is filmed. `demo/reframe.sh` turns one master into every aspect ratio.

**Extend `demo/verify.sh` to all 24 cases before recording anything.** It covers 13 today. A case
that cannot be verified must not get a page — that is exactly how the failing `unpack.gif` shipped.

**Hero demos (8):** real Finder, real menu bar, 10–15s, MP4 + WebM + poster. Real speed, no
zoom, no cursor highlights, no music — the rules in `marketing/04-PRICING-AND-DEMO.md` hold.
Each opens on the *problem state* (a messy selection, nine terminal windows), not on Chute.
**The before-state is the hook.** A demo that opens on the solution has skipped the argument.

**Short demos (16):** VHS tapes, ≤6s, GIF, existing pipeline.

**New check** in `site/scripts/check-paddle.mjs` (or a sibling): every `demo` and `poster` named
in `cases.ts` must exist on disk. A case page with a missing video is this month's `og.png`.

---

## PART G — Design system

Wire these in. They are the difference between a page that looks designed and one that looks
generated.

| Resource | Use it for |
|---|---|
| **ui-skills.com** | Design-engineering skills for agents, via CLI or MCP. Install FIRST — it makes the agent build to rules instead of to generic habit. Carries skills from shadcn, Anthropic and Emil Kowalski. |
| **ui.shadcn.com** | Already the base. Components live in the repo, so they are editable. Keep the token override in `site/src/app/brand.css` — shadcn's defaults are the templated look. |
| **coss.com/ui** | Components over the shadcn base, aimed partly at AI apps. Open source. Use for the cases grid and filters. |
| **designsystemchecklist.com** | The quality frame. Feed it to the agent as the bar to check the finished frontend against, colours through documentation. |
| **beautifului.dev** | AI-interface components — streaming loaders, code blocks, agent-action cards, workflow visualisation. Directly relevant: this product is *about* agents. |
| **beui.dev** | Framer Motion + Tailwind animated components, installs via the shadcn CLI. Modals, tabs, toasts. |
| **rareui.com** | A few striking animated components, one file each. Use at most **one**, in the hero. More than one and the page becomes a showreel. |
| **transitions.dev** | Ready-made transitions and microanimations — modal opens, skeletons, number animation, card resize. |
| **emilkowal.ski/ui/you-dont-need-animations** | **The governing constraint. Read it before using any of the four libraries above.** |

### The animation rule, and it outranks every library here

From Emil Kowalski (author of `sonner` and `vaul`): **frequent actions should not be animated, and
everything should stay under 300 ms.** Applied here:

- The hero demo may have one considered entrance. Nothing else on the page animates on load.
- Filtering `/cases` must be **instant**. It is a frequent action; animating it makes the page feel slow while looking busy.
- Never animate anything a returning visitor sees more than twice.
- No scroll-triggered reveals on the case list. 24 sections that fade in as you scroll is the single clearest signal of a generated landing page.
- Motion earns its place by explaining a state change. Decoration does not qualify.

**Anti-slop rules (unchanged, and non-negotiable):** no violet/indigo gradient · no glassmorphism ·
no floating blurred blobs · no 3D isometric art · no AI orb · no emoji as section icons ·
`--radius: 4px` · one shadow token, on the hero frame only · every image is real recorded product
output · the words *seamless, powerful, revolutionary, supercharge, effortlessly, unlock, elevate*
are banned.

---

## PART H — Copy

Every case follows one shape, and the order is the argument:

> **The moment.** "Nine terminals. One stopped four minutes ago. You don't know which."
> **What you do now.** "You click through each window reading the last line."
> **What happens instead.** "The menu bar already says which one, and clicking it brings that terminal forward."
> **What it costs you.** "About 40 times a day."

Rules: pain before product, always · numbers from the ledger, never invented · second person ·
one idea per sentence · no adjective where a number will do · never explain the mechanism before
the reader wants it.

Where a claim has no measurement — case 3 — say what it costs in attention and do not invent a
figure. The page is more credible with one honest gap than with 24 identical-looking numbers.

---

## PART I — Execution order

| # | Task | Gate |
|---|---|---|
| 1 | Extend `demo/verify.sh` to all 24 cases | `./demo/verify.sh` → 24 passed, 0 failed |
| 2 | **Part C** — four new Finder actions | `swift run chutetests && ./Scripts/smoke.sh`, then a hand-driven right-click of each |
| 3 | `site/src/lib/cases.ts` — all 24, from the ledger | a script asserts every `savedMinutes` matches `docs/03-JTBD-LEDGER.md` |
| 4 | Install ui-skills + the component libraries | agent builds to the skills, not to habit |
| 5 | Record 8 hero demos (`demo/gui/record.sh`) | verify.sh green first; watch each one back |
| 6 | Record 16 shorts (`make -C demo demos`) | `make check` |
| 7 | Rebuild `/` from `cases.ts` | Lighthouse ≥ 95; read at 375 px wide |
| 8 | Build `/cases` + 24 case pages | every route 200; every demo and poster resolves |
| 9 | Rewrite `/buy` and `/docs` to match | `npm run check:paddle` |
| 10 | Full pass against designsystemchecklist.com | recorded in the spec, gaps listed |

**Do not start 5 before 2 lands.** Three of the eight hero demos film Finder actions that do not
exist yet.

---

## PART J — Verification

```bash
swift run chutetests && ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && ./demo/verify.sh
cd /Users/sxope/Documents/2026/Development/37.chute/demo && make check
cd /Users/sxope/Documents/2026/Development/37.chute/site && npm run build && npm run check:paddle
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/deploy-site.sh
```

Then the check no script performs, and the one that caught every real bug on 2026-08-27:
**open the deployed page and look at it.** Four bugs shipped that day past green builds and HTTP
200s — a page rendering with no CSS at all, a page rendering pure white, every image 404ing, and a
demo of the product failing. Every one was invisible to automation and obvious to an eye.

---

## Open questions

1. **Does the free CLI keep `unpack` once it is a Finder action?** Yes under the locked open-core
   split — the CLI is free in full, the app sells the surface. Worth restating on the page, because
   a reader who sees `unpack` in both columns will otherwise think it is a mistake.
2. **13 Finder rows may be too many.** Decide by right-clicking, not by reasoning. If it reads as
   crowded, group the four new ones under one submenu.
3. **`chute sandbox --help` launches an agent** instead of printing help — it treats `--help` as a
   sandbox name. Harmless in a demo, embarrassing in a terminal. Small fix, not part of this work.
