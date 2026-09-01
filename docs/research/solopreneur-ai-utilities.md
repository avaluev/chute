# Paid solopreneur utilities sold to AI builders — field scan

Researched 2026-09-01 by web research agent. Companion to
`/Users/sxope/Documents/2026/Development/37.chute/docs/research/competitors.md` and
`/Users/sxope/Documents/2026/Development/37.chute/docs/research/gtm-tactics.md`.
This file deliberately does NOT re-cover: repomix, Repo Prompt, PasteMax, 16x Prompt,
Downie, Lunar, MagicMenu, Product Hunt / Show HN mechanics, agent-skills / `npx skills add`.

**Tagging key**
- `[VERIFIED]` — I fetched a primary source (the vendor's own page, the founder's own post, a platform page) and read the figure there.
- `[SECONDARY]` — an aggregator, third-party blog, or search snippet reported it.
- `[UNVERIFIED]` — could not trace to a source. Do not put in a deck.

STATUS: in progress — sections appended as research lands.

---

## 1. The catalogue — paid 1–2 person products sold to AI builders (2024–2026)

Sorted roughly by closeness to Chute's shape. Every price below was read on the
vendor's own page or a Product Hunt product page on 2026-09-01 unless marked otherwise.

### 1.1 macOS menu-bar / Finder utilities for Claude Code & Cursor users

| # | Product | Founder | One line | Price + model | Channel | Public numbers | URL |
|---|---|---|---|---|---|---|---|
| 1 | **SessionWatcher** | not named on site `[UNVERIFIED]` | Claude/Codex/Cursor usage limits, 5-hour window, tokens and cost live in the macOS menu bar | **$6.99 one-time** (Claude solo) / **$14.99 one-time** bundle / **Pro $24 per year or $59 one-time** `[VERIFIED]` | Direct site, SEO comparison pages, guides | 6 named testimonials with GitHub avatars on-site; no revenue published `[VERIFIED that none is published]` | https://sessionwatcher.com/claude |
| 2 | **Conan** | **Randy Daniel** | "A native Mac cockpit for Claude Code" — live HUD of prompts, tool calls, skills, context gauge, cost | **Free app + $29 one-time premium, lifetime 1.x updates, no subscription** `[VERIFIED via PH]` | Product Hunt (**129 upvotes, #7 of day**), direct | 129 PH upvotes; no revenue published | https://conan.sh · https://www.producthunt.com/products/conan |
| 3 | **Pathly** | **Zura Guerra / Sophinauta** | Finder right-click → copy any file/folder path in 5 formats (incl. git-relative), explicitly "for sharing paths with Claude & Codex" | **$4.99 one-time, Mac App Store** `[VERIFIED]` | Mac App Store + SEO blog ("How to copy a file path on Mac in 2026") | none published | https://pathly.sophinauta.com/ |
| 4 | **AgentQuartz** | **Marco Calderon** (@mcalderon_codes) | Claude & Cursor usage gauges in the macOS menu bar, local-first, no account | **Free + Pro $3 one-time lifetime via Gumroad** `[VERIFIED via PH]` | Product Hunt (**94 upvotes**), Gumroad | none published | https://agentquartz.vercel.app · https://www.producthunt.com/products/agentquartz |
| 5 | **PromptPaste** | **Ivan Terehin** | Private AI prompt library on Mac/iPhone/iPad, ⌘⇧P from the menu bar to copy a prompt | **7-day trial → $59.99/yr or $149.99 lifetime** `[VERIFIED via PH]` | Product Hunt (**119 upvotes, #9 of day**) | none published | https://getpromptpaste.com · https://www.producthunt.com/products/promptpaste |

**Note on the free flood in this exact niche.** The Claude-Code menu-bar slot is
crowded with free/OSS builds: `tddworks/ClaudeBar`, `gmr/claude-status`,
`m1ckc3s/claude-status-bar`, TokenBar (MIT), ClaudeUsageBar, Claude God,
ClaudeMeter, `AThevon/TokenEater`, `cordwainersmith/Claudoscope`, ClaUse Bar
(free on MAS, `[VERIFIED]` via iTunes lookup 2026-09-01), Minto – Vibe Coding
Tracker (free on MAS, `[VERIFIED]`). **Yet SessionWatcher charges $6.99 and Conan
charges $29 in the same slot and both are alive.** That is the single most
directly encouraging fact in this file: a dozen free clones did not stop two paid
products from existing there. `[VERIFIED — free apps and paid apps both listed and live 2026-09-01]`

### 1.2 Native Mac apps for AI workflows, sold one-time by 1–2 people

| # | Product | Founder | One line | Price + model | Channel | Public numbers | URL |
|---|---|---|---|---|---|---|---|
| 6 | **VoiceInk** | **"Pax" / JoshiPax** (solo) | On-device dictation for Mac; GPL-v3 open source AND paid | **One-time, tiered by Macs: Solo $25 (1 Mac), Personal $39 (2), Extended $49 (3)** — all shown with a struck-through anchor ($49/$49/$69). "One-time purchase, lifetime access", **14-day money-back, no questions asked**, free trial download `[VERIFIED on tryvoiceink.com]` | GitHub (GPL) + direct site + comparison SEO | **"5,696+ users"** stated on its own homepage `[VERIFIED that the claim is made; the number itself is self-reported]` | https://tryvoiceink.com |
| 7 | **MacWhisper** (Jordi Bruin / Good Snooze) | solo | Whisper transcription for Mac | **Gumroad: Pro €59 one-time lifetime**; **Mac App Store edition separately: $6.99/mo, $29.99/yr, $99.99 lifetime**; cloud "Assistant" +$9.99/mo `[SECONDARY — getvoibe.com and lumevoice.com, 2026]` | Gumroad + MAS | revenue figures found are mutually contradictory — see `gtm-tactics.md` §1.7, do not cite | https://goodsnooze.gumroad.com/l/macwhisper |
| 8 | **superwhisper** | small team | Dictation for Mac | **$8.49/mo Pro (annual) or $249 lifetime** `[SECONDARY — spokenly.app review, 2026]` | Direct | none published | https://superwhisper.com |

### 1.3 Non-macOS: extensions, CLIs, small SaaS aimed at AI builders

| # | Product | Founder | One line | Price + model | Channel | Public numbers | URL |
|---|---|---|---|---|---|---|---|
| 9 | **Unnamed AI coding assistant for VS Code** (listed for sale on Acquire.com) | **1 full-time person** | Model-agnostic BYO-key AI coding extension for VS Code | subscriptions + usage-based token marketplace | VS Code Marketplace, 100% organic | **$320k TTM revenue** (headline of the listing says $378k TTM), **~40% margin, 30,000+ MAU, 2.4M downloads, 8,700+ organic installs/week, $0 paid acquisition, 865,000-address developer email list** `[SECONDARY — a seller-written Acquire.com listing; seller-reported, unaudited, but it is a public, dated, named number]` | https://app.acquire.com/startup/pzayb81ude-ai-coding-assistant-for-vs-code-378k-ttm-revenue-140-yoy-2-2m-downloads-organic-0-cac |
| 10 | **AI Toolbox** (Chrome extension) | indie `[UNVERIFIED headcount]` | Folders, search, bulk export, prompt library and prompt chaining bolted onto ChatGPT | **Free forever + $9.99/mo or $99 one-time lifetime** `[SECONDARY]` | Chrome Web Store | **40,000+ active users, 4.6/5** on the Web Store `[SECONDARY]` | Chrome Web Store |
| 11 | **PromptHub** | **two-person, unfunded, bootstrapped** `[SECONDARY]` | Prompt management / versioning / evals for teams building with LLMs | Free (2,000 req/mo) · **Pro $9/mo annual** · Team $15/user/mo · Enterprise custom `[VERIFIED on prompthub.us/pricing per search result]` | Direct + SEO | none published | https://www.prompthub.us/pricing |

### 1.4 Adjacent — free/OSS or funded, listed only to map the field (NOT comparables)

- **Conductor** (conductor.build) — parallel Claude Code/Codex/Cursor agents on Mac. **Free today**; a Pro $50/mo + Teams $60/user tier was announced but "the planned paid collaboration features have not shipped" `[SECONDARY — rywalker.com / codepick.dev]`. A second data point that the *subscription* model keeps failing to launch in this niche.
- **Crystal → Nimbalyst** — Crystal (Stravu) deprecated Feb 2026, redirected to **Nimbalyst**: free for individuals, **Teams $20/user/mo** `[SECONDARY]`.
- **CodeAgentSwarm**, **Canopy** (`juliensimon/canopy`), **Paseo** (MIT), **Superset** (superset.sh, open source), **Vibe Kanban** (no public commit since 2026-04-24 `[SECONDARY]`) — parallel-agent orchestrators, all free/OSS.
- **Promptfoo** — free OSS, **acquired by OpenAI in March 2026** `[SECONDARY]`. Second founder-exit event in this space after Repo Prompt→OpenAI. Pattern worth naming: **the best AI-dev-tooling solos are being hired, not out-competed.**
- **Shadow** (shadow.do, Taper Labs Inc.) — "the interface AI needs. One that sees, hears, and runs." Screen-aware, voice-triggered, writes results back into the active app. Company, not a solo. Its whole pitch is *removing the copy-paste step* — the same enemy Chute names. No public price found `[VERIFIED absent from the page fetched]`.
- **SupaSidebar** — Mac sidebar unifying tabs across 33 browsers with an MCP server for agents; free tier `[SECONDARY]`.
- **macos-use** (macos-use.dev) — drive any Mac app from Claude Code without AppleScript.

### 1.5 More paid one/two-person products for AI builders

| # | Product | Founder | One line | Price + model | Channel | Public numbers | URL |
|---|---|---|---|---|---|---|---|
| 12 | **BoltAI** | solo (Dan, indie) `[UNVERIFIED name]` | Native Mac AI workspace, 300+ models, BYO key, MCP | **Perpetual, tiered by devices: Essential $79 (1 device), Pro $99 (2 desktop + 1 mobile), Pro+ $199 (3+2), Team $99/seat (5 min)**. 1 year of updates included; optional renewal at **40% off**; **30-day money-back, "no questions asked"**; free trial, **no account required** `[VERIFIED on boltai.com/pricing]` | Direct site, SEO, lifetime-deal sites | logo wall claims Apple/Deloitte/Zapier/Cloudflare/MIT usage; no revenue published | https://boltai.com/pricing |
| 13 | **ChatWise** | **EGOIST** (github.com/egoist) — solo | "The fastest AI chatbot" for Mac; MCP tools, artifacts, BYO key, works with Claude Pro/Max and Copilot subs | **Free tier + Pro $29 one-time, anchored "was $49"**, "Pay once and use it forever", **7-day free trial** `[VERIFIED on chatwise.app/pricing]` | Direct + GitHub releases | none published | https://chatwise.app/pricing |
| 14 | **Agent Bar** | **Aayush** (@aayushbuilds1) | "Run Claude Code from your menu bar" — native SwiftUI, voice dictation, tool-call streaming, approvals, token cost | paid on Gumroad; listed price **$5.04** at fetch time `[VERIFIED via Gumroad page JSON-LD, 2026-09-01]` | **Product Hunt: 162 upvotes, #6 of day** `[VERIFIED]`; Gumroad | 162 PH upvotes | https://aayushbuilds.gumroad.com/l/agentbar |
| 15 | **PowerClick** | **Ata Kilic** | Finder right-click menu + radial menu: new file, batch rename, window snap, copy path, clipboard history | **$5.99 one-time, Mac App Store** `[VERIFIED]` | Mac App Store | claims **"#3 Utility App in Mac App Store"** `[VERIFIED that the claim is made]` | https://powerclick.kilicov.dev/ |
| 16 | **Prompt Library** | indie solo | Menu-bar prompt store, ⌘⌥P recall, local-only, model-agnostic | **$8 one-time** `[SECONDARY]` | Product Hunt (Feb 2026) | none | https://www.producthunt.com/products/prompt-library |
| 17 | **PromptMan** | **Healcy.App UG** (Germany, HRB 208164) | ⌘⇧O menu-bar prompt library with "AI Enhance" | Free (10 prompts) · **Pro $4.99/mo · $39/yr** `[VERIFIED on promptman.app]` | Mac App Store | none | https://promptman.app/ |
| 18 | **Superpower ChatGPT** | **Saeed Ezzati** (solo) | Chrome extension adding folders, search, exports, prompt tooling to ChatGPT | Free for the first 9 months, then **freemium: free core + Pro** `[VERIFIED via his IH post]` | Chrome Web Store organic search, Reddit, Product Hunt, own newsletter | **"over 420,000 downloads", "more than 150,000 weekly active users", newsletter "over 350,000 subscribers", "5-figure MRR" (>$10K/mo)** — founder's own Indie Hackers post, **2026-07-08** `[VERIFIED — primary, founder-authored]` | https://www.indiehackers.com/post/tech/building-a-free-chrome-extension-in-3-days-and-turning-it-into-a-5-figure-mrr-ecosystem-3rIbjigZxiFsrgqJjJYp |
| 19 | **Easy Folders** | **Edmund Yong** (solo) | Chrome extension: folders, chat search, prompt manager for ChatGPT **and Claude** | freemium `[UNVERIFIED price points]` | Chrome Web Store only | **"$42,000+" total revenue, "$3,700+" MRR at 6 months post-launch** — founder's own IH milestone, **2024-08-09** `[VERIFIED — primary, founder-authored]` | https://www.indiehackers.com/product/easy-folders |
| 20 | **ChatGPT Toolbox** | **Adi and Modi** (two people) | Browser extension solving ChatGPT organisation problems | paid `[UNVERIFIED price]` | Chrome Web Store **featured badge** | **$6K in 30 days** `[SECONDARY — indieniche.substack.com]` | Chrome Web Store |
| 21 | **Claude Code Notifier for Mac** | touchtap | Menu-bar app that pings you the moment Claude Code needs attention | **$0 on Gumroad** at fetch time `[VERIFIED via Gumroad JSON-LD]` | Gumroad | none | https://touchtap.gumroad.com/l/claude-code-notifier |
| 22 | **PromptLatch** / **PromptBar** | Zalo Design Studio / indie | Menu-bar prompt libraries for Mac | `[UNVERIFIED — promptbar.app served no readable content to the fetcher]` | direct | none | https://promptbar.app/ · https://zalodesignstudio.com/promptlatch/ |

**Count: 22 paid products, 1–2 person, buyer = someone building with AI.** Only **four**
publish a real number: Superpower ChatGPT (>$10K MRR, 150K WAU), Easy Folders
($42K total / $3.7K MRR), the anonymous VS Code extension on Acquire ($320–378K TTM,
1 FTE), and ChatGPT Toolbox ($6K in 30 days, secondary).

> **The finding hiding in that sentence: three of those four are browser extensions,
> not native Mac apps.** Nobody selling a small paid native macOS utility to AI
> builders publishes revenue. Not one. Chute should expect to be flying blind on
> comparables and should therefore not build a plan that depends on a number nobody
> in its own category has ever disclosed.

---

## 2. Ranked by similarity to Chute — top 8

Similarity scored on: (a) native macOS, (b) one gesture / one job, (c) sold one-time
at a low price, (d) buyer is a Claude Code / Cursor user, (e) removes *friction*
rather than adding *capability*.

### #1 — Pathly ($4.99 one-time, Mac App Store) — the closest thing that exists
`https://pathly.sophinauta.com/` · Zura Guerra / Sophinauta, founded 2024, "builds focused Mac utilities for developers and power users."

Same surface (Finder right-click), same buyer (its own copy says the point is
"sharing paths with Claude & Codex"), same model (one-time, tiny price), same
size (one gesture). It is Chute minus the file *contents*.

- **COPY:** the friction arithmetic. Its structured data says, verbatim: *"The native
  macOS method requires 4 steps (hold Option, right-click, locate menu item, click).
  Pathly requires 2 (right-click, choose format)."* **That sentence is the entire
  argument for a paid Finder extension and Chute needs its own version of it**
  (Chute's is roughly: 40 files by hand = 40 open/select-all/copy/paste cycles, or
  one terminal `cd` + a flag set you have to remember; Chute = 2).
- **COPY:** the comparison table against **macOS itself**, not against a competitor.
  Pathly's only comparison page is "Pathly vs native macOS." Chute's should be
  "Chute vs a Shortcuts Quick Action" and "Chute vs opening a terminal".
- **COPY:** naming the AI tools in the copy. "for Claude & Codex" is doing the
  qualifying work in one phrase.
- **COPY:** SEO built on the *problem*, not the product — its blog ranks for
  "how to copy a file path on Mac in 2026", a query people already type.
- **AVOID:** $4.99 on the Mac App Store. Apple takes 15%, sandboxing fights a tool
  that must read arbitrary user files, and $4.99 anchors the whole Finder-extension
  category as sub-coffee. Chute at $19 direct is the right side of that line.
- **AVOID:** zero testimonials and no changelog. It reads like a weekend project even
  though it is not.

### #2 — SessionWatcher ($6.99 / $14.99 / $59 one-time) — the best-converting page in the set
`https://sessionwatcher.com/claude`

Native menu-bar utility, Claude Code buyer, one-time, sold direct with a full
marketing site. It is the only product in this scan that behaves like a business.

- **COPY:** the hero pattern — *"Claude limits, in your menu bar"* (five words, names
  the surface), subhead lists the five concrete things it shows, CTA is
  *"Get SessionWatcher for Claude"* with the reassurance line directly beneath:
  **"One-time purchase, instant download, 14-day refund window."** Three objections
  killed in nine words. Chute should ship that exact triplet.
- **COPY:** the guides directory (`/guides/best-claude-code-usage-trackers`) that
  **honestly lists its free competitors including ccusage and Anthropic's own
  `/usage`**, then explains who should still pay. This is the single highest-leverage
  page they own: it ranks for the query their buyer types, and the honesty is what
  makes the paid case credible. Chute's equivalent is "Best ways to get a codebase
  into Claude Code (2026)" listing repomix, gitingest, files-to-prompt, and Chute.
- **COPY:** testimonials sourced from **GitHub profiles with avatars** — the right
  credibility currency for this buyer.
- **AVOID:** the three-tier ladder ($6.99 / $14.99 / $59 Pro + a $24/yr option). It
  needs a comparison table to explain itself. Chute's whole advantage at one price
  is that there is nothing to decide.
- **AVOID:** the mixed one-time-and-subscription Pro tier. It muddies "one-time" as
  a promise.

### #3 — Conan ($29 one-time, free download) — the closest *price* comparable
`https://conan.sh` · Randy Daniel · PH 129 upvotes, #7 of day

Native macOS, Claude Code, one-time $29, solo, launched 2026, free-to-download with
a paid unlock. This is the shape Chute is aiming at, one notch up in price and scope.

- **COPY:** the price sentence, verbatim in structure: **"Free to download · Premium
  $29, once"** and **"$29 once, no subscription"**. No pricing table at all — the
  price is a clause inside a sentence. At one price point, that is correct.
- **COPY:** **five numbered screenshots (01–05), one per feature.** This is the most
  repeated pattern in the whole set and Conan does it most cleanly.
- **COPY:** scoping the promise — *"lifetime access to 1.x"*. It gives "lifetime"
  without promising eternity. Chute should copy this word for word.
- **COPY:** the secondary CTA **"Windows or Linux? Get notified →"** — turns the
  single biggest bounce reason into an email address.
- **AVOID:** no docs, no testimonials, no refund policy, no licence terms anywhere on
  the page. For a $29 purchase from an unknown solo dev that is a real conversion
  leak; SessionWatcher's "14-day refund window" line costs one sentence.
- **AVOID:** the hero headline **"Command the campaign, by your own hand"**. It is a
  Conan-the-Barbarian pun. The subhead does 100% of the explaining. Chute's headline
  must say the job.

### #4 — VoiceInk ($25 / $39 / $49 one-time, GPL-v3 open source) — the open-core twin
`https://tryvoiceink.com` · "Pax" / JoshiPax, solo

Not a coding tool, but structurally it is Chute: **a fully open-source codebase and a
paid build, sold one-time, to technical Mac users who could compile it themselves.**
This is the best available evidence that Chute's free-MIT-CLI + paid-GUI split can
carry a price.

- **COPY:** **licence tiers by number of Macs, not by features** — $25 (1 Mac) /
  $39 (2) / $49 (3). Every tier gets the whole product. Nobody feels cheated, and the
  middle tier does the anchoring work. This is the single best pricing idea in the file.
- **COPY:** **"One-time purchase, lifetime access"** + **"14-day money-back guarantee,
  no questions asked"** side by side under the buy button.
- **COPY:** the self-reported user counter — **"5,696+ users"** with avatars. A precise
  odd number reads as a real query against a real database; "thousands of users" does not.
- **COPY:** a "Wall of Love" page, and a changelog that just points at GitHub Releases.
- **AVOID:** the permanent struck-through discount ($49 → $25 that never ends). It
  works, and it also trains buyers to distrust the number. If Chute wants an anchor,
  use a real, dated launch window.
- **AVOID:** GPL. Chute's CLI is MIT, which is right: GPL on the CLI would poison the
  possibility of shared code with the paid GUI.

### #5 — ChatWise (Pro $29 one-time, was $49) — the solo-dev-with-a-GitHub-face model
`https://chatwise.app` · EGOIST, solo

- **COPY:** **"Pay once and use it forever."** Five words, no asterisk.
- **COPY:** a real `/docs` subdomain and a `/changelog` with "View All". A changelog is
  the cheapest possible proof that a one-time purchase will keep being maintained —
  which is the #1 unspoken objection to buying from a solo dev.
- **COPY:** the **7-day free trial** on a $29 one-time product. Cheaper to run than a
  free tier and it converts better (see §4).
- **AVOID:** the hero headline stuffed with model names for SEO
  (*"The fastest AI chatbot for ChatGPT, DeepSeek, Claude, Gemini and Llama"*). It reads
  as a keyword list. Chute's ICP is one audience, not five.
- **AVOID:** a free tier restricted to "personal, non-commercial use". Unenforceable,
  and it invites an argument. Chute's free half is MIT with no strings — keep it.

### #6 — BoltAI ($79 / $99 / $199 perpetual + optional 40%-off renewal)
`https://boltai.com`

Bigger and pricier than Chute, but it is the most complete example of the
**perpetual-licence + optional update renewal** shape that `competitors.md` §4
identified as the dominant 2025–26 indie-Mac model.

- **COPY:** **"Free trial · No account required"** directly under the download button.
  "No account required" is a conversion feature for this buyer, not a footnote.
- **COPY:** the **30-day money-back, "no questions asked"** wording — a longer, plainer
  promise than the 14-day norm, at a price where refunds actually matter.
- **COPY:** an 11-question FAQ that leads with **licensing** — devices, renewal, what
  happens when you stop paying. Answering "what do I actually own" is what makes a
  perpetual licence purchasable.
- **AVOID:** the "1 year of updates, then renew at 60%" structure. Correct at $99,
  wrong at $19 — the renewal machinery would cost more to build and support than it
  would collect.
- **AVOID:** the Apple/Deloitte/Cloudflare/MIT logo wall. Unverifiable, and this
  audience discounts it.

### #7 — PromptPaste (7-day trial → $59.99/yr or $149.99 lifetime)
`https://getpromptpaste.com` · Ivan Terehin · PH 119 upvotes, #9 of day

Menu-bar, one-gesture (⌘⇧P), AI workflow, Apple-native. Included mainly as a
cautionary comparable.

- **COPY:** the hero headline **"Your private AI prompt library"** — four words, a noun
  phrase, no verb, no adjectives. This is the correct headline register.
- **COPY:** "no account required", "no telemetry", local-first + iCloud. Privacy as a
  feature is nearly free to build and is load-bearing for a tool that touches files.
- **AVOID — hard: the price.** $59.99/yr or $149.99 lifetime for a prompt clipboard,
  when Prompt Library sells the same job at **$8 one-time** and PromptMan at
  **$4.99/mo**, is a 7–18x spread inside one tiny category. There is no visible
  differentiator carrying it. Chute's $19 is defensible; do not talk yourself upward.
- **AVOID:** a landing page with **no pricing table, no FAQ, no testimonials, no
  refund statement** asking for $149.99. That is the widest ask-to-evidence gap in
  this scan.

### #8 — PowerClick ($5.99 one-time, Mac App Store) · Ata Kilic
`https://powerclick.kilicov.dev/`

The other paid Finder-right-click product, and the direct precedent for "someone will
bundle your gesture into a grab-bag."

- **COPY:** the headline **"Finder's missing right-click. Plus a ring for the rest."**
  It names a *gap in macOS* rather than a product category. Chute's version:
  Finder can copy files; it cannot hand them to a model.
- **COPY:** the App Store rank as social proof ("#3 Utility App in Mac App Store") —
  a third-party number the founder didn't have to invent.
- **AVOID:** the grab-bag itself. New file + batch rename + window snapping + clipboard
  history + radial menu at $5.99 is a race to the bottom on breadth. Chute's whole
  defensibility is that it is *one* thing for *one* audience — and it can therefore
  charge 3x PowerClick for less surface.
- **AVOID:** MAS-only distribution, for the sandboxing and 15% reasons above.

### Also-rans, and why they missed the top 8
- **AgentQuartz** (free + $3 Pro) — right shape, but its page is client-rendered and
  returned no readable content to a fetcher `[VERIFIED — fetch returned only the title]`.
  A landing page that renders nothing without JS is invisible to every LLM, every
  scraper, and every preview card. **That is a mistake Chute must not copy.**
- **Agent Bar** ($5.04, Gumroad) — good PH result (162 upvotes, #6), but a bare Gumroad
  page is the whole storefront.
- **16x Prompt**, **Repo Prompt**, **repomix**, **PasteMax** — covered in `competitors.md`.

---

## 3. Their websites — fetched, not remembered

All eight pages fetched 2026-09-01. Structure as it actually appears, in page order.

### 3.1 SessionWatcher — https://sessionwatcher.com/claude
1. **Hero** — H1: *"Claude limits, in your menu bar"*. Sub: *"Track your 5-hour session window, weekly cap, reset time, token usage, and costs live in your macOS menu bar."*
2. **CTA** — *"Get SessionWatcher for Claude"*, with the line *"One-time purchase, instant download, 14-day refund window."* underneath.
3. **Hero visual** — an **interactive** menu-bar mock inside a MacBook frame showing live Claude + Copilot percentages and reset timers. Not a video, not a GIF: a live DOM recreation of the UI.
4. **Screenshots** — 1 (the hero mock). Everything else is rendered UI, not image files.
5. **Pricing table** — yes, 3 columns: Claude Solo $6.99 / Bundle $14.99 / Pro $24-per-year-or-$59-once, compared on coverage, metrics tracked, and Macs (1 vs 5, iCloud-synced).
6. **Docs** — yes: setup guide + several how-to guides.
7. **Changelog** — yes (release notes).
8. **Comparison pages** — yes, several: vs competitors, and tool-vs-tool explainers (Claude Code vs Cursor).
9. **Testimonials** — 6, five stars, with GitHub profile photos.
10. **FAQ** — 9 questions: do I need it, setup, Claude Code compatibility, widgets, privacy, notifications, refunds.
11. **Refund** — "14-day money-back guarantee", repeated.  **Trial** — none.  **Licence** — 1 Mac (Solo/Bundle), 5 Macs (Pro).

### 3.2 Conan — https://conan.sh
1. **Hero** — H1: *"Command the campaign, by your own hand"*. Sub: *"Conan is a native macOS app that wraps Claude Code in a live HUD — every prompt, tool call, skill, and token, surfaced as it happens."*
2. **CTA** — primary *"↓ Download for Mac"*; secondary *"Windows or Linux? Get notified →"*.
3. **Hero visual** — one static screenshot of the timeline view.
4. **Screenshots** — **5, numbered 01–05**, one per feature (Timeline / Context / Pulse / Skills & MCP / Radio).
5. **Pricing** — no table. Inline sentences: *"$29 once, no subscription"* and *"Free to download · Premium $29, once"*.
6. **Docs** — none.  **Changelog** — yes, `/changelog`.  **Comparison** — none.  **Testimonials** — none.
7. **FAQ** — yes, expandable, on-page.  **Refund/trial/licence** — **absent entirely**.
8. Extras: a Product Hunt badge widget, a "Claude Radio" feature demo, footer newsletter signup.

### 3.3 Pathly — https://pathly.sophinauta.com/
1. **Hero** — H1: *"Copy & Get Any File or Folder Path on Mac — Instantly"*. Sub names the developer's own motivation: built for sharing paths with Claude & Codex; five copy actions, no modifier keys.
2. **CTA** — *"Get Pathly — $4.99 One-Time"*, repeated down the page, with the Mac App Store badge.
3. **Hero visual** — a static screenshot of the **Finder right-click menu itself**, five options open.
4. **Screenshots** — 5 (terminal use, preferences, filesystem compatibility, workflows).
5. **Pricing table** — yes, but it is **Pathly vs native macOS across 8 rows**, not a tier ladder. Single price.
6. **Docs** — 3 blog guides.  **Changelog** — none.  **Testimonials** — none.  **Trial** — none.  **Refund** — not stated.
7. **FAQ** — 10 questions: install, git paths, external drives, privacy, languages.
8. Notable: heavy schema.org markup naming the founder, the org, the OS versions, and a `featureList`. Localised into 34 languages.

### 3.4 VoiceInk — https://tryvoiceink.com
1. **Hero** — H1: *"Write at the speed of thought"*. Sub: *"VoiceInk uses local AI models to instantly transcribe what you say to text with near-perfect accuracy and complete privacy."*
2. **CTA** — *"Buy Now"*; secondary *"Now available on iOS"*.
3. **Hero visual** — hero image, not a gallery.
4. **Social proof immediately below the fold** — *"5,696+ users"* + 5 avatars + audience labels (coders, writers, students, entrepreneurs).
5. **Features** — shown as **before/after text transformations**, not screenshots. Cheap to build, and it demonstrates output quality directly.
6. **Pricing table** — 3 one-time tiers **differing only by Mac count**: Solo $25 (was $49, 1 Mac) / Personal $39 (was $49, 2 Macs) / Extended $49 (was $69, 3 Macs).
7. **Guarantees** — *"One-time purchase, lifetime access"*, *"14-day money-back guarantee, no questions asked"*, "No subscription", free trial download.
8. **Docs** — yes (Getting Started, Modes, Recommended Models).  **Changelog** — on GitHub.  **Comparison** — yes, a "best dictation apps" blog.  **Testimonials** — a dedicated "Wall of Love" page.

### 3.5 ChatWise — https://chatwise.app
1. **Hero** — H1 is the SEO title: *"ChatWise — The fastest AI chatbot for ChatGPT, DeepSeek, Claude, Gemini and Llama"*. Sub: *"Simple, Powerful and Privacy-Friendly AI Chat"*.
2. **CTA** — *"Download 26.4.0"* — **the version number is in the button**, which quietly proves active maintenance.
3. **Hero visual** — one static screenshot (`preview-light.webp`), theme-aware.
4. Sections: 5 core-feature bullets → "Bring Your Own API Key" → "use your existing Copilot / Claude Pro-Max subscription" → Artifacts / Web Search / MCP.
5. **Pricing** — separate `/pricing` page: Free vs **Pro $29 one-time (struck-through $49)**, *"Pay once and use it forever"*, 7-day free trial.
6. **Docs** — yes, `docs.chatwise.app`.  **Changelog** — yes, `/changelog` with "View All".  **Testimonials / FAQ / comparison** — none.

### 3.6 BoltAI — https://boltai.com
1. **Hero** — H1: *"Private AI workspace for Mac power users"*. Sub: *"Switch between 300+ AI models from one native Mac app."*
2. **CTA** — *"Download Free Trial"* + *"View Pricing →"*, with the micro-line *"Free trial · No account required"* and *"No account required · Intel & Apple Silicon · macOS 13+"*.
3. **Hero visual** — an **interactive demo** labelled *"click around ✌️"* with a "Change demo" switcher. The most sophisticated hero in the set.
4. Provider logo row (8) → customer logo row (6: Apple, Deloitte, Zapier, Cloudflare, MIT) → dark-mode shot → iOS shot → 3 bento feature cards.
5. **Testimonials** — exactly **1**, named, with avatar and title.
6. **FAQ** — 11 questions, **licensing first**.
7. **Pricing** — separate page; *"Pay once. No subscription"*, "one-time purchase with one year of updates", 30-day no-questions refund, renewal at 40% off.
8. **Changelog** — yes, dated releases (v2.15.0, 2026-08-17). **Docs** — Help Center. **Comparison** — none.

### 3.7 PromptPaste — https://getpromptpaste.com
1. **Hero** — H1: *"Your private AI prompt library"*. Sub: *"Save, organize, and instantly paste your AI prompts. Dynamic inputs, folders, iCloud sync, and more…"*
2. **CTA** — *"Download PromptPaste for Mac"* (+ iPhone/iPad variants).
3. **Hero visual** — one multi-device mockup (iPad + Mac + iPhone in one image).
4. **Screenshots** — 1. **Pricing table** — none on the landing page. **Docs** — none. **Changelog** — none. **Comparison** — none. **Testimonials** — none. **FAQ** — none. **Refund/trial/licence** — none stated.
5. Price ($59.99/yr, $149.99 lifetime, 7-day trial) appears only on Product Hunt and in the App Store.

### 3.8 PowerClick — https://powerclick.kilicov.dev/
1. **Hero** — H1: *"Finder's missing right-click. Plus a ring for the rest."*
2. **CTA** — *"Download on the Mac App Store"*. **$5.99 one-time.**
3. **Hero visual** — app icon at 512px plus product screenshots.
4. **Social proof** — *"#3 Utility App in Mac App Store"*, five-star rating.
5. Feature counts used as copy: "15 built-in templates", "Batch Rename with 13 rules", 12 window-snap actions, 13 languages.
6. **Pricing table / trial / refund / licence terms** — none.

### 3.9 The patterns that repeat across 5+ of the 8

These are the convert-looking patterns. Treat this list as Chute's landing-page spec.

1. **The hero visual is a static screenshot of the app's actual UI — never a video, never an autoplay GIF.** 8/8. Two go further and rebuild the UI interactively in the DOM (SessionWatcher, BoltAI); that is the premium version of the same idea. **No product in this scan uses a video hero.**
2. **The headline is a noun phrase naming the surface, and the subhead does the explaining.** "Claude limits, in your menu bar" / "Your private AI prompt library" / "Private AI workspace for Mac power users" / "Finder's missing right-click". The one product that made its H1 a joke (Conan) has to spend its entire subhead recovering.
3. **The price and its reassurance are one line, under the button.** "One-time purchase, instant download, 14-day refund window." / "Free trial · No account required" / "$29 once, no subscription". 6/8.
4. **"Pay once" is stated as a sentence, not implied by a number.** The words *once*, *forever*, *lifetime*, *no subscription* appear on every one-time page in the set. Nobody trusts a price tag alone in 2026.
5. **Numbered feature screenshots, 5 of them.** Conan 01–05, Pathly 5, VoiceInk's transformations. Five is the observed mode.
6. **Local-first / no-account / no-telemetry is stated explicitly.** 6/8. For a tool that touches your filesystem this is not a nice-to-have — Chute must say it above the fold.
7. **A changelog is present on every product that charges over $19** (SessionWatcher, Conan, ChatWise, BoltAI, VoiceInk-via-GitHub) and absent on every product under $9 (Pathly, PowerClick, Prompt Library). The changelog is the tell that separates a product from a weekend project, and it is the answer to "will this still work next year?"
8. **The comparison page compares against the free/native alternative, not against a rival.** Pathly vs native macOS; SessionWatcher vs ccusage and Anthropic's own `/usage`. **Nobody in this niche writes a competitor-bashing page.** The honest "here is when you should NOT buy this" page is the category's convention — and given Chute's HN launch, it is also a defensive necessity.
9. **Testimonials, where present, come from GitHub/X profiles with avatars** — never from a "Marketing Director at Acme".
10. **Nobody publishes a real docs site under $19.** Guides and an FAQ are the substitute.

---

## 4. Pricing psychology for one-time dev utilities, 2026

### 4.0 The honest state of the evidence, first

**There is no published controlled experiment comparing $9 / $19 / $29 / $49 for a
one-time developer utility.** I looked hard. What exists is:
- opinion pieces that read like data and are not — e.g. the widely-shared "$9–$12
  sweet spot" post, which **states in its own body: "This is first-person opinion and
  framework, not quantitative research."** `[VERIFIED by fetching it]`
- one genuine first-party dataset, from 2020 (§4.2)
- the observed price distribution of the field itself, which is the strongest thing
  available and is reproduced below

Anyone quoting a conversion delta for $19-vs-$29 on a Mac utility is guessing.

### 4.1 The observed price distribution — the real evidence

Every one-time price found in this scan plus the neighbours from `competitors.md`,
sorted. `[VERIFIED]` unless noted.

| Price | Product | Channel |
|---|---|---|
| $3 | AgentQuartz Pro | Gumroad |
| $4.99 | **Pathly** (Finder right-click, for Claude/Codex) | Mac App Store |
| $5.04 | Agent Bar | Gumroad |
| $5.99 | **PowerClick** (Finder right-click) | Mac App Store |
| $6.99 | SessionWatcher (Claude solo) | Direct |
| $8 | Prompt Library `[SECONDARY]` | Mac App Store |
| $9.99 | iRightMouse Pro; Rectangle Pro | Mac App Store |
| $14.99 | SessionWatcher (3-tool bundle) | Direct |
| **— gap —** | **nothing between $15 and $19** | |
| $19.99 | Downie | Direct + Setapp |
| $20 | Bartender 6 | Direct |
| $25 | VoiceInk Solo (1 Mac) | Direct |
| $29 | **Conan**, **ChatWise Pro**, CleanShot X | Direct |
| $39 | VoiceInk Personal (2 Macs) | Direct |
| $48 | 16x Prompt | Direct |
| $49 | VoiceInk Extended (3 Macs) | Direct |
| $59 | SessionWatcher Pro (5 Macs) | Direct |
| $79 / $99 / $199 | BoltAI Essential / Pro / Pro+ | Direct |
| $99.99 | MacWhisper lifetime `[SECONDARY]` | Mac App Store |
| $149.99 | PromptPaste lifetime | Mac App Store |
| $249 | superwhisper lifetime `[SECONDARY]` | Direct |

**Two findings fall straight out of this table.**

1. **The distribution is bimodal, and the split is the distribution channel, not the
   feature set.** Everything on the Mac App Store clusters at **$3–$10**. Everything
   sold direct from the maker's own site clusters at **$25–$59**. Pathly and PowerClick
   are not cheap because a Finder extension is worth less; they are cheap because
   they are on a store whose buyers are trained to sub-$10 impulse and where 15% goes
   to Apple. **Chute's $19 direct price is below every direct-sold comparable in this
   field and roughly double every MAS-sold one.**
2. **$19 is in a genuinely empty band.** Nothing in this niche is priced $15–$19. That
   is either whitespace or a warning; the evidence does not distinguish. What it does
   say clearly is that **the two products closest to Chute in kind — Conan (native Mac,
   solo, Claude Code, one-time) and ChatWise (native Mac, solo, AI, one-time) — both
   landed on $29**, and neither has visibly suffered for it.

**Judgement, flagged as judgement, not evidence:** $19 is defensible and safe. $29 is
where the two nearest comparables actually sit. Raising a launched price is far harder
than launching high with a dated launch discount — VoiceInk and ChatWise both do
exactly that (see §4.5).

### 4.2 The one real first-party dataset — tyler.io, "One Year of App Pricing Experiments"
`https://tyler.io/one-year-of-app-pricing-experiments/` — indie Mac developer, own numbers, 2020. Old, but it is the only honest first-party set I found. `[VERIFIED by fetching]`

- **CommandQ** — *two-week free trial, then **$9.99 one-time***: **6% conversion**, 11% of his active customers.
- **Rebudget** — $2.99/mo, $14.99/yr, or **$39.99 one-time for life**: 2.1% direct-sale conversion; of buyers, **50% chose monthly, 30% annual, 20% lifetime**. Mac App Store version converted at 8% but on far fewer users.
- **Ears** — shareware, name-your-price: ~7% conversion, **average selling price $2.78, i.e. 40% above his stated minimum.**
- **Spotish** — pay-what-you-want on Gumroad, $1 minimum: **average purchase $8** — 8x the floor.

**Two transferable lessons.** (a) *A 2-week trial into a ~$10 one-time purchase
converted at 6%* — a usable planning number for a friction utility. (b) *When people
choose the number, they pay several times the minimum.* That is a data point against
pricing timidly, not for it.

### 4.3 Trial length
`[SECONDARY — aggregated benchmark sources; directionally consistent across several]`

- **Free trials are used by 57% of products vs 26% for freemium**, and trials convert **10–25% of trialists** vs **2–5% of freemium users**.
- Trial length distribution: **14 days = 62% of products**, 7 days = 14%, 30 days = 14%.
- **14 days converts better than 30** (urgency). **7 days is sufficient when a user can reach the core value in one session.**

**Applied to Chute:** the whole product is one right-click. A user reaches core value
in **under ten seconds**, not one session. The observed field agrees — ChatWise and
PromptPaste both use **7 days** for products far more complex than Chute. A 14-day
trial on a ten-second product is 13 days of forgetting you installed it.
**7-day trial, or the Conan model (free download, paid unlock).**

### 4.4 Refund policy wording — copy the exact phrasing, it is standardised

Observed verbatim, and there are only two live variants:
- **"14-day money-back guarantee, no questions asked"** — VoiceInk `[VERIFIED]`
- **"One-time purchase, instant download, 14-day refund window"** — SessionWatcher `[VERIFIED]`
- **"30-day Money Back Guarantee. If you're not happy with the product, we will refund. No questions asked."** — BoltAI `[VERIFIED]`

**14 days is the norm; 30 days appears at the $79+ end.** The load-bearing phrase in
all three is **"no questions asked"** — it converts because it removes the imagined
argument, not because of the window length. Conan, Pathly, PowerClick and PromptPaste
state **no refund policy at all**, and three of those four are the four weakest pages
in the scan.

**Also note, and this is a hard constraint:** on the **Mac App Store, Apple is merchant
of record and the developer contract does not permit you to offer your own money-back
guarantee** `[SECONDARY — Apple Developer Forums]`. Selling direct is what makes
"14-day, no questions asked" sayable at all. One more reason Chute sells direct.

### 4.5 "Lifetime" vs "one-time"

No conversion study exists comparing the two words `[VERIFIED that I could not find one]`.
What the field does is unambiguous, and every one-time product in the scan uses
**both, together, in a short sentence**:

- VoiceInk: **"One-time purchase, lifetime access"** + "No subscription"
- ChatWise: **"Pay once and use it forever"**
- Conan: **"$29 once, no subscription"** / "Free to download · Premium $29, once"
- BoltAI: **"Pay once. No subscription"** — then bounded: "one-time purchase with one year of updates"
- SessionWatcher: **"One-time purchase, instant download, 14-day refund window"**

The pattern is not one word beating the other. It is that **the price alone is never
trusted; the promise has to be spelled out in words next to it**, and it is always
paired with the negation *"no subscription."* In 2026 that negation is the actual
product feature — after a decade of subscription creep it is what the buyer is
scanning for.

**The one refinement worth stealing is Conan's:** *"lifetime access to 1.x"*. It gives
the reassurance without writing a cheque against a version you have not designed yet.
BoltAI's *"one year of updates, then optional renewal at 40% off"* is the same idea
with machinery attached — correct at $99, **overbuilt at $19**; the renewal system
would cost more to build and support than it collects.

### 4.6 Licence-per-machine norms

- **"Two or three active Macs per license is a practical default for indie macOS apps.
  It protects against casual sharing while respecting how people actually work."** — Keylight, 2026-05-18 `[SECONDARY but the closest thing to a stated norm I found]`
- Observed in the field: SessionWatcher **1 Mac** (Solo/Bundle) / **5 Macs** (Pro, iCloud-synced); VoiceInk **1 / 2 / 3** Macs; BoltAI **1 / 2 desktop + 1 mobile / 3 desktop + 2 mobile**; Rectangle Pro **3 Macs**; TablePlus **1 / 2 devices**.
- Keylight also notes trial builds are often limited to **one device** to reduce abuse.

**The best pricing idea in this whole document is VoiceInk's, and Chute can lift it
whole: tier by Mac count, not by features.** Every tier is the complete product; only
the activation count changes. It gives a $19 product a legitimate $29 tier without
crippling anything, without a feature matrix, and without a single "Pro" label — and
it maps onto a real behaviour (this buyer genuinely has a laptop and a desktop).

    Chute        $19   1 Mac
    Chute × 3    $29   3 Macs
    (nothing else changes)

> `[Judgement]` If Chute wants to test a higher number without risking the launch,
> that is the shape of the test — and it is the shape the field already validated.

---

## 5. The state of menu-bar / Finder-extension utilities for AI developers — and is Chute's slot occupied?

### 5.1 The menu bar is a bloodbath. The Finder context menu is empty.

**Menu bar, Claude-Code-aimed, as of 2026-09-01 — at least 25 distinct products:**

*Free / OSS:* `tddworks/ClaudeBar` (**1,443 stars**, pushed 2026-09-01), `AThevon/TokenEater`
(**490**, 2026-08-30), `cordwainersmith/Claudoscope` (**232**, 2026-08-26),
`juliensimon/canopy` (**108**, 2026-08-23), `gmr/claude-status`, `m1ckc3s/claude-status-bar`,
TokenBar (MIT), ClaudeUsageBar, Claude God, ClaudeMeter, AIQuotaBar, CodeQuota,
ClaUse Bar (free, MAS), Minto – Vibe Coding Tracker (free, MAS), Claude Code Notifier
($0 on Gumroad), plus the notch sub-genre: Notchi, Notch-Pilot, MacNotch, NotchIA,
CodeIsland, and web/desktop dashboards Poirot, Sniffly, Chops, Clui CC, Companion.
`[VERIFIED — star counts pulled live from api.github.com 2026-09-01]`

*Paid:* SessionWatcher ($6.99), Conan ($29), Agent Bar ($5.04), AgentQuartz Pro ($3),
NotchIA. **Five paid products against twenty-plus free ones — and the paid ones are
still shipping.**

**Finder context menu, AI-aimed: nobody.** Searches across GitHub (`topic:finder-extension`
returns **58 repos total**, and the top ten are image upload, archive management, symlinks,
new-file creation, vim-mode navigation, and path copying — **zero mention any LLM**),
Product Hunt, Reddit, the Mac App Store and Setapp found **no product that puts file
*contents* on the clipboard for a model from a Finder right-click.** `[VERIFIED — searched; absence of evidence, but a fairly thorough absence]`

### 5.2 The closest anyone gets, and the exact distance

| Product | What it does | Distance from Chute |
|---|---|---|
| **Pathly** ($4.99, MAS) | Finder right-click → copies the **path**, incl. git-relative, explicitly for Claude & Codex | **Same gesture, same buyer, different payload.** It hands the model a string; Chute hands it the bytes. This is the nearest neighbour in existence and it is one noun away. |
| **PowerClick** ($5.99, MAS) | Finder right-click grab-bag: new file, rename, copy path, clipboard history | Same surface, no AI awareness, no token count |
| `sane-apps/SaneClick` (free, 31★, 2026-08-18) | **"Finder context menu automation for macOS. Run scripts on selected files with a right-click."** | **The dangerous one.** It is the generic programmable version of Chute's gesture — someone can wire a repomix script into it in an afternoon. It has 31 stars, i.e. no distribution. |
| `wflixu/RClick` (free, **986★**) | Generic macOS Finder context-menu extender | Has the distribution SaneClick lacks; has no AI story |
| `context-root/code-clip` (free, **3★**, last push 2026-03-05, **abandoned**) | CLI: copies files to clipboard with a token count — literally prints `Copied 7 files (~4251 tokens)`, emits XML for Claude, uses `pbcopy` | **This is Chute's CLI, already built, already free — and it has 3 stars and has been dead for six months.** |
| `neilberkman/clippy` (MIT, **245★**, active) | Unified macOS clipboard tool handling text *and* files, with an MCP server so Claude can copy things | Adjacent, terminal-shaped, no Finder surface |
| Shortcuts / Automator Quick Action | Free, built in | Covered in `competitors.md` §2 |

### 5.3 What `code-clip` proves, and it is the most useful thing in this section

Someone already shipped the exact CLI — file selection → clipboard → token count →
Claude-flavoured XML — in **March 2026**. It has **3 stars** and has not been touched
since **2026-03-05**. `[VERIFIED via api.github.com]`

**The mechanism was never the moat.** Chute's CLI is a weekend of work for anyone who
wants it, and the person who did it got nothing, because a CLI with no distribution and
no gesture is invisible. What Chute is actually selling — and what `code-clip` did not
have — is (a) the Finder surface, where the selection already is, and (b) a reason for
anyone to ever hear about it. Any strategy that treats the packing logic as the asset is
defending the wrong thing.

### 5.4 Setapp

Setapp's own 2026 editorial for developers frames the market exactly the way Chute
does — *"AI code editors (Cursor, Claude Code) for real codebases, and **Mac-native
utilities for everything around the code**"* `[SECONDARY — setapp.com/app-reviews/ai-tools-developers]`.
The catalogue is 250–270 apps and its AI-adjacent entries are Eney (their own assistant),
CodeRunner, TeaCode, Proxyman. **No context-packing or Finder-selection tool is in it.**
`[VERIFIED absent from the pages fetched]` Setapp is a plausible later distribution
channel, not a launch one — and note from `gtm-tactics.md` that Panaitiu nets 64% selling
direct.

### 5.5 The verdict on the slot

**Nobody is in Chute's exact slot.** The slot next door (menu bar, usage tracking) has
25+ occupants and 5 of them charge money. The slot Chute wants (Finder right-click,
file *contents*, token count, for an agent) has **one adjacent product one noun away
(Pathly, $4.99) and nothing else.**

Read it both ways, honestly:

- **Bull:** a real, verified, empty slot immediately beside a slot proven to sustain
  paid products, with the adjacent product's own marketing copy confirming the buyer
  ("for sharing paths with Claude & Codex") — and the general-purpose Finder extenders
  (RClick 986★, SaneClick 31★) show the surface has users but nobody has aimed it at
  agents.
- **Bear:** empty slots are usually empty for a reason, and the two reasons visible here
  are that (i) the free flood arrives fast in anything Claude-Code-adjacent — 20+ free
  menu-bar apps in under a year — and (ii) the one person who built the packing CLI got
  3 stars, meaning the *demand signal for this specific job, expressed as a free tool,
  was approximately zero*. Chute's bet is that the demand shows up when the gesture is
  in Finder rather than in a terminal. **That bet is not yet supported by any evidence
  in this file, and it should be tested before it is funded with months of work.**

The cheapest possible test, given everything above: put the Finder gesture in front of
20 Claude Code users and see whether they use it twice. Nothing in this research answers
that; nothing in this research can.

---

## 6. What I could not establish

- **No native-Mac paid AI-dev utility publishes revenue.** Zero of the 22 products. The four public numbers in this file are three browser extensions and one anonymous Acquire listing. Any revenue model for Chute is extrapolated from a different product shape.
- **No controlled price experiment** for $9/$19/$29/$49 one-time dev utilities exists publicly. The distribution table in §4.1 is the substitute.
- **No published "lifetime" vs "one-time" wording test.** The field uses both together, always.
- **AgentQuartz's landing page could not be read** — client-rendered, returns only `<title>AgentQuartz</title>` to a fetcher.
- **promptbar.app** returned only its meta description.
- SessionWatcher's founder is not named on the site (the guides page attributes it to "SessionWatcher/Starck").
- The **AI Toolbox** Chrome extension's 40,000-user figure and its $9.99/mo-or-$99-lifetime pricing are `[SECONDARY]`; I did not reach the Web Store listing directly.
