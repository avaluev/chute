# The website — rebuild, screenshots, and organic discovery

> Written 2026-09-01 from three research documents in `docs/research/`:
> `solopreneur-ai-utilities.md` (8 competitor pages fetched section by section),
> `seo-geo-aio.md` (742 lines, the GEO paper read from the PDF), and `gtm-tactics.md`.
> Every rule below carries its evidence. Where the evidence is weak, it says so.

---

# PART 1 — THE REBUILD

## The one finding that changes the site

**Eight of eight comparable products use a static screenshot hero. Not one uses a video.**
Two go further and rebuild their UI live in the DOM (SessionWatcher, BoltAI). The site currently
opens with an autoplaying `.mp4`.

**This does not mean delete the videos.** Chute's recordings are not product tours — each one is a
two-take race with a stopwatch burned into the frame, the manual ritual against the right-click.
That is *evidence*, and evidence belongs below the fold where a sceptic goes looking, not above it
where a first-time visitor has to wait for it to load before understanding what the product is.

**Decision: static screenshot hero, videos demoted to a "Don't take my word for it" proof band.**

## The nine patterns to copy, each seen on 5+ of the 8

| # | Pattern | Chute today |
|---|---|---|
| 1 | Static screenshot hero of the real UI | ✗ autoplay video |
| 2 | H1 is a **noun phrase naming the surface**; the subhead explains | ✗ H1 is a metaphor ("Chute is the door between them") |
| 3 | Price + reassurance as **one line under the button** | ✗ price is a section far below |
| 4 | "Pay once" stated as words — *once, forever, no subscription* | ~ present but not above the fold |
| 5 | **Five numbered feature screenshots** | ✗ five case strips with videos |
| 6 | Local-first / no-account / no-telemetry **above the fold** | ~ in a badge, easy to miss |
| 7 | A changelog — present on every product >$19, absent on every one <$9 | ✓ current as of 0.2.1 |
| 8 | Comparison page vs the **free/native alternative**, never a rival | ✗ does not exist |
| 9 | Testimonials from GitHub/X profiles with avatars, or none at all | ✗ none — correct for now |

On #2: the one product in the scan whose H1 was a joke (Conan, *"Command the campaign, by your own
hand"*) has to spend its entire subhead recovering. Chute's current H1 is a three-line metaphor.
It is well written and it does not say what the product is.

## The home page, top to bottom

**1. Hero.**
- H1, noun phrase, names the surface: **"Agent context, from the Finder right-click."**
- Subhead does the work: *"Select the folders. Right-click once. Every file inside is on your
  clipboard as one blob with a token count — for Claude Code, Cursor, or anything that reads text."*
- Primary CTA: **Download — free for {trialDays} days**. Under it, one line, no styling:
  *"$19 once. No subscription, no account. 14-day money-back guarantee."*
- Secondary CTA, quieter: `brew install avaluev/tap/chute` with a copy button — *"the CLI half is
  MIT and free forever"*.
- Hero visual: **one static screenshot**, the Finder context menu open on a real folder with the
  five rows visible, the notification badge showing `41 files · ~14k tokens`. See Shot 1.
- Trust line, above the fold, plain text: *macOS 13+ · no account · no telemetry · no network code*.

**2. The tax — three cards, highest number first.** Copy from `marketing/02-LANDING-COPY.md`. Each
card gets one static annotated screenshot, not a video.

**3. Five numbered feature screenshots, 01–05.** One per Finder row, in ledger order. Numbering is
the observed convention and it makes the surface feel finite, which is the argument: five rows, not
a suite.

**4. "Don't take my word for it" — the proof band.** This is where the videos live, and where they
are strongest, because now they have a job: each is a stopwatch race, manual against Chute. One
sentence above them: *"Two takes, one fixture, one stopwatch. The clock in the corner is read off
the timer, not typed in."* **Do not ship this band until `./demo/gui/by-hand.sh` has run** — until
then every figure is an estimate and this section is the most attackable thing on the site.

**5. Trust.** Preview-by-default, Trash not `rm`, checkpoint cannot touch your worktree, the
extension is sandboxed and cannot run a command. Keep as is; it is already the strongest section.

**6. Price.** One line, and the Mac-count decision below.

**7. FAQ.** Nine questions is the observed norm. Lead with *"Doesn't Claude Code already read
files?"* — it is the objection, and answering it first is the whole positioning.

## New pages

| Page | Why | Effort |
|---|---|---|
| **`/vs`** | The category's convention is comparison against the *free/native* alternative, never a rival — Pathly vs native macOS, SessionWatcher vs `ccusage`. Chute's version: **`@`-mentions, `repomix`, and Automator Quick Actions.** Concede where they win: repomix packs better and is free and cross-platform. An honest "here is when not to buy this" page is also defensive cover for Show HN. | 3 h |
| **`/docs`** | Exists. Nobody under $19 publishes a real docs site; guides + FAQ are the substitute. Leave it. | — |
| **Newsletter capture** | Skip. No audience to send to, and it is a section that converts nothing while looking like it should. | — |

## Two decisions only the founder can make

**Price.** $19 sits in an empty band: Mac App Store products cluster $3–$10, direct-sold cluster
$25–$59, and $15–$19 is unoccupied. The two closest comparables in kind — native, solo, one-time,
AI audience — both chose **$29** (Conan, ChatWise). The liftable idea is VoiceInk's: **tier by Mac
count, not features** — identical product at $25/1, $39/2, $49/3. Chute's version would be
**$19 one Mac / $29 three Macs**, which keeps the $19 anchor and puts a $29 option on the page.
Observed licence norm is 2–3 Macs; the site currently says nothing about machine count at all.

**Trial and refund.** 14 days is the field norm (62%), but 7 is right when the value lands in one
session — Chute's lands in about ten seconds. Trials convert 10–25% against freemium's 2–5%. And
the refund wording is standardised across the field; copy it verbatim: **"14-day money-back
guarantee, no questions asked."** 30 days appears only above $79. The site currently offers 30.

---

# PART 2 — THE SCREENSHOTS

## What exists, what does not

Five GUI recordings exist at 1280×800 / 1280×996, ~10–12 s each, with poster frames:
`paste-a-whole-folder-into-your-agent`, `which-agent-is-waiting-for-you`,
`clipboard-straight-into-a-file`, `stop-typing-file-paths`, `whats-on-port-3000`.
`demo/reframe.sh` already turns any master into 16:9, 1:1, 4:5 and 9:16.

**Five of nineteen cases have no recording, and one of them is the differentiator:**
`collect-files-over-several-copies` — the Context Basket, the only row nothing else on the Mac
ships. **Do not record it yet.** `handoff/NEXT.md` still asks whether the Basket survives at all,
and recording it is polishing before the answer. Answer first, then shoot.

## The shot list

Static, PNG, 2× retina, real content only — no lorem, no invented filenames. macOS light appearance
with the system accent set to blue, because the menu row icons are colour-coded and a random accent
fights them.

| # | Shot | Where | What is in frame | State |
|---|---|---|---|---|
| **1** | **Hero.** Finder window, three folders selected, context menu open, the five Chute rows visible. Notification in the corner: `41 files · ~14k tokens`. | home hero, OG image | The whole product in one frame. This is the single most important asset on the site. | **to shoot** |
| 2 | Copy Files as Context — after state: the pasted blob in Claude Code, token badge visible | feature 01, /cases | the wedge | **to shoot** |
| 3 | Copy Full Paths — three paths on the clipboard, correctly quoted, one containing a space | feature 02 | proves the escaping | **to shoot** |
| 4 | Copy Folder Tree ▸ — the submenu open showing 2 / 4 / All Levels, and a pasted tree beside it | feature 03 | **to shoot** |
| 5 | Add to Context Basket — menu bar open, basket holding files from three different folders | feature 04 | **blocked** on the Basket decision |
| 6 | New File ▸ — submenu open, Empty Markdown / From Clipboard / Image | feature 05 | **to shoot** |
| 7 | Menu bar — five sessions, one badged as waiting, per-session CPU and memory | proof band, /cases | **exists** as video; needs a still |
| 8 | The confirmation sheet for a destructive action, showing the real list | Trust section | this is the section's whole claim, and nothing currently shows it | **to shoot** |
| 9 | `chute doctor` output, all ten checks | /docs, /support | it is a genuinely reassuring screen | **to shoot** |
| 10 | Terminal: `brew install` through to `chute bundle src/` with the token badge | /cli, LinkedIn posts | **to shoot** |

**Ten shots, one afternoon.** Six of them need no new fixture — the app is installed and working at
`/Applications/Chute.app`, stamp `c9ed42f`.

## Rules for every shot

- **Real content.** A screenshot with `foo.ts` and `bar.ts` in it tells a developer you did not use
  your own product.
- **Crop to the claim.** The hero shot is the menu, not the whole desktop. A 1440-wide screenshot
  scaled into a 600px column is unreadable on the device most people are holding.
- **No drop shadows, no perspective, no floating browser chrome.** The competitor set is uniformly
  plain and it reads as confidence.
- **One idea per image.** If the caption needs "and also", it is two images.
- **Alt text on all of them**, describing the content rather than the file.
- The OG image is Shot 1 recropped to 1200×630 — the same picture everywhere is a feature.

---

# PART 3 — SEO, GEO AND AIO

## Do this today, it takes 90 seconds and has a 7-day fuse

**Create the AlternativeTo account now.** There is a reported 7-day account-age gate before you can
submit a product, and AlternativeTo ranked #1 on the control "alternatives" query. Everything else
in this section can wait; this one has a clock on it.

## GEO — what the research actually measured

From the KDD '24 paper *"GEO: Generative Engine Optimization"*, numbers taken from the PDF rather
than from blog coverage. Baseline visibility **19.3**:

| Intervention | Score |
|---|---|
| **Quotation Addition** — quote a real source verbatim | **27.2** |
| **Statistics Addition** — replace vague claims with numbers | **25.2** |
| **Cite Sources** — link the source of each claim | **24.6** |
| *Keyword Stuffing* | *17.7 — **worse than doing nothing***, and 10% below baseline on live Perplexity |

**The number that matters most to Chute is not the headline.** Table 2 of the same paper: Cite
Sources moves a **rank-5 source +115.1%** and the **rank-1 source −30.3%**. These tactics are worth
far more to a site with no authority than to repomix. Chute is the rank-5 source in every query it
cares about.

**This is the same voice the fact sheet already enforces** — numbers over adjectives, every claim
with the command that proves it. The GEO research is, unusually, telling us to keep doing exactly
what the house style already requires. The one change: **cite and link outward more.** Link to the
`git stash create` documentation, to Apple's hardened-runtime page, to repomix's repo.

## What NOT to spend time on

- **llms.txt is dead.** 97% of files got zero requests across 137,000 domains; 0.1% of AI-bot
  visits; a 900-domain study found not one real AI bot; Google documents that it ignores it.
  **Shipped anyway, for one narrow reason:** the bots that *did* fetch it were coding agents, with
  Claude-Code named among the top requesters — which is exactly and only Chute's ICP. Ten minutes,
  as a lottery ticket, already done and generated from `cases.ts` so it cannot rot.
- **Schema is a 30-minute job, not a strategy.** FAQ rich results were deprecated 2026-05-07 and
  HowTo in 2023; Google documents that no special schema is needed for its AI features; the best
  controlled test concluded its lift was algorithmic, not schema-driven. `SoftwareApplication` is
  shipped. Stop there. **Every "schema = 2.5× more citations" figure in circulation traces to a
  vendor blog with no study behind it — do not repeat them.**
- **Do not block AI crawlers.** `robots.txt` allows everything, deliberately. Note the distinction
  the research drew from vendor docs: `OAI-SearchBot`, `Claude-SearchBot` and `PerplexityBot` feed
  *answers* — blocking them removes you from the conversation. `GPTBot`, `ClaudeBot` and
  `Google-Extended` are training-only.

## The keyword finding that changes the copy

Volumes are unavailable without a paid tool and the research says so rather than guessing. From
Google Autocomplete:

- The biggest cluster is **"claude code context window full"** — six variants, full-sentence
  queries. People are not searching for a tool; they are searching for a symptom.
- **"how to add multiple files to claude code"** is the second cluster.
- **`"copy files for llm"` returns zero suggestions. Kill that phrasing from the copy.**

That reshapes `/vs` and any future writing: **write to the symptom, not the category.** A page
titled *"Claude Code's context window keeps filling up"* is closer to the query than any page with
"context tool" in the title.

The SERPs are not locked up: GitHub repos and official docs hold the top slots, but indie blogs
(agentsroom.dev, learncursor.dev) sit on page 1 beside them. Reddit and Stack Overflow did not
surface at all on these dev queries.

## The measurement that ends the guessing

Third-party Homebrew taps **are** in the public analytics JSON — this resolves an open question
from `gtm-tactics.md` §6c. It gives a real denominator, and a calibration for what the numbers mean:

| Rank in the public list | Installs / month |
|---|---|
| 101 | 824 |
| 501 | 79 |
| 1,001 | 31 |
| — | **6,677 formulae sit at exactly 1** |

That last row is the honest one. One grep against
<https://formulae.brew.sh/analytics/install-on-request/30d/> is Chute's free, third-party,
verifiable top-of-funnel number, and there is no excuse for estimating it.

## The ten-hour checklist, in order of expected return

| # | Task | Hours | Evidence |
|---|---|---|---|
| 1 | AlternativeTo account **today** | 0.05 | 7-day age gate; ranked #1 on the control query |
| 2 | Hero rewritten as noun phrase + static Shot 1 | 2 | 8/8 competitor pattern |
| 3 | Price + reassurance line under the button | 0.25 | 6/8 |
| 4 | `/vs` — vs `@`-mentions, repomix, Quick Actions, conceding where they win | 3 | category convention; Show HN defence |
| 5 | Symptom-titled page: "Claude Code's context window keeps filling up" | 2 | the largest autocomplete cluster |
| 6 | awesome-list PRs | 1 | highest ROI/hour in `gtm-tactics.md`; `awesome-mcp-servers` = 93,127 stars |
| 7 | Outbound citations added across existing pages | 1 | Cite Sources 24.6 vs 19.3, and +115.1% for a rank-5 source |
| 8 | Homebrew analytics bookmarked and a baseline recorded | 0.1 | the only free verifiable funnel number |
| 9 | ~~sitemap, robots, JSON-LD, llms.txt~~ | ~~1~~ | **done 2026-09-01** |

**Total remaining: ~9.4 hours.** None of it needs money and none of it needs an audience.

---

## What this file does not claim

No number here was estimated. Where the research could not find one — keyword volumes, a
solo-founder LinkedIn benchmark, a published CLI→GUI conversion rate — the research document says
so and this file repeats the gap rather than filling it. `docs/research/` carries the tags.
