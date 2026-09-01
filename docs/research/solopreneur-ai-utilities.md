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

