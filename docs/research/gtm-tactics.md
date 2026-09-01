# GTM tactics that actually worked — evidence file for Chute

Researched 2026-09-01. Chute = $19 one-time macOS utility for devs living in Claude Code / Cursor.
Free half = MIT CLI (`brew install avaluev/tap/chute`). Paid half = Finder right-click menu + menu bar app.
Solo founder, no budget, no audience, imminent launch.

**Reading key**
- `[VERIFIED]` — number appeared in a primary source I fetched (founder's own write-up, official docs, platform page).
- `[SECONDARY]` — number appeared in an aggregator/blog citing someone else. Treat as directional, not bankable.
- `[UNVERIFIED]` — claim I could not trace to a primary source. Do not put in a pitch deck.

Aggregator blogs about "2026 statistics" are heavily SEO-farmed and cite each other in circles.
I have marked those `[SECONDARY]` even where they name a source, because I could not always reach the source.

---

## 0. The short version (if you read nothing else)

1. **Section 5 is the whole game.** Chute's buyers are already inside Claude Code. The distribution
   surfaces that reach them — plugin marketplace, skills, MCP registries, awesome-lists — are
   *undersupplied relative to attention* right now, the way the App Store was in 2009 and the VS Code
   marketplace was in 2016. Everything else in this doc is a one-day spike.
2. **Show HN is the single highest-EV one-day event** for this exact product shape (dev tool, macOS,
   free OSS half, one-time price). It is free, it allows commercial products explicitly, and its
   audience is literally the ICP. Product Hunt is worth ~1 hour of effort, not ~1 week.
3. **The free CLI is not a funnel unless it says so.** Every documented open-core conversion story
   turns on a deliberate, visible upgrade seam. A silent MIT repo converts approximately nobody.
4. **The evergreen channel is SEO comparison pages + awesome-list placement.** They compound; launches
   do not.

---

## 3. SHOW HN MECHANICS (2025–2026)

### The actual rules — primary source

`https://news.ycombinator.com/showhn.html` (fetched 2026-09-01). `[VERIFIED]`

Verbatim / near-verbatim points from the guidelines page:

- "Show HN is for something you've made that other people can play with."
- Off topic: **"blog posts, sign-up pages, newsletters, lists, and other reading material."**
- "New features and upgrades ('Foo 1.3.1 is out') generally aren't substantive enough."
- Projects must be non-trivial and personally meaningful; you should be around to respond to comments.
- **Minimise friction** — avoid signup walls or email requirements.
- Work needn't be polished but must be functional.
- Don't solicit upvotes.

**What this means for a $19 paid macOS app — the critical read:**

Show HN does **not** ban commercial or paid products. What it bans is *reading material* and
*things people cannot play with*. A paid-only download behind a licence key is functionally a
sign-up page — that is where paid launches get flagged or die in `/shownew`.

Chute is in an unusually strong position here: **the MIT CLI is the "something people can play with."**
The correct Show HN is the CLI (free, `brew install`, no signup, source on GitHub), with the paid
GUI mentioned honestly in the first comment. That satisfies the letter and the spirit of the rules.
A Show HN of the $19 GUI alone is the version that gets flagged.

### Front-page mechanics

- `[SECONDARY]` ~2.3% of all HN submissions reached the front page in Q1 2026; a post typically needs
  **30–50 upvotes in the first hour** to have a shot. (daily.dev Ads, "Hacker News Marketing for
  Developer Tools", https://business.daily.dev/resources/hacker-news-marketing-developer-tools-show-hn-launch-day-sustained-coverage/)
- `[VERIFIED, structural]` Show HN posts get a dedicated `/shownew` queue
  (https://news.ycombinator.com/shownew) — a second discovery surface that plain submissions lack.
  This is real and checkable, not a growth-blog claim.
- `[SECONDARY]` Show HN posts get a grace period where downvotes are disabled. Directionally
  consistent with HN's documented behaviour but I could not find this in official guidelines text.

### Title patterns that fit the rules

The guidelines force the shape: `Show HN: <name> – <what it does, plainly>`.
Observed conventions on `/show` (checkable live):
- En dash separator, lowercase after it, no marketing adjectives.
- Naming the platform when it's a constraint ("for macOS") pre-empts the top comment being
  "is this Mac-only?" — which wastes your best comment slot.
- No "revolutionary", no "AI-powered" unless it literally is the mechanism, no exclamation marks.

### First comment — this is the highest-leverage 200 words you will write

The convention on HN is that the author posts a first comment giving the backstory. For a paid
product this comment is where you defuse the two objections that kill paid Show HNs:

1. **"Is this a rug-pull / open-core bait?"** → State exactly what is MIT and stays MIT, and what
   is paid. Link the LICENSE.
2. **"Why is this not free / why $19?"** → One honest sentence. HN respects one-time pricing and
   is actively hostile to subscriptions for utilities. `$19 one-time` is an asset here, say it.

Also standard and effective: why you built it, what it does *not* do, and what you want feedback on.

### What gets flagged

From the guidelines plus observed norms:
- Landing page with no working artifact → off topic, flagged.
- Email wall before you can try it → violates "minimise friction", reliably draws hostile comments.
- Reposting the same product repeatedly, or posting a `1.3.1` release → not substantive.
- Vote solicitation (Slack/Discord/Twitter "please upvote") → HN detects voting rings and penalises.
- Astroturfed praise comments → the fastest way to get a domain banned.

`[UNVERIFIED]` I did not find a reliable published dataset of optimal posting *time* for 2025–2026.
Widely repeated folk wisdom is US-morning weekday (roughly 13:00–16:00 UTC). Treat as folklore.
The competition-vs-audience tradeoff is real but I have no defensible number for it.

---

## 4. PRODUCT HUNT IN 2025–2026 — is it worth it for a $19 dev utility?

**Verdict: worth about one hour, not one week. Launch it, do not build a campaign around it.**

### The numbers (all `[SECONDARY]` — aggregator sources)

Traffic by daily rank (Causo Hub, updated 2026-08-07, attributing Lenny's Newsletter / First Round):
https://hub.causo.ai/guides/product-hunt-traffic-data-2026

| Daily rank | Visitors (launch day) | Signups |
|---|---|---|
| #1–3 | 5,000–15,000 | 100–400 |
| #4–10 | 1,000–3,000 | 30–100 |
| #11–30 | 300–700 | 10–30 |
| #31+ | <300 | <10 |

Conversion by category, same source: **dev tools / API, top 3 → 1.5–3% visitor-to-signup.**

Traffic decay, same source: day 0 ≈ 60% of all traffic, days 1–7 ≈ 25%, days 8–30 ≈ 15%.
SEO tail only for top-3 finishers.

From shno.co's stats roundup (https://www.shno.co/marketing-statistics/product-hunt-launch-statistics):
- `[SECONDARY]` Only ~10% of launches now receive **featured** status (vs 60–98% in 2020–2023);
  featured status is claimed to drive ~70% of a launch's outcome. Non-featured ≈ 70% less traffic
  *regardless of upvotes*. (attributed to Tetriz.io via Awesome Directories, Nov 2025)
- `[SECONDARY]` Featured products: 1,000–5,000 visitors, 10–150 signups. Non-featured: 100–500
  visitors, 1–15 signups.
- `[SECONDARY]` Top-of-day typically needs 400–800+ upvotes; "at least 400 committed supporters in
  the first 4 hours". **A founder with no audience cannot produce 400 supporters. This is
  disqualifying for Chute's #1 ambitions and should be treated as such.**
- `[SECONDARY]` PH ~3.1% conversion vs Indie Hackers ~23.1% (OpenHunts 2024 study, via Awesome
  Directories). Directionally: PH traffic is low-intent for a paid dev utility.
- `[SECONDARY]` Counter-example worth internalising: "Tomas Blatak (2024): 612 upvotes, #1 ranking,
  **one** paying customer." Rank ≠ revenue.
- `[SECONDARY]` Spring-2026 founder roundup: "rank did not predict revenue; paid conversion ranged
  0 to ~20%, and the highest-ranked launch reported the lowest conversion."
  (https://happysupport.ai/blog/product-hunt-launch-roundup-2026)

### The one durable reason to still do it

`[SECONDARY]` PH has domain authority ~91. The permanent backlink and the product page ranking for
"chute" + "alternative to X" queries outlives the launch day. That is a ~1 hour investment for a
permanent DA-91 backlink. Do that. Do not spend a week chasing #1.

### Current mechanics

- Launch day runs 12:01am PT to 11:59pm PT. Rank resets daily.
- **Featured** (curator-selected) is the gate that matters, not upvotes. `[SECONDARY]`
- A "hunter" is no longer required — self-hunting is standard now and does not penalise you.
  A high-follower hunter mainly buys initial notification reach. `[UNVERIFIED for 2026 specifics]`
- Maker comment at launch + replying to every comment is the one behaviour every playbook agrees on.


---

## 5. DISTRIBUTION INSIDE AI CODING TOOLS — the highest-priority section

**Headline finding: there is now a real, measurable, one-command install surface for Claude Code /
Cursor users, and it is dominated by a handful of skills with install counts in the hundreds of
thousands to millions. Chute's CLI belongs in it. This is the channel with the best ratio of
(effort) to (reaching exactly the ICP).**

### 5a. The four distribution surfaces, ranked by leverage for Chute

| Surface | Install mechanic | Scale (2026) | Effort | Verdict for Chute |
|---|---|---|---|---|
| **Agent skills / skills.sh** | `npx skills add <owner/repo>` | 3.2M installs on the top skill | ~1 day | **Do this first** |
| **Claude Code plugin marketplace** | `/plugin marketplace add owner/repo` then `/plugin install` | official marketplace 200+ plugins | ~1 day | **Do this second** |
| **MCP server + registries** | server config / `claude mcp add` | 9,652–20,222 servers listed | ~2–3 days | Only if Chute has a genuine tool surface |
| **awesome-* lists** | GitHub PR | `punkpeye/awesome-mcp-servers` 93,127 stars | ~1 hour each | **Highest ROI per hour. Do all of them.** |

### 5b. Agent Skills / skills.sh — the strongest single lever

`[VERIFIED]` Vercel announced the open agent skills ecosystem on **2026-01-20**
(https://vercel.com/changelog/introducing-skills-the-open-agent-skills-ecosystem).

- Install command: **`npx skills add <package>`** `[VERIFIED]`
- Supported agents, verbatim from the changelog (17 listed): amp, antigravity, **claude-code**,
  clawdbot, codex, **cursor**, droid, gemini, gemini-cli, github-copilot, goose, kilo, kiro-cli,
  opencode, roo, trae, windsurf. `[VERIFIED]`
  → **This is the single biggest strategic fact in this document: one artifact reaches Claude Code
  AND Cursor AND 15 other agents through one install command.** Chute's ICP is exactly this set.
- Directory: https://skills.sh `[VERIFIED, fetched 2026-09-01]`
  - Site self-reports **1,348,411 total skills** listed.
  - Top skills by 8-week activity: `find-skills` (vercel-labs) **3.2M**, `grill-me` **1.0M**,
    `grill-with-docs` **872.5K**, `frontend-design` **840.8K**.
  - Publishing is GitHub-repo based (`npx skills add <owner/repo>`).

`[SECONDARY]` Third-party trackers report skills.sh at ~60,788 skills / ~125M recorded installs as
of July 2026 (skillselion.com). These conflict with skills.sh's own 1.35M figure — the two are
almost certainly counting different things (packages vs. individual skill files). **Do not cite
either number externally.** The safe, defensible claim is: *the top skill has millions of installs
and the ecosystem is measured in millions of installs.*

**What this means concretely for Chute:**
A `chute` skill that teaches the agent how to invoke the MIT CLI is a legitimate, useful artifact —
not spam. The agent learns the CLI; the human sees the tool work; the GUI upsell is one line in the
SKILL.md and one line in the CLI's own output. This is the only channel in this document where the
distribution artifact and the product are the same thing.

**The trap:** 1.35M listed skills means discovery inside the directory is already near-worthless.
Installs come from *someone linking your skill*, not from browsing. Ranking on skills.sh is an
output of other channels, not an input.

### 5c. Claude Code plugin marketplace — exact mechanics

Primary source: https://code.claude.com/docs/en/plugin-marketplaces `[VERIFIED, fetched 2026-09-01]`

Repository structure:
```
your-marketplace/
├── .claude-plugin/
│   └── marketplace.json
└── plugins/
    └── your-plugin/
        ├── .claude-plugin/
        │   └── plugin.json
        └── skills/
            └── your-skill/
                └── SKILL.md
```

`marketplace.json`:
```json
{
  "name": "your-marketplace",
  "owner": { "name": "Your Name", "email": "you@example.com" },
  "plugins": [
    { "name": "your-plugin", "source": "./plugins/your-plugin", "description": "Plugin description" }
  ]
}
```

Commands, verbatim from the docs:
- User adds your marketplace: `/plugin marketplace add owner/repo`
- Non-GitHub git host: `/plugin marketplace add https://gitlab.com/company/plugins.git`
- User installs: `/plugin install plugin-name@marketplace-name`
- You validate before publishing: `claude plugin validate .` (or `/plugin validate .`)

**Discovery — read this carefully, it is the whole catch.** The docs list exactly three discovery
paths: (1) *direct sharing* — you give people the repo URL; (2) *organization settings* via
claude.ai admin settings; (3) `extraKnownMarketplaces` in `.claude/settings.json`.

> **There is no browsable public plugin search built into the discovery story.** Publishing a
> marketplace does not get you found. It gets you an *install command you can paste into a
> README, a Show HN comment, a tweet, or a blog post.* That is still valuable — a one-line
> `/plugin marketplace add avaluev/chute` is a dramatically lower-friction CTA than "download a
> .dmg" — but budget zero organic traffic from it.

Community aggregators that DO provide browse/search (fill the gap above), worth submitting to:
- claudepluginhub.com `[SECONDARY]` — reported 36,633 plugins / 16,679 authors / 358,699 components
  / 24,049 install events in a trailing 30 days, as of ~2026-06-08. (Fetch returned 403; number is
  from search snippet — treat as unverified.)
- claudemarketplaces.com `[SECONDARY]`
- `github.com/anthropics/skills` — first-party skills repo `[VERIFIED it exists]`
- `awesome-claude-skills` GitHub list, ~13k stars `[SECONDARY]`

`[SECONDARY]` Individual plugin traction is *small* right now: tracked plugins showed **103–326
installs over 7 days** as of June 2026. **Calibrate expectations accordingly — this is a
high-intent, low-volume channel.** A few hundred installs of a well-targeted plugin from your exact
ICP is worth more than 5,000 Product Hunt tourists, but it is not a launch.

### 5d. MCP servers and registries

Scale `[SECONDARY, from Builder Radar week of 2026-08-30, https://buttondown.com/Builder-Radar/archive/builder-radar-week-of-august-30-2026/]`:
- `@modelcontextprotocol/sdk`: **52.1M weekly / 204M monthly npm downloads** — the most-downloaded
  AI package on npm that week (ahead of OpenAI 143M/mo and Anthropic 132M/mo).
- `modelcontextprotocol/typescript-sdk` 13,281 stars; spec repo 9,084 stars.
- **`punkpeye/awesome-mcp-servers`: 93,127 stars.**

Registry sizes `[SECONDARY]`:
- mcp.so — ~20,222 servers listed
- Official MCP Registry API — 9,652 latest server records / 28,959 server-version records (2026-05-24)
- smithery.ai, glama.ai/mcp, mcp.directory, mcpservers.org — other significant directories
- mcp.directory usage analysis across 1,864 servers: Context7 **11,000 views / 690 installs**;
  Sequential Thinking **569 installs**. → **Even the top of a major directory is in the hundreds of
  installs.** Directory browsing is not a growth channel; it is a credibility artifact.

Top individual servers `[SECONDARY]`: Context7 (Upstash) 44,000+ stars / 240,000+ weekly npm
downloads; `eyaltoledano/claude-task-master` 28K stars; `GLips/Figma-Context-MCP` 16K stars.

**Verdict for Chute:** build an MCP server *only if* the CLI has operations an agent would
genuinely want to call unattended. Do not build one for distribution — the install numbers above
show directories don't distribute. **But get into `punkpeye/awesome-mcp-servers` (93k stars) if you
legitimately qualify.** That list is a bigger audience than every MCP registry combined.

### 5e. Cursor

- `https://cursor.directory` — community directory for MCPs, rules, news, jobs. `[VERIFIED it exists]`
- `github.com/cursor/mcp-servers` — Cursor's own curated list of MCP servers. `[VERIFIED it exists]`
- Cursor MCP docs: https://cursor.com/docs/mcp
- `[SECONDARY]` Cursor supports team-distributed MCP servers via a team marketplace.

Cursor's *rules* directory is the low-effort entry: a `.cursorrules` / rule entry mentioning the
Chute CLI is a legitimate submission if the rule genuinely helps.

### 5f. VS Code marketplace — the analogue, and its warning

`[SECONDARY]` The VS Code Marketplace has tens of millions of users and **no built-in paid tier** —
"Free" and "Free Trial" only. Indie devs must build their own licensing. The standard, proven
pattern: **free extension in the marketplace for discovery, premium features behind a licence key,
payments handled off-platform.** Reported outcomes for "lean, well-maintained extensions":
$300–$2,100/month recurring. `[SECONDARY — from monetisation-vendor blogs, treat sceptically.]`

**The lesson that transfers directly to Chute:** *marketplace distribution provides discoverability
advantages that are difficult to replicate through direct distribution alone* — so put the free
thing where the marketplace is, and take the money outside it. That is exactly Chute's architecture
already (MIT CLI in Homebrew + skills/plugin ecosystems; $19 GUI sold direct). **The architecture is
right. The gap is that nothing in the free half currently tells anyone the paid half exists.**

---

## 2. OPEN-CORE / FREE-CLI-AS-FUNNEL

### The honest state of the evidence

**I could not find published, first-party conversion rates from a free CLI to a paid GUI for any of
Kaleidoscope, Proxyman, TablePlus, Dash, Warp, Fig/Amazon Q, or Raycast.** These companies do not
publish funnel numbers. Anyone who tells you "Proxyman converts at X%" is making it up.
What follows is what IS documented.

### Benchmarks that are published

`[SECONDARY]` Open-source / free-to-paid conversion benchmarks (getmonetizely.com, ChartMogul,
Lenny's Newsletter):
- Open-source SaaS typically **0.5–3%**, materially below closed SaaS.
- "Rule of 3s": **0.3–1%** viable for mass-market dev tools with huge adoption; **1–3%** the target
  for most open-source companies.
- **Elastic converted ~1% of its user base** and still built a multi-billion-dollar business on volume.
- Median free-to-paid for developer-focused companies **5%** — *half* that of companies not selling
  to developers. (i.e. developers convert worse. Plan for it.)

**Chute arithmetic, do this on paper before launch:** at $19 and a 1–3% conversion, 1,000 CLI
installs = 10–30 sales = $190–$570. **The free CLI must reach five figures of installs to matter
as a revenue funnel.** If that's not plausible in year one, the CLI's real job is *credibility and
trust*, not conversion — and it should be budgeted as marketing, not as a funnel.

### Documented cases

- **Proxyman** — `[VERIFIED-ish, from proxyman.com]` free basic tier / **$49 one-time Pro**; the
  site claims "used daily by 800k+ developers". GitHub repo `ProxymanApp/Proxyman` is the *public
  face* (issues, releases) — **the app itself is not open source.** This is worth noting: Proxyman
  gets the trust signal of a GitHub presence without giving away the product. `[UNVERIFIED]` No
  published revenue or conversion figures.
- **TablePlus** — `[SECONDARY, Tracxn]` unfunded/bootstrapped, founded by Huy Pham, **perpetual
  licence $99–$129 one-time**, no institutional funding, operating since 2017. Evidence that
  one-time pricing for a native Mac dev tool sustains a company. No published funnel numbers.
- **Raycast** — `[VERIFIED, TechCrunch 2021-11-30]` raised $15M from Accel and Coatue; `[SECONDARY]`
  $47M+ total, 2,000+ store extensions as of Aug 2026. The *store* is the distribution engine.
  Relevant lesson, not a conversion number: Raycast made third-party extensions the acquisition
  channel for the paid core.
- **`[UNVERIFIED]`** "~$100,000 Revenue with a simple Mac app" — startupsemail.substack.com. Found
  but not fetched/verified. Worth reading before launch.

### Documented mistakes in open-core (the pattern, from the sources above)

1. **The funnel is long and lossy**: adoption → community engagement → value recognition →
   conversion. Each step leaks. A CLI user who never hits the GUI's problem never converts.
2. **Free tier too generous → no reason to pay.** The upgrade seam must map to a *different job*,
   not a quota. Chute has this right structurally (CLI = scriptable/agent-facing; GUI = Finder
   right-click + menu bar = a job the CLI genuinely cannot do). **Keep it that way; resist adding a
   nag or a limit to the CLI — HN will punish it and it won't convert anyone.**
3. **The seam is invisible.** The single most common documented failure. Fix, concretely:
   - One line in `chute --help` and in the README naming the GUI and the price.
   - One line in the CLI's success output *the first time only* (never repeatedly — that's a nag).
   - The GitHub README is your highest-traffic marketing page. Treat it as a landing page.

---

## 1. SOLO INDIE macOS / DEV-TOOL LAUNCHES WITH PUBLISHED NUMBERS

Ordered roughly by how transferable the lesson is to Chute. **Note the systematic bias in this
genre: people publish wins, not flops.** The two cases below with *bad* numbers (Aidlab, Blatak)
are the most informative in the whole list.

### 1. Aidlab — Show HN front page, 0 sales `[VERIFIED — founder's own postmortem]`
https://www.indiehackers.com/post/front-page-of-hn-the-full-postmortem-traffic-lessons-surprises-cbe9e0a7f6
Show HN posted **2025-10-13**. Front page.
- ~6,000 page views; ~500+ unique visitors from HN; 2+ min avg session; 20% bounce on launch day
- Peak ~468 concurrent users on Oct 13; 100–150/day Oct 14–16
- 170+ unique visitors reached the shop pages
- **0 direct conversions.** 4 inbound inquiries from research teams; 8 LinkedIn requests (3 from VCs)

**What he'd do differently (his words):** *"The title ('Health Data for Devs') mattered more than I
thought: our first Show HN failed because it sounded too 'producty.'"* Second attempt added personal
co-founder context, code examples for the SDK, technical depth (on-device ML, edge-first design),
and free datasets as an engagement hook.

> **This is the most important single data point in this document.** HN front page ≠ sales.
> HN traffic converts on *technical credibility*, and the title is the lever. A "producty" title
> fails; a "here is a thing for devs, here is the code" title works. Budget HN as an
> awareness/credibility event, not a revenue event — and be pleasantly surprised.

### 2. Lunar (Alin Panaitiu / The Low-Tech Guys) — the closest analogue to Chute
Sources: https://notes.alinpanaitiu.com/Costs-of-running-a-macOS-app-studio-business `[VERIFIED]`
and https://www.indiehustle.co/p/no-ads-no-funnels-no-black-friday `[SECONDARY interview]`

2023 full-year, from his own numbers page:
| | Sales | Proceeds | Costs |
|---|---|---|---|
| App Store (rcmd, Grila, Gamma Dimmer) | $14,900 | $11,500 | $3,400 (15% commission, tax/FX) |
| Paddle (Lunar, Clop — direct) | $93,500 | $73,300 | $20,200 (5% commission, $15,500 tax/FX) |
| **Total** | **$108,400** | **$69,960 net (64% retained)** | $38,440 to intermediaries (36%) |

`[SECONDARY]` Lunar ~$7,000/mo, other apps ~$1,000/mo. **Price: $23 lifetime, set by polling users
(median answer was $23).** Costs: $50/mo server, $10/mo geolocation, $20/yr domains, $100/yr Apple.
~35% of revenue to taxes/VAT.

**Channels that worked, per the interview:**
- **Hacker News and niche communities — posted thoughtfully, only when relevant.** A technical blog
  post about his M1 challenges reached **30k views** and generated quality feedback.
- **Reddit `/r/macapps`** — effective for sharing updates with engaged macOS users.
- **Product Hunt — multiple launches (v1, v2, v3), "hundreds of users organically."**
  → Relaunching a major version on PH is normal and works. You get more than one shot.
- Early "Buy Me a Coffee" button surfaced feature requests from the most invested users.

**What did NOT work, his words:** *"I also tried conventional paid ads on Google, Facebook, Twitter
etc. but they are a money sinkhole for the niche that Lunar fills. Never got any sale from that,
thousands of dollars down the drain."*

> **Direct read-across for Chute:** open-source-adjacent, one-time-priced (~$23!), macOS utility,
> solo, no ads, sells direct through Paddle rather than the App Store, ~$100k/yr. The $19 price and
> one-time model are validated by the closest available comparable. **Also note: he sells direct,
> not through the App Store — 5% Paddle vs 15% Apple. And note the 36% total leakage. At $19, a sale
> nets you roughly $12.**

### 3. Tony Dinh — DevUtils, Xnapper (macOS dev utilities, one-time pricing)
`[SECONDARY — aggregated from indiehackers.com, thebootstrappedfounder.com, supabird.io]`
- DevUtils and Xnapper are **one-time purchases**, ~$3K–$6K/mo each; total across 3 products
  ~$15–20K/mo (2022). DevUtils peaked ~$20K/mo, still ~$8K/mo "on autopilot" in 2025.
- **Xnapper: a tweet demo got 1,700 likes → #1 on Product Hunt for the day and week → $10K+ in the
  launch month.** Exited for ~$150K ~21 months after launch. Black Magic exited for ~$128K.
- TypingMind: ~$10,000 in days from the launch tweet, **plus ~$14,000 from the Product Hunt launch.**
- Twitter: ~100 followers in 2021 → 97K by end of that arc → 181,000+ by 2026.

**His own words on the mechanism** `[VERIFIED quote via thebootstrappedfounder.com]`:
> *"If that tweet didn't blow up, if I didn't have like 70k or something followers? I don't think
> the product will have seen the day of light live day."*

> **The uncomfortable lesson for Chute: Dinh's results are downstream of an audience he spent two
> years building. You do not have one. Do not model your launch on his launch — model it on his
> 2021.** The transferable part is: build-in-public compounds, and a *demo video/GIF* is the unit
> of currency, not a blog post.

### 4. Simple Ops — $7,300 in month 1, HN front page `[VERIFIED via IH post]`
https://www.indiehackers.com/product/simpleops/7000-revenue-in-first-month-of-launch--MDYg2e63fJ8xDzLrSjC
July 2020. 30+ paid customers, ~$233 average — **majority of revenue from lifetime deals.**
Founder: *"I posted it on Hacker News and it made it to the front page."*
Caveat the founder's own framing acknowledges: pandemic-timed demand.
> Lesson: HN front page CAN convert directly — when the product solves an expensive, urgent,
> B2B-shaped problem. A $19 personal utility is not that shape. Expect Aidlab's outcome, not this one.

### 5. Product Hunt #1 with one customer `[SECONDARY]`
"Tomas Blatak (2024): 612 upvotes, #1 ranking, **1 paying customer**." (via Awesome Directories,
Nov 2025). Pair this with #3 — Dinh's #1 made $10K+. The difference is not the rank; it is whether
an audience already wanted the thing. **Rank is not a lever, it is a readout.**

### 6. Fig — the free-CLI-tool-with-a-community outcome `[VERIFIED, TechCrunch 2023-08-29]`
https://techcrunch.com/2023/08/29/amazon-fig-command-line-terminal-generative-ai/
At acquisition by AWS: hundreds of thousands of users, **22k GitHub stars, 13k Discord members,
400 open-source contributors**, 5 products; had raised just over $2M. Standalone Fig sunset
2024-09-01, folded into Amazon Q Developer.
> The autocomplete *specs* were the open-source community artifact; the app was the product.
> **The specs repo was the distribution.** Direct structural parallel to Chute's MIT CLI.

### 7. MacWhisper (Jordi Bruin / Good Snooze) `[UNVERIFIED — numbers conflict]`
Free tier + Pro licence, sold via Gumroad, launched Jan 2023. One search result claims "~$2M revenue
on Gumroad with 519.4K sales in the last 30 days (as of Aug 2026)"; another claims "~$100,000
revenue, 57,574 downloads." **These are mutually inconsistent and I could not verify either. Do not
use.** The *structural* lesson is the only safe takeaway: free tier + Pro licence + Gumroad +
bundling several small Mac apps together.

### 8. REBASE Book — a modest, honest Show HN `[VERIFIED via IH post]`
2020-03-03. **#3 on the front page with only 38 points and 9 comments.** No revenue disclosed.
> Useful calibration: **front page is cheaper than the folklore suggests.** 38 upvotes got #3 on
> that day. The "you need 400 supporters" math is Product Hunt's problem, not HN's.

### 9. Indie Kit `[SECONDARY, indiehackers.com]`
Launched Jan 2025 → 100+ signups in 3 months → **$6,000 revenue by May 2025**, marketed
**entirely via Reddit**, by participating in founder communities.

### 10. Warp `[SECONDARY, Sacra/Crunchbase]`
$73M raised total ($50M Series B led by Sequoia, June 2023). Growth described as
"developer word-of-mouth and viral adoption within engineering teams", bottom-up PLG. **Has still
not open-sourced the client as of 2026** despite stating intent. Counter-example: you do not need
to be open source to win a terminal-adjacent dev-tool market — but Warp had $73M and you have $0.

### 11. VS Code extension monetisation `[SECONDARY]`
"Lean, well-maintained extensions" reported at **$300–$2,100/month** recurring. Marketplace has no
paid tier; the pattern is free extension → licence key → off-platform payment.

### 12. Alyssa X `[SECONDARY]` — self-taught macOS app, **$5,000 in the first week**, ~$6,600 by
March 21. Source is a Medium/Women Make post; numbers not independently verified.

### 13. Proxyman / TablePlus — the "no numbers published" cohort
Proxyman: free basic / **$49 one-time Pro**, site claims 800k+ developers. TablePlus:
**$99–$129 perpetual licence**, unfunded, operating since 2017 (Tracxn). Neither publishes funnel
data. Their value as evidence is the *pricing model*: **native macOS dev tools sustain companies on
one-time perpetual licences.** That is the strongest available support for Chute's $19 decision.

### Cross-cutting pattern across all 13

| Claim | Support |
|---|---|
| One-time / perpetual pricing works for macOS dev tools | Lunar $23, Proxyman $49, TablePlus $99–129, DevUtils, Xnapper |
| HN front page is achievable with modest upvotes | REBASE #3 with 38 points |
| HN front page does not imply sales | Aidlab: 6,000 views, 0 sales |
| Paid ads do not work at this niche/price | Panaitiu: "thousands of dollars down the drain", zero sales |
| Reddit works if you participate, not promote | Indie Kit ($6K), Panaitiu (/r/macapps) |
| PH rank does not predict revenue | Dinh #1 → $14K; Blatak #1 → 1 customer |
| Audience precedes launch, launch does not create audience | Dinh's own quote |
| Sell direct, not through the App Store | Panaitiu: 5% Paddle vs 15% Apple, 36% total leakage |

---

## 6. ETHICAL GROWTH TACTICS THAT WORKED

### 6a. awesome-list PRs — best ROI per hour in this entire document

`[VERIFIED]` `punkpeye/awesome-mcp-servers` sits at **93,127 stars** (Builder Radar, week of
2026-08-30). `awesome-claude-skills` ~13k stars `[SECONDARY]`. These lists rank on page 1 for
"best X tools github" queries.

`[SECONDARY]` Reported effect of placement in a *relevant* awesome list: **50–200 stars/month on
autopilot**, and acceptance rates are much higher on smaller niche lists than on the flagship ones —
so start small and work up. (dev.to / repoclip.io growth posts; treat the exact numbers as
directional, the mechanism as real.)

Targets for Chute, in submission order (smallest/most relevant first):
1. macOS-specific awesome lists (`awesome-macos`, `awesome-macos-command-line`, `awesome-mac`)
2. Claude Code / agent-skills lists (`awesome-claude-skills`, `awesome-claude-code`)
3. `punkpeye/awesome-mcp-servers` — **only if you ship a genuine MCP server**
4. CLI-tool lists (`awesome-cli-apps`, `awesome-shell`)

**Ethics line:** submit only where the tool genuinely belongs, one PR per list, follow the list's
contributing guide exactly, and never open a PR that adds your entry plus reorders others.

### 6b. The GitHub README is the highest-traffic page you own

`[SECONDARY, consistent across multiple sources]`: developers decide whether to star within ~15
seconds; the README must sell in under 7. Elements that recur in every source:
- One sentence, above the fold, saying what it does
- **A GIF/demo video showing it working** — the single most cited element
- Copy-paste quick start that works first try (`brew install avaluev/tap/chute` — you already have this)
- Badges: build, version, licence, downloads

**For Chute specifically:** the README must contain, visibly and honestly, the sentence that names
the paid GUI and the $19 price, plus the `/plugin marketplace add` and `npx skills add` one-liners.
Right now that seam is where the money leaks.

### 6c. Homebrew tap — you can measure this `[VERIFIED, docs.brew.sh/Analytics]`

Homebrew's anonymous analytics include **"the package and non-private GitHub tap names"** — i.e.
installs from your public tap `avaluev/tap` ARE recorded, and public aggregates are published at
https://formulae.brew.sh/analytics/ (30d / 90d / 365d install and install-on-request events).

> **Actionable: `install-on-request` is your real signal.** It counts people who typed
> `brew install chute` deliberately, as opposed to pulling it in as a dependency. That is your free
> top-of-funnel number, and it is the denominator for any conversion claim you make later.
> Check it at https://formulae.brew.sh/analytics/install-on-request/30d/ after launch.

`[UNVERIFIED]` The docs do not explicitly confirm a per-tap-owner dashboard; you may need to grep
the published aggregate JSON for your formula name. Verify this yourself post-launch.

### 6d. SEO comparison / "alternative to X" pages

I could **not** find a credible, primary case study quantifying "alternative to" page performance
for a dev tool. `[UNVERIFIED]` The tactic is universally recommended and universally unquantified in
what I could reach. What IS verifiable is the *mechanism*: search "X alternatives" for any dev tool
and page 1 is comparison pages and awesome lists, not vendor homepages.

Do it anyway — it costs one afternoon and compounds — but do not model revenue from it.
Write honest pages (name where the competitor is better; the dishonest ones don't rank long and
get called out on HN). Target the specific queries Chute's ICP actually types.

### 6e. Changelog and docs as marketing `[SECONDARY]`

- Every changelog entry is a fresh indexable page. **Stripe** runs two layers: a programmatically
  generated API changelog tied to named versions, plus a curated narrative blog changelog.
  **Linear** uses its changelog as a growth and culture artifact.
- Separate *activation docs* (get the existing user working) from *discovery tutorials* (rank in
  search, bring new users in). Most solo founders write only the first kind.
- Note the HN constraint from §3: a changelog post is fine on your blog and terrible as a Show HN
  ("Foo 1.3.1 is out" is explicitly not substantive).

### 6f. Reddit — the 90/10 rule, and where it applies

`[SECONDARY]` The long-standing convention is **9 genuine contributions for every 1 promotion.**
One documented example: a direct link post got 2 upvotes and 0 signups; a genuinely helpful comment
earned 50+ upvotes and 5–10 product visits. Reddit is a *feedback and reputation* channel with a
weak direct-install funnel — judge it on signup quality, not download spikes.
`r/macapps` is specifically named as working by Panaitiu. AI subreddits (r/ClaudeAI, r/cursor)
restrict direct promotion — value-first only.

### 6g. Free tier design

The rule every source converges on: **the free tier must be complete for a job, and the paid tier
must be a different job — not a quota on the same job.** Chute already satisfies this (CLI =
scriptable/agent-invocable; GUI = Finder right-click + menu bar). Protect it:
- Never put a nag, a limit, or telemetry-with-a-prompt into the MIT CLI. HN will find it.
- Never relicense or move a shipped CLI feature behind the paywall. That is the documented
  rug-pull pattern that ends open-core goodwill permanently.

---

## 7. THE RECOMMENDED SEQUENCE FOR CHUTE

Effort-ordered, highest expected value first. Nothing here costs money.

**Before launch day**
1. README rewrite as a landing page: one-sentence description, demo GIF, `brew install` quick start,
   badges, and **one honest paragraph naming the $19 GUI.** (§6b)
2. Ship the **agent skill** and publish it — `npx skills add avaluev/chute`. This is the one artifact
   that reaches Claude Code *and* Cursor *and* 15 other agents from a single repo. (§5b)
3. Ship the **Claude Code plugin marketplace** — `.claude-plugin/marketplace.json`, run
   `claude plugin validate .`, so your CTA is `/plugin marketplace add avaluev/chute`. (§5c)
4. Write the Show HN title and first comment now, cold, and sit on them for a day.
   Title names the mechanism, not the product benefit. (§3, Aidlab lesson)

**Launch day**
5. **Show HN the free CLI**, not the paid GUI. First comment discloses the $19 GUI, what stays MIT,
   and why one-time. Be online all day to answer. (§3)
6. Product Hunt the same week — self-hunted, ~1 hour, for the DA-91 backlink and the permanent page.
   Do not build a campaign. Do not expect revenue. (§4)

**Week 1–4 (this is where the actual work is)**
7. awesome-list PRs, smallest and most relevant first. (§6a)
8. Submit to the community plugin/skill aggregators: claudepluginhub.com, claudemarketplaces.com,
   cursor.directory. (§5c, §5e)
9. `r/macapps` — participate for two weeks before you post about Chute. (§6f)
10. Write the *technical* blog post about the hardest thing you solved. Panaitiu's M1 post did 30k
    views. That post, not the launch post, is what brings people back. (§1 case 2)

**Explicitly do not**
- Buy ads. Zero sales, thousands wasted, per the closest comparable. (§1 case 2)
- Chase Product Hunt #1. You cannot produce 400 supporters in 4 hours and rank doesn't predict
  revenue anyway. (§4)
- Build an MCP server for distribution reasons. Directory installs are in the hundreds. (§5d)
- Model revenue on Tony Dinh's launches. Those are outputs of a 180K-follower audience. (§1 case 3)

## 8. Open questions I could not resolve

- No first-party free-CLI→paid-GUI conversion rate exists in public for any comparable product.
  The 1–3% open-source benchmark is the best available proxy and it is not from this niche.
- No reliable 2025–2026 dataset on optimal HN posting time. Folklore only.
- claudepluginhub.com returned HTTP 403 to fetch; its plugin/install counts are search-snippet only.
- skills.sh's own "1,348,411 skills" and third-party trackers' "60,788 skills / 125M installs"
  cannot both be right. Do not cite either.
- The MacWhisper revenue figures found are mutually contradictory. Do not cite.
