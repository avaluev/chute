# Organic discovery in 2026 — GEO / AIO / SEO evidence file for Chute

Researched 2026-09-01. Companion to `/Users/sxope/Documents/2026/Development/37.chute/docs/research/gtm-tactics.md`
(channels, launches, pricing — not repeated here).

Chute = $19 one-time macOS utility (Finder right-click → files as agent context, token count).
Free MIT CLI, `brew install avaluev/tap/chute`. Static Next.js export at chutedev.com, not yet live.
Zero backlinks, zero domain authority, zero budget.

**Reading key**
- `[VERIFIED]` — I fetched the primary source (the paper itself, the vendor's own docs, the platform's own page) and read the number there.
- `[SECONDARY]` — a study/blog reporting someone else's number, or a vendor blog reporting its own unaudited study. Directional.
- `[UNVERIFIED]` — could not trace to a source I could open. Do not repeat externally.

---

## 0. The short version

1. **The GEO paper's single most relevant finding for Chute is Table 2**, not the headline 40%.
   GEO methods *hurt* the #1-ranked source (−30.3%) and *massively help* the #5-ranked source
   (+115.1%). Chute is a rank-nothing site. This is the one published result that says the tactic is
   worth more to you than to your competitors. `[VERIFIED]`
2. **What to write, concretely: statistics, direct quotes with attribution, and citations to third
   parties.** Those three were the paper's top performers (+30–40% position-adjusted word count).
   Keyword stuffing performed *worse than doing nothing* (17.7 vs 19.3). `[VERIFIED]`
3. **You do not control the citation surface — other people's pages do.** Ahrefs' 75,000-brand study
   found off-site brand mentions (YouTube 0.737, branded web mentions 0.664) correlate with AI
   visibility 2–3× more strongly than backlinks (~0.2). `[SECONDARY]` This says: the GitHub README,
   the Homebrew formula page, the awesome-list entry, and the Reddit thread matter more than
   chutedev.com does.
4. **llms.txt is dead on arrival as of 2026.** Multiple log studies show ~0 fetches by real AI
   crawlers, and Google documented that it ignores the file. Cost to ship it is 10 minutes; expected
   return is ~0. Ship it only as a cheap hedge, never as a priority. `[SECONDARY]`
5. **Schema is a 30-minute job, not a strategy.** Google says verbatim that no special schema.org
   markup is needed for its AI features; FAQ rich results were dropped 2026-05-07 and HowTo in 2023;
   the best controlled test found no schema-driven citation lift. Ship `SoftwareApplication` (it
   makes price/platform machine-readable for the directories that parse it) and stop. Every
   "schema = 2.5× more citations" figure in circulation traces only to vendor blogs — do not repeat
   them.

---

## 1. GEO — what the actual research says

### 1a. The paper: "GEO: Generative Engine Optimization" (KDD '24)

`[VERIFIED — I extracted the numbers from the PDF itself]`
Aggarwal, Murahari, Rajpurohit, Kalyan, Narasimhan, Deshpande.
Princeton / Georgia Tech / IIT Delhi / Allen Institute. arXiv 2311.09735, published at
**ACM SIGKDD 2024, Barcelona, Aug 25–29 2024**. https://arxiv.org/abs/2311.09735

**Setup:** GEO-bench — **10,000 queries** from nine sources, split 8K/1K/1K, spanning **25 domains**
across 7 categorizations. Generative engine mimicked with a retrieval pipeline (**top 5 sources
fetched**) + `gpt-3.5-turbo` for synthesis. Also validated on **Perplexity.ai** as a real deployed
engine.

**Two metrics:**
- *Position-Adjusted Word Count* — words attributed to your source, discounted exponentially by
  position in the answer. (i.e. being cited early and at length is what counts.)
- *Subjective Impression* — G-Eval–scored sub-metrics: relevance, influence, uniqueness, diversity,
  follow-up likelihood, position, count.

**Table 1 — absolute scores (baseline "No Optimization" = 19.3 overall):** `[VERIFIED]`

| Method | Pos-Adj Word Count (Overall) | Subjective Impression (Avg) |
|---|---|---|
| No Optimization (baseline) | 19.3 | 19.3 |
| **Keyword Stuffing** | **17.7** ← *worse than baseline* | 20.2 |
| Unique Words | 20.5 | 20.4 |
| Easy-to-Understand | 22.0 | 20.5 |
| Authoritative | 21.3 | 22.9 |
| Technical Terms | 22.7 | 21.4 |
| Fluency Optimization | 24.7 | 21.9 |
| Cite Sources | 24.6 | 21.9 |
| **Statistics Addition** | 25.2 | 23.7 |
| **Quotation Addition** | **27.2** (best) | **24.7** (best) |

Paper's own summary, verbatim: *"our top-performing methods, Cite Sources, Quotation Addition, and
Statistics Addition, achieved a relative improvement of 30-40% on the Position-Adjusted Word Count
metric and 15-30% on the Subjective Impression metric."* And: *"The best methods improve upon
baseline by 41% and 28% on Position-Adjusted Word Count and Subjective Impression respectively."*

On keyword stuffing, verbatim: *"we find such methods offer little to no improvement on generative
engine's responses."*

**Table 2 — THE finding for a zero-authority site.** Relative visibility improvement (%) by the
source's existing SERP rank: `[VERIFIED]`

| Method | Rank-1 | Rank-2 | Rank-3 | Rank-4 | **Rank-5** |
|---|---|---|---|---|---|
| Authoritative | −6.0 | 4.1 | −0.6 | 12.6 | 6.1 |
| Fluency Opt. | −2.0 | 5.2 | 3.6 | −4.4 | 2.2 |
| **Cite Sources** | **−30.3** | 2.5 | 20.4 | 15.5 | **+115.1** |
| **Quotation Addition** | −22.9 | −7.0 | 3.5 | 25.1 | **+99.7** |
| **Statistics Addition** | −20.6 | −3.9 | 8.1 | 10.0 | **+97.9** |

Paper's framing, verbatim: *"the Cite Sources method led to a substantial 115.1% increase in
visibility for websites ranked fifth in SERP, while on average, the visibility of the top-ranked
website decreased by 30.3%"* … *"GEO is especially helpful for lower ranked websites"* …
*"since Generative Engines utilize generative models conditioned on website content, factors such as
backlink building should not disadvantage small creators."*

> **Read-across for Chute:** this is the strongest published argument that a no-authority dev-tool
> site can win citation share it cannot win rankings. It does not say you get cited without being
> retrieved at all — you still need to be in the top-5 retrieved set for the query. It says that
> *once retrieved*, content composition is the lever, and the lever is biggest for the underdog.

**Table 3 — best method per domain** `[VERIFIED]`

| Method | #1 domain | #2 | #3 |
|---|---|---|---|
| Authoritative | Debate | History | Science |
| Fluency Opt. | Business | Science | Health |
| Cite Sources | Statement | Facts | Law & Gov. |
| Quotation Addition | People & Society | Explanation | History |
| Statistics Addition | Law & Gov. | Debate | Opinion |

A "how do I do X with tool Y" dev query is closest to *Facts / Explanation / Statement* → **Cite
Sources and Quotation Addition are the right primary levers for Chute's content**, with Statistics
Addition second.

**Combinations:** *"the best combination (Fluency Optimization and Statistics Addition) outperforming
any single GEO strategy by more than 5.5%"*, and *"using Fluency Optimization with other strategies
is most beneficial."* `[VERIFIED]`

**Real-engine validation on Perplexity.ai:** `[VERIFIED]` Quotation Addition **+22%** on
Position-Adjusted Word Count; Cite Sources and Statistics Addition **up to +9% and +37%** on the two
metrics; **Keyword Stuffing performs 10% worse than baseline.**

**Caveats you should hold — the paper is 2024, the engines are 2026.**
- The engine was a *simulation* over `gpt-3.5-turbo` with a 5-source retrieval, not ChatGPT Search,
  Claude, AI Overviews or Copilot as they exist in 2026.
- Only the Perplexity arm tested a live commercial engine.
- Nothing in the paper measures whether the optimized page is *retrieved* in the first place. It
  measures what happens after retrieval. Retrieval is still an SEO/indexing problem (§4).

### 1b. What the 2025–2026 successor studies say

The GEO paper is about *content composition*. The industry studies since are about *which sources get
retrieved at all* — and they broadly say: **not yours.**

**Ahrefs, 75,000 brands, published 2025-12-12** — https://ahrefs.com/blog/ai-brand-visibility-correlations
`[SECONDARY — vendor's own study, methodology disclosed, not peer-reviewed]`
Spearman correlations with AI brand visibility. Sample: domains with DR > 40, top keyword ≥ 800 MSV.

| Factor | ChatGPT | AI Mode | AI Overviews |
|---|---|---|---|
| **YouTube mentions** | **0.737** | 0.740 | 0.712 |
| YouTube mention impressions | 0.717 | 0.728 | 0.705 |
| **Branded web mentions** | **0.664** | 0.709 | 0.656 |
| Branded anchors | 0.511 | 0.628 | 0.527 |
| Branded search volume | 0.352 | 0.466 | 0.392 |
| **Domain Rating (DR)** | 0.266 | 0.285 | 0.326 |
| Branded traffic | 0.235 | 0.357 | 0.274 |
| Number of backlinks | "very weak" | — | — |

> **Read-across for Chute:** the two strongest correlates are *someone else saying your name* —
> on YouTube, and in text anywhere on the web. Both are things you can seed with zero budget and
> zero domain authority. DR (0.27–0.33) is roughly *half* the strength of plain branded web
> mentions (0.66–0.71). **This is the quantitative case for spending your ten hours on other
> people's pages instead of your own.** Correlation, not causation — a well-known brand gets both
> mentions and citations. But the direction is consistent across three engines.
> `[UNVERIFIED]` I could not find an equivalent study restricted to developer-tool queries.

**Profound, 680 million citations, Aug 2024 – Jun 2025** — https://www.tryprofound.com/blog/ai-platform-citation-patterns `[SECONDARY]`

| ChatGPT | | Google AI Overviews | | Perplexity | |
|---|---|---|---|---|---|
| Wikipedia | 7.8% | Reddit | 2.2% | Reddit | 6.6% |
| Reddit | 1.8% | YouTube | 1.9% | YouTube | 2.0% |
| Forbes | 1.1% | Quora | 1.5% | Gartner | 1.0% |
| G2 | 1.1% | LinkedIn | 1.3% | Yelp | 0.8% |
| TechRadar | 0.9% | Gartner | 0.7% | LinkedIn | 0.8% |

ChatGPT TLD split: `.com` 80.41%, `.org` 11.29%, `.uk` 2.16%, `.io` 1.67%, `.ai` 1.13%.
Profound's framing: *"ChatGPT favors authoritative knowledge bases," "Perplexity prioritizes
community discussions."*

**Semrush, 230K prompts / >100M citations, 2025-07-14 → 2025-10-12** —
https://www.semrush.com/blog/most-cited-domains-ai/ `[SECONDARY]`
Top domains: ChatGPT — Reddit, Wikipedia, Medium, Forbes, LinkedIn. Google AI Mode — LinkedIn,
YouTube, Reddit, Google properties. Perplexity — Reddit, LinkedIn, NIH, Microsoft, Google.
Reported LinkedIn citation rates: **14.3% of ChatGPT Search responses, 13.5% of Google AI Mode,
5.3% of Perplexity.** Notes high week-to-week volatility (Reddit and Wikipedia both dropped sharply
in ChatGPT between Aug and Sep 2025).

**The head-vs-tail caveat, and it matters.** `[SECONDARY]` Multiple reports of the same data note
that even the top domain rarely exceeds ~5% of citations and *the other ~95% is spread across
thousands of domains*. Two of these numbers (7.8% vs ~5%) are not reconcilable across sources — the
studies count differently (share of all citations vs share of top-10 slots). **Do not quote a single
"Wikipedia is X% of ChatGPT" figure; the sources disagree.**

> **The actionable conclusion from all three:** the head of the citation distribution is UGC and
> encyclopedias. For a niche technical query there is no Wikipedia page and no Forbes article, so
> the retrieved set is *whatever exists* — GitHub, Reddit, the vendor's own docs. That is Chute's
> opening, and it is entirely a "be the only page that answers this exact question" play (§4).

---

## 2. llms.txt, AI crawler robots.txt, and schema

### 2a. llms.txt — the evidence says no

**Ahrefs, 137,000 domains, May 2026** `[SECONDARY — reported via Search Engine Journal;
original at https://ahrefs.com/blog/llmstxt-study/]`
https://www.searchenginejournal.com/97-of-llms-txt-files-got-no-requests-ahrefs-data-shows/579478/
- 28% of the 137,000 domains published an llms.txt; ~38,000 had valid syntax.
- **97% of llms.txt files got zero requests in the study month.** Only ~1,100 domains saw any.
- Of the requests that did happen: audit tools 21%, unidentified bots 14%, general web crawlers
  (Googlebot) 13%, tech-profiling tools 11%. **AI retrieval bots: 1.1%.**
- The AI bots that *did* fetch it were **coding agents (10%) and training crawlers (5%)**, with
  Claude-Code and GPTBot named as the top individual bots.
- Ahrefs' conclusion as reported: the file's audience is *"coding agents and training crawlers, not
  AI search and retrieval bots."*

**Otterly.ai 90-day server-log experiment** — https://otterly.ai/blog/the-llms-txt-experiment/ `[SECONDARY]`
62,100+ AI bot visits over 90 days; **84 of them hit /llms.txt (~0.1%)**. An average content page
got ~265 visits — 3× more than the llms.txt file. Conclusion verbatim: *"There is a grassroots
appetite to publish llms.txt, but very limited evidence that leading AI search systems read or rely
on it today."*

**Seekio server-log study, 2025-09-04 → 2026-04-13, ~900 domains** `[SECONDARY, via digitalapplied.com]`
1,227 total requests to llms.txt files. **"Among the requesters there was not a single real AI bot."**
Commercial data aggregator 64.7%, human browsers 31.9%, security scanners 2.7%, **frontier AI-lab
crawlers 0.0%.**

**Correlation study, ~300,000 domains, published 2025-11-20** `[SECONDARY, via digitalapplied.com]`
10.13% adoption. Gradient-boosted model predicting AI-citation frequency: **removing the llms.txt
feature *improved* model accuracy** — i.e. it behaved as noise, not signal.

**Google's own position — the closest thing to a primary source** `[VERIFIED, fetched 2026-09-01]`
https://developers.google.com/search/docs/appearance/ai-features, verbatim:
> *"You don't need to create new machine readable files, AI text files, or markup to appear in these
> features."*
> *"There's also no special schema.org structured data that you need to add."*
> *"There are no additional requirements to appear in AI Overviews or AI Mode, nor other special
> optimizations necessary."*

`[UNVERIFIED]` No major AI lab (OpenAI, Anthropic, Google, Meta, Mistral) has published a commitment
to read llms.txt in production. I found no such statement in any of their documentation.

> **Verdict for Chute:** llms.txt costs 10 minutes and returns ~0 for search citation. **BUT** —
> the one bot category Ahrefs found actually fetching it is *coding agents*, and Claude-Code is named
> as a top individual requester. Chute's ICP literally is Claude Code. Ship a small honest
> `/llms.txt` on chutedev.com as a ~10-minute lottery ticket in exactly the one niche where the
> evidence is not zero. Do not spend an eleventh minute on it, and do not tell anyone it is an SEO
> tactic.

### 2b. AI crawler user-agents — what allowing/blocking each actually does

All from the vendors' own docs, fetched 2026-09-01. `[VERIFIED]`

| User-agent | Owner | Purpose | Blocking it does what |
|---|---|---|---|
| `OAI-SearchBot` | OpenAI | Surfaces sites in ChatGPT search | *"Sites that are opted out of OAI-SearchBot will not be shown in ChatGPT search answers, though can still appear as navigational links."* |
| `GPTBot` | OpenAI | Training data for foundation models | *"Disallowing GPTBot indicates a site's content should not be used in training generative AI foundation models."* No search effect. |
| `ChatGPT-User` | OpenAI | User-initiated fetches / GPT Actions | Not automatic crawling; *"robots.txt rules may not apply"*; doesn't determine search appearance. |
| `OAI-AdsBot` | OpenAI | Validates submitted ad landing pages | Only visits pages submitted as ads; data not used for training. Irrelevant to Chute. |
| `ClaudeBot` | Anthropic | Training data collection | *"signals that the site's future materials should be excluded from our AI model training datasets."* |
| `Claude-User` | Anthropic | Fetches pages when a Claude user asks | *"prevents our system from retrieving your content in response to a user query, which may reduce your site's visibility for user-directed web search."* |
| `Claude-SearchBot` | Anthropic | Indexes content for Claude search | *"prevents our system from indexing your content for search optimization, which may reduce your site's visibility and accuracy in user search results."* |
| `PerplexityBot` | Perplexity | *"designed to surface and link websites in search results on Perplexity. It is not used to crawl content for AI foundation models"* | Site won't appear in Perplexity results. |
| `Perplexity-User` | Perplexity | User-triggered page visits | Docs state it *"generally ignores robots.txt rules"* since the user initiated the fetch. |
| `Google-Extended` | Google | Gemini training + grounding | *"Google-Extended does not impact a site's inclusion in Google Search nor is it used as a ranking signal in Google Search."* |
| `Google-CloudVertexBot` | Google | Crawls requested by site owners for Vertex AI Agents | Irrelevant to Chute. |
| `Bingbot` | Microsoft | Powers Bing **and Copilot** | See note below. |

Sources: https://developers.openai.com/api/docs/bots ·
https://support.claude.com/en/articles/8896518-does-anthropic-crawl-data-from-the-web-and-how-can-site-owners-block-the-crawler ·
https://docs.perplexity.ai/guides/bots ·
https://developers.google.com/search/docs/crawling-indexing/google-common-crawlers ·
Anthropic publishes verification IPs at https://claude.com/crawling/bots.json

**The three practical points:**
1. **Anthropic split its crawler into three in 2026.** Blocking `ClaudeBot` (training) no longer
   blocks `Claude-SearchBot` (search visibility). If you ever want to opt out of training but stay
   citable, that is now expressible. For Chute: allow all three, obviously.
2. **`Google-Extended` is a training/grounding switch only** — blocking it does not remove you from
   AI Overviews, which are served from the regular Search index via Googlebot.
3. **The default `robots.txt` that ships with many static templates blocks nothing, which is
   correct.** The only real risk for Chute is shipping a copy-pasted "block AI scrapers" robots.txt
   from a blog post. **Verify chutedev.com's robots.txt before launch** — a zero-authority site
   blocking OAI-SearchBot is self-harm.

### 2c. Schema.org — what the evidence actually supports

**Google, verbatim, on its own AI features page:** *"There's also no special schema.org structured
data that you need to add."* `[VERIFIED]`

**The best controlled-ish test I could find** — Otterly.ai, https://otterly.ai/blog/schema-markup-real-impact-ai-search/
`[SECONDARY]` JSON-LD (FAQ, Organization, **SoftwareApplication**, Review, Article) added
2025-12-07; 4 URLs, 319 tracked prompts, US market, Nov 2025 – Mar 2026, across ChatGPT, AI
Overviews, AI Mode, Perplexity, Copilot, Gemini, Claude. Result: brand coverage **ChatGPT −71%,
Gemini −35%, Perplexity 0%, Copilot −64%, AI Mode +42%, AI Overviews +611%** — and their own
conclusion was that when compared against competitor trajectories *"the December lift was
algorithmic, not schema-driven."* They also report 6 of 7 platforms could not fetch schema when
directly asked.

`[UNVERIFIED]` Widely circulated claims — "schema makes you 2.5× / 3.7× more likely to be cited",
"Tier 1 schema = 40% more AI Overview appearances" — appear only in SEO-vendor blog posts and I
could not reach a primary study behind any of them. **Do not repeat these.**

> **Verdict for Chute:** the honest position is that schema is a **rich-results and machine-parsing**
> play, not a proven AI-citation play. That is still worth ~30 minutes:
> - `SoftwareApplication` (with `offers` → `Offer` at `price: 19`, `priceCurrency: USD`,
>   `operatingSystem: macOS`, `applicationCategory: DeveloperApplication`) — this is the type that
>   makes a price and platform machine-readable, which is exactly what a "is there a cheap Mac tool
>   for X" query needs to resolve. It is also what aggregators like AlternativeTo parse.
> - `Organization` + `WebSite` sitewide.
> - **Skip `HowTo`.** Google deprecated HowTo rich results on **2023-08-08**, desktop and mobile,
>   and removed the documentation. `[SECONDARY]`
> - **`FAQPage` no longer earns a rich result either.** Google's notice, verbatim: *"FAQ rich results
>   are no longer appearing in Google Search. We will be dropping the FAQ search appearance, rich
>   result report, and support in the Rich results test in June 2026."* Deprecation effective
>   **2026-05-07**; Search Console API support ended August 2026.
>   `[SECONDARY — https://www.searchenginejournal.com/google-drops-faq-rich-results-from-search/574429/]`
>   FAQPage remains a valid schema.org type and harmless to keep, but **the rich-result argument for
>   it is gone as of four months ago.** Anyone still selling you FAQ schema as an SEO tactic in 2026
>   has not read the changelog. Add it only if you believe the (unproven) machine-parsing argument;
>   it costs 5 minutes.
>
> That leaves `SoftwareApplication` as the only schema on this list with a live, non-speculative
> reason to exist: it makes price, platform and category machine-readable for the directories and
> aggregators that *do* parse it.
> Keep every value identical to visible page text (Google's one explicit ask: *"Making sure your
> structured data matches the visible text on the page"*). `[VERIFIED]`

---

## 3. Where AI models actually learn about dev tools

**Honest framing first:** every large citation study I could reach (Profound 680M, Semrush 230K
prompts, Ahrefs 75K brands, Growfusely 1,739 citations) is about **B2B software and consumer
queries**, not developer-tool queries. `[UNVERIFIED]` **I found no published study of AI citation
sources restricted to developer/CLI/coding-tool queries.** Anyone who gives you a ranked list with
percentages for this niche is inventing it — including me, if I did.

So I built the ranking from three things I could actually verify: (a) the general studies' *shape*,
(b) live SERP composition for Chute's exact queries (AI answer engines retrieve from these same
indexes), and (c) GitHub/Homebrew hard counts.

### 3a. Live SERP composition for Chute's actual queries `[VERIFIED — searches run 2026-09-01]`

| Query | What actually came back, in order |
|---|---|
| *"how do I get my codebase into Claude Code"* | **GitHub repo** (`zilliztech/claude-context`, 12,458★) · **official docs** (claude.com/blog/using-claude-md-files) · one indie SEO blog (stacknotice.com) · **more GitHub repos** (`khromov/context-coder`) · **MCP directory page** (glama.ai/mcp/servers/...) |
| *"claude code context files best practices"* | **official docs** (code.claude.com/docs/en/best-practices) · DataCamp · dometrain.com · claude.com blog · **Medium** · turbodocx.com · **agentsroom.dev (indie)** · siddharthbharath.com (indie) · **a GitHub issue** |
| *"cursor add files to context @ mention"* | **official docs ×2** (cursor.com/help, cursor.com/docs) · **Cursor community forum ×3** · datalakehousehub.com · **learncursor.dev (indie)** · storylane.io |
| *"repomix alternative codebase to prompt tool"* | repomix.com · **GitHub** (`yamadashy/repomix`, 28,154★) · **a GitHub Discussion comparison thread** (`glincker/stacklit` #13) · **aitoolnet.com directory** ("30 Best Repomix Alternatives in 2026") · aitoolnet comparison page |
| *"copy files for LLM prompt token count mac"* | lib.rs crate page · Medium post · **GitHub ×2** · **dev.to post** · PyPI ×3 · token-calculator.net |
| *"ChatGPT alternatives"* (control, non-dev) | **alternativeto.net at #1**, then vendor blogs |

**The ranking that falls out of this, for dev-tool queries specifically:**

1. **GitHub README / repo page** — appears in every single dev query above, usually #1 or #2.
   GitHub's `robots.txt` does not block GPTBot, ClaudeBot, OAI-SearchBot or PerplexityBot
   `[VERIFIED — fetched https://github.com/robots.txt 2026-09-01; it only lists specific path
   disallows for bingbot/adidxbot/BingPreview and similar, no AI-crawler block]`.
2. **Official vendor docs** (code.claude.com, cursor.com/docs) — the other guaranteed slot.
   You cannot occupy these, but you *can* be the third-party page that answers the question the
   official docs answer badly.
3. **Package-registry pages** — PyPI, npm, crates.io/lib.rs all surfaced. `formulae.brew.sh` has an
   open `robots.txt` with only a sitemap directive `[VERIFIED]`, so Homebrew formula pages are
   crawlable — a free indexed page per formula.
4. **Community forums and GitHub Issues/Discussions** — Cursor's forum took 3 of 9 slots on its
   query; a GitHub *Discussion* ranked for "repomix alternative". A genuinely useful comparison
   comment in a Discussion is an indexable asset.
5. **Small independent blogs** — agentsroom.dev, learncursor.dev, stacknotice.com,
   siddharthbharath.com all rank on page 1 for these queries. **This is the single most encouraging
   finding in this document: for "claude code context" queries, page 1 is not locked up by
   high-DA publishers.** Compare with the general studies where Forbes/G2/LinkedIn dominate.
6. **Tool directories** — aitoolnet.com ranked for "repomix alternatives"; alternativeto.net ranked
   **#1** for the control query "ChatGPT alternatives" `[VERIFIED]`.
7. **Reddit** — huge in the general citation studies (Perplexity 6.6%, AI Overviews 2.2%) but
   **did not surface** on any of my five dev queries. `[SECONDARY]` Reddit has content-licensing
   deals with Google and OpenAI and blocks unlicensed crawlers; `https://www.reddit.com/robots.txt`
   returns a network-policy block to scripted requests `[VERIFIED — I got HTTP block page]`. So
   Reddit's citation value flows to ChatGPT and Google, not to Perplexity/Claude, and it did not
   appear for these long-tail dev queries at all.
8. **YouTube** — Ahrefs' top correlate overall (0.712–0.740) but Growfusely found ChatGPT cites it
   "almost none" while Perplexity gave it 47 of 1,739 citations `[SECONDARY]`. For Chute a 60-second
   screen recording is cheap; treat it as a mention-generator, not a citation source.
9. **Stack Overflow** — I did not see it on any of these queries. `[SECONDARY]` The Stack Overflow
   2026 Developer Survey (49,000 respondents, 177 countries) reports 84% AI-tool adoption and 29%
   trust in AI accuracy; independent analyses describe a large post-ChatGPT activity decline.
   **Stack Overflow is not where 2026 Claude Code questions are being asked.** Do not invest here.

**Platform split worth knowing** `[SECONDARY — Growfusely, 1,739 citations, 128 queries across 16
B2B software categories, 8 phrasings each, July 2026, via Perplexity Sonar API and OpenAI web-search
API]`: ChatGPT cites **vendor web pages 24%** vs Perplexity **12%**; Perplexity is the only one that
meaningfully cites YouTube (47) and Reddit (11); review platforms 7.3% overall, G2 the biggest at 41.

> **The strategic read:** ChatGPT — the engine Chute's buyers actually use most — leans on *vendor
> pages* twice as hard as Perplexity does. chutedev.com is therefore not worthless; it is the single
> page most likely to be cited *once the product is known enough to be retrieved.* But retrieval
> comes from GitHub, Homebrew, directories and other people's posts. **Own pages convert; other
> people's pages get you retrieved.**

### 3b. The GitHub numbers that set the bar `[VERIFIED — GitHub API, 2026-09-01]`

| Repo | Stars |
|---|---|
| `yamadashy/repomix` | 28,154 |
| `coderamp-labs/gitingest` | 15,370 |
| `zilliztech/claude-context` | 12,458 |
| `mufeedvh/code2prompt` | 7,621 |
| `simonw/files-to-prompt` | 2,778 |
| `mohsen1/yek` | 2,475 |

Topic sizes `[VERIFIED — GitHub search API]`: `ai` 170,743 · `llm` 124,102 · `cli` 122,235 ·
`mcp` 69,840 · **`claude-code` 66,589** · `developer-tools` 61,647 · `macos` 52,382 ·
`claude` 48,798 · `cursor` 14,608 · `llm-tools` 5,338 · `context-engineering` 2,927.

Note what `yamadashy/repomix` did with its topics: **20 of them**, including every model name
(`claude`, `chatgpt`, `gemini`, `deepseek`, `llama`, `openai`, `anthropic`) plus `mcp`,
`developer-tools`, `genai`. That is the incumbent's own, checkable, free tactic. GitHub allows 20
topics per repo; Chute should use all 20.

---

## 4. Classic SEO that still works for a zero-authority dev-tool site

### 4a. Keyword demand — what I could actually measure

**I have no keyword volume numbers.** Ahrefs/Semrush volume data is paywalled and I will not invent
it. `[UNVERIFIED — volumes unavailable]` What follows is **Google Autocomplete**, which is a real
signal of query *existence and phrasing* (it is generated from actual queries), not of volume.
All pulled from `suggestqueries.google.com` on 2026-09-01. `[VERIFIED — I ran the requests]`

**"claude code context" →**
`claude code context window` · `claude code context window size` · `claude code context management` ·
`claude code context7` · `claude code context window limit` · **`claude code context window full`** ·
`claude code context mode` · `claude code context limit` · `claude code context size`

**"claude code context window f" →**
`claude code context window full` · `claude code context window almost full` ·
`what happens when claude code's context window fills up during a long session` ·
`claude code your context window is full` · **`what to do when claude code context window is full`**

**"how to add files to claude code" →**
**`how to add files to claude code context`** · `how to add files to claude code terminal` ·
`how to add files to claude code cli` · `how to upload files to claude code` ·
**`how to add multiple files to claude code`** · `how to add md file to claude code`

**"claude code token" →**
`claude code token cost` · `claude code token limit` · `claude code token usage` ·
`claude code token optimization` · `claude code token usage report` · `claude code token usage monitor`

**"repomix" →**
`repomix github` · **`repomix alternatives`** · `repomix commands` · `repomix mcp` · `repomix npm` ·
`repomix install` · `repomix reddit` · **`repomix claude code`** · `repomix skill`
**"repomix alternative" →** `repomix alternatives` · **`repomix alternative reddit`** (only two —
low but non-zero demand)
**"gitingest alt" →** `gitingest alternative` (one suggestion)

**"codebase to prompt" →** `codebase to llm prompt tool` · `codebase to llm prompt` ·
`convert codebase to prompt` (thin but real)

**"best tools for claude code" →** `best tools for claude code reddit` · `best mcp tools for claude
code` · **`best cli tools for claude code`** · `best ui tools for claude code` ·
`best terminal tools for claude code` · `best memory tool for claude code`

**"cursor context" →** `cursor context window` · `cursor context usage` · `cursor context management`
· `cursor context compaction` · `cursor context limit`

**"copy files for llm" → ZERO suggestions.** `[VERIFIED]` **This phrase has no measurable demand.
Do not build a page for it, do not put it in your h1.** Users do not describe the job that way.

**"claude code finder" → nothing relevant** (`claude code search engine`, `claude code bug finder`
…). The Finder-menu framing has no search demand either. `[VERIFIED]`

> **The demand map, ranked, and it is not where you'd guess:**
> 1. **The context-window-is-full cluster is the biggest by far** — six separate autocomplete
>    variants, including full natural-language questions, which Google only surfaces for queries
>    people really type. Chute's token count is the answer to this, and *nobody is selling into this
>    cluster with a Mac utility.*
> 2. **"how to add files to claude code context" / "how to add multiple files to claude code"** —
>    this is literally Chute's product description as a search query. Highest intent on the list.
> 3. **"claude code token usage / cost / optimization / monitor"** — adjacent, high commercial
>    intent, and a real content angle.
> 4. **"repomix alternatives" / "gitingest alternative"** — confirmed real, low volume. Worth one
>    page each, not more.
> 5. **"codebase to prompt"** — thin.
> 6. **"copy files for llm"** — dead. Kill it from the copy.

### 4b. Comparison / "alternative to X" pages

`[UNVERIFIED]` I still could not find a primary case study quantifying "X alternative" page
performance for a dev tool — same gap as `gtm-tactics.md` §6d. What I *can* now show:
- The queries exist (autocomplete above). `[VERIFIED]`
- Directory pages rather than vendor pages own them: `aitoolnet.com` "30 Best Repomix Alternatives
  in 2026" ranked for the alternative query; `alternativeto.net` ranked **#1** for the control
  "ChatGPT alternatives". `[VERIFIED]`
- The GEO paper's Table 2 says content-composition tactics deliver **+115.1%** visibility to a
  rank-5 source and **−30.3%** to a rank-1 source. A comparison page is exactly a rank-5 source.
  `[VERIFIED]`

**Write them in the GEO shape, because that is the one thing the research actually supports:**
statistics (real token counts, real timings, real star counts), direct quotes (from the competitor's
own README/docs, attributed), and citations to third parties. Not adjectives.

### 4c. Docs-as-SEO and changelog

`[SECONDARY]` Covered in `gtm-tactics.md` §6e; the new evidence here is that **official docs took a
page-1 slot on every dev query I ran**, and that indie tutorial sites took slots alongside them.
The gap to exploit is the question the official docs answer badly. Concretely, `code.claude.com`
documents CLAUDE.md and `/context`; it does not have a page titled *"what to do when your context
window is full"* — and Google's autocomplete says people type that sentence.

### 4d. Programmatic pages

**Skip.** `[UNVERIFIED as a tactic here]` Chute has no dataset to templatize (no per-language, no
per-framework, no per-integration axis), and thin programmatic pages on a zero-authority domain are
the classic way to earn a site-wide quality problem. There is nothing in the research supporting it
for a single-purpose $19 utility.

---

## 5. Getting into other people's content

Ranked by (evidence it ranks/gets crawled) × (hours to execute).

| Surface | Ranks? | Crawlable by AI bots? | Effort | Verdict |
|---|---|---|---|---|
| **GitHub README + 20 topics** | Yes — #1 or #2 on every dev query I ran `[VERIFIED]` | Yes — no AI-bot block in `github.com/robots.txt` `[VERIFIED]` | 2h | **Do first.** |
| **Homebrew formula page** | Formula pages are static, sitemapped, `robots.txt` allows all `[VERIFIED]` | Yes | Already done | Free permanent indexed page. |
| **awesome-lists** | Rank for "best X github" `[SECONDARY, gtm-tactics §6a]` | Hosted on GitHub → yes | 1h each | **Highest ROI/hour** (unchanged from prior research). |
| **AlternativeTo** | Ranked **#1** for "ChatGPT alternatives" `[VERIFIED]` | `robots.txt` has `User-agent: *`, no AI block `[VERIFIED]` | 30min | **Do it — but see the trap.** |
| **Product Hunt** | DA ~91 `[SECONDARY, gtm-tactics §4]`; permanent page | `robots.txt` `User-agent: *`, no AI block `[VERIFIED]` | 1h | Already planned. Backlink is the point. |
| **GitHub Discussions / Issues comparison comments** | A GitHub Discussion ranked for "repomix alternative" `[VERIFIED]` | Yes | 30min | Cheap and legitimate if genuinely useful. |
| **dev.to / Medium** | dev.to surfaced on a dev query `[VERIFIED]`; Medium ranked on the Claude Code query `[VERIFIED]`; Semrush lists Medium in ChatGPT's top domains `[SECONDARY]` | dev.to `robots.txt` `User-agent: *` `[VERIFIED]` | 2h/post | Worth one cross-post of the technical post. |
| **aitoolnet / AI-tool directories** | Ranked for "repomix alternatives" `[VERIFIED]` | Presumably | 20min | Cheap; low quality but it ranks. |
| **StackShare** | Returned HTTP 429 to me; could not verify `[UNVERIFIED]` | Unknown | — | **Skip.** No evidence it still matters; it is a company-stack directory, wrong shape for a $19 personal utility. |
| **Slant** | Returned HTTP 403; did not surface on any query I ran `[UNVERIFIED]` | Unknown | — | **Skip.** No evidence of 2026 relevance. |
| **Stack Overflow** | Did not surface on any dev query `[VERIFIED, my searches]`; activity declining `[SECONDARY]` | Yes | — | **Skip.** |

### 5a. The AlternativeTo trap — act on this before launch week

`[SECONDARY — https://launchdirectories.com/directory/alternativeto and other submission guides;
alternativeto.net returns 403 to non-browser fetches so I could not read the policy first-hand]`
Reported: **a new AlternativeTo account must be seven days old before it can submit an app**, and
submissions are human-reviewed. Listing is free. Submit form reported at
`https://alternativeto.net/manage/new/`.

> **Concretely: create the AlternativeTo account today.** If the 7-day rule is real, creating it on
> launch day costs you the whole launch week on the one directory with verified #1-for-"alternatives"
> ranking. Cost of hedging: 90 seconds.

### 5b. Homebrew analytics — the open question from `gtm-tactics.md` §6c is now RESOLVED

`[VERIFIED — I downloaded and parsed https://formulae.brew.sh/api/analytics/install-on-request/30d.json
on 2026-09-01, period 2026-08-02 → 2026-09-01, 8,765,297 total events, 28,659 items]`

**Third-party taps ARE in the public analytics JSON, addressed by full `owner/tap/formula` name.**
14,488 of the 28,659 entries contain a slash. Examples pulled straight from the file:

| Formula | Rank | 30-day install-on-request |
|---|---|---|
| `gh` (core, #1 overall) | 1 | 288,697 |
| `anomalyco/tap/opencode` | 9 | 84,620 |
| `hashicorp/tap/terraform` | 110 | 16,078 |
| `supabase/tap/supabase` | 127 | 12,626 |
| `metalbear-co/mirrord/mirrord` | 171 | 9,457 |
| `stripe/stripe-cli/stripe` | 194 | 8,202 |
| `oven-sh/bun/bun` | 207 | 7,502 |

**Distribution across third-party tap formulae only** (n = 14,488):
rank 1 = 84,620 · rank 11 = 7,714 · rank 101 = 824 · rank 501 = 79 · rank 1,001 = 31 ·
rank 2,001 = 11 · rank 5,001 = 3 · rank 10,001 = 1. **6,677 entries have a count of exactly 1.**

> **This is your free, public, self-serve top-of-funnel dashboard, and it needs no work to enable.**
> Fetch that JSON, grep `avaluev/tap/chute`, and you have a real monthly install-on-request number —
> the denominator for every conversion claim in `gtm-tactics.md` §2.
> **Calibration you should internalise now:** landing in the top ~500 third-party formulae means
> ~79 installs/month. At the 1–3% open-source conversion benchmark that is **1–2 sales a month.**
> The comparable that matters is `anomalyco/tap/opencode` at 84,620 — an AI coding agent, the same
> audience, showing the ceiling of this channel is real but is reached by being the *product people
> want*, not by tap hygiene.
>
> Command: `curl -s https://formulae.brew.sh/api/analytics/install-on-request/30d.json | grep -o '"formula":"avaluev/tap/chute","count":"[^"]*"'`

---

## 6. The ~10-hour checklist, ordered by expected return

Nothing here costs money. Each item names the evidence. Times are honest estimates.

### Hour 0 — 2 minutes, do it before you read the rest
**0. Create the AlternativeTo account now.** Reported 7-day account-age requirement before you can
submit an app (§5a) `[SECONDARY]`. AlternativeTo ranked #1 for the control "alternatives" query
`[VERIFIED]`. If you create it on launch day you lose launch week on the best-ranking directory.

### Hours 1–2 — the GitHub README (highest return, unambiguously)
**1. Rewrite the README as a GEO-shaped landing page.** (1.5h)
Evidence: GitHub was #1 or #2 on **every** dev-tool query I ran `[VERIFIED]`; GitHub's robots.txt
does not block AI crawlers `[VERIFIED]`; the GEO paper's three winning tactics are Cite Sources,
Quotation Addition, Statistics Addition, worth +30–40% position-adjusted visibility, and
**+115.1% for a rank-5 source** `[VERIFIED]`.
Concretely, in the README:
- **Statistics** — real numbers, not adjectives. "Counts tokens for N files in X ms." "A 40-file
  selection is ~Y tokens." "Chute's own repo packs to Z tokens." Statistics Addition scored 25.2 vs
  19.3 baseline.
- **Cite sources** — link Anthropic's context-window docs, the tokenizer you use, the Homebrew
  analytics page. Cite Sources gave rank-5 sources +115.1%.
- **Quote** — one attributed direct quote (a user, an issue, a docs line). Quotation Addition was
  the single best method on both metrics (27.2 / 24.7).
- **NO keyword stuffing.** It scored **17.7 vs a 19.3 baseline** — actively worse than nothing, and
  10% worse than baseline on live Perplexity `[VERIFIED]`.
- The demo GIF and the honest $19 GUI paragraph (`gtm-tactics.md` §6b) — unchanged.

**2. Set all 20 GitHub topics.** (15 min)
Evidence: `yamadashy/repomix` (28,154★) uses 20 including every model name `[VERIFIED]`. Topic
sizes `[VERIFIED]`: `claude-code` 66,589 · `mcp` 69,840 · `developer-tools` 61,647 · `macos` 52,382 ·
`cursor` 14,608 · `llm-tools` 5,338 · `context-engineering` 2,927.
Suggested set: `claude-code, cursor, llm, ai, macos, cli, developer-tools, anthropic, claude,
openai, chatgpt, gemini, prompt-engineering, context-engineering, llm-tools, tokenizer, finder,
swift, mcp, generative-ai`.

**3. Verify chutedev.com's robots.txt allows every AI crawler.** (15 min)
Evidence: blocking `OAI-SearchBot` removes you from ChatGPT search answers; blocking
`Claude-SearchBot`/`Claude-User` reduces Claude visibility; blocking `PerplexityBot` removes you from
Perplexity — all from the vendors' own docs `[VERIFIED]` (§2b). Copy-pasted "block the AI scrapers"
robots.txt from a blog post is the one way to lose this for free.

### Hours 3–5 — the three pages that answer the queries that exist
Evidence for the queries: Google Autocomplete, pulled 2026-09-01 `[VERIFIED]` (§4a). Evidence for
the page type: indie blogs (agentsroom.dev, learncursor.dev, stacknotice.com) hold page-1 slots on
these exact queries `[VERIFIED]`, unlike general-interest queries where Forbes/G2/LinkedIn dominate
`[SECONDARY]`.

**4. "What to do when your Claude Code context window is full."** (1.5h) — **the biggest cluster.**
Six distinct autocomplete variants including full sentences (`what to do when claude code context
window is full`, `claude code your context window is full`, `what happens when claude code's context
window fills up during a long session`) `[VERIFIED]`. `code.claude.com` has no page with this title.
Chute's token count *is* the answer. Write it as genuine advice — `/clear`, `/compact`, CLAUDE.md
size, and "know the number before you paste" — with Chute as one of several answers.

**5. "How to add multiple files to Claude Code's context."** (1h) — highest intent.
Autocomplete confirms `how to add files to claude code context`, `how to add multiple files to
claude code`, `how to add files to claude code cli` `[VERIFIED]`. This is Chute's product
description as a search query. Cover `@`-mentions, drag-drop, CLI piping, and Chute.

**6. "Repomix alternatives" + "gitingest alternative."** (30 min, one page)
Autocomplete confirms both, plus `repomix alternative reddit` `[VERIFIED]`. Low volume — one honest
page, not a suite. Directory pages currently own this slot (`aitoolnet.com`) `[VERIFIED]`, which
means it is winnable by anyone with a real comparison. Name where repomix is better (whole-repo
packing, CI, cross-platform); Chute wins on Finder-level selection and instant token count. GEO
shape: real token counts for the same repo through each tool. Dishonest comparison pages get called
out on HN (`gtm-tactics.md` §6d).

### Hours 6–7 — other people's pages
Evidence: Ahrefs' 75,000-brand study puts **branded web mentions at 0.66–0.71** vs **DR at
0.27–0.33** — off-site mentions correlate with AI visibility ~2× more strongly than authority
`[SECONDARY]` (§1b).

**7. awesome-list PRs.** (1h) Unchanged from `gtm-tactics.md` §6a — smallest and most relevant lists
first. Now with the added reason: they live on GitHub, which is the #1 retrieved surface for dev
queries `[VERIFIED]`.

**8. AlternativeTo submission** using the account from step 0. (30 min) Listing free; human-reviewed.
`[SECONDARY]` Add Chute as an alternative to repomix, gitingest, code2prompt.

**9. One useful comparison comment in a relevant GitHub Discussion / Issue.** (30 min)
Evidence: a GitHub Discussion (`glincker/stacklit` #13) ranked on page 1 for "repomix alternative"
`[VERIFIED]`. Genuine contribution only — the 90/10 rule (`gtm-tactics.md` §6f) applies here too.

### Hours 8–9 — schema and the technical page
**10. `SoftwareApplication` JSON-LD on chutedev.com.** (30 min)
The only schema on the list with a live, non-speculative reason: it makes price / platform /
category machine-readable for the aggregators that parse it. Google says explicitly *"There's also
no special schema.org structured data that you need to add"* to appear in AI features `[VERIFIED]`,
FAQ rich results were dropped 2026-05-07 and HowTo in 2023 `[SECONDARY]`, and the best controlled
test found the effect vanished against competitor trajectories `[SECONDARY]` (§2c). So: 30 minutes,
no more, and no claims about it.
Keep every value identical to the visible page text — Google's one explicit ask `[VERIFIED]`.
Fields: `applicationCategory: DeveloperApplication`, `operatingSystem: macOS`,
`offers: {price: "19", priceCurrency: "USD"}`.

**11. `/llms.txt` — 10 minutes, as a lottery ticket only.** (10 min)
Evidence *against*: 97% of llms.txt files got zero requests across 137,000 domains in May 2026;
0.1% of AI bot visits in a 90-day log study; a ~900-domain log study found "not a single real AI
bot"; a 300,000-domain model found it behaved as *noise*; Google says it does not use it
`[VERIFIED]` (§2a). Evidence *for*, and it is narrow: the AI bots that did fetch it were
**coding agents (10%)** and training crawlers (5%), with **Claude-Code named as a top individual
requester** `[SECONDARY]`. Chute's ICP is Claude Code users. Ten minutes. Never call it SEO.

**12. The technical blog post** (1h of the 2h it deserves; finish it later).
Unchanged from `gtm-tactics.md` §7 item 10 — Panaitiu's M1 post did 30k views. Write the hardest
thing you actually solved. Cross-post to dev.to (surfaced on a dev query `[VERIFIED]`; Medium is in
ChatGPT's top-cited domains `[SECONDARY]`).

### Hour 10 — instrumentation, so the next ten hours are informed
**13. Wire up the Homebrew number.** (30 min)
`[VERIFIED]` Third-party taps are in the public analytics JSON.
```
curl -s https://formulae.brew.sh/api/analytics/install-on-request/30d.json \
  | grep -o '"formula":"avaluev/tap/chute","count":"[^"]*"'
```
Calibration `[VERIFIED from that file]`: rank 101 of third-party formulae = 824 installs/month;
rank 501 = 79; rank 1,001 = 31; 6,677 formulae sit at exactly 1. At the 1–3% open-source conversion
benchmark (`gtm-tactics.md` §2), 79 installs/month ≈ 1–2 sales/month. **Know this number before you
believe any funnel story.**

**14. Search your own queries monthly.** (30 min/month, not part of the 10h)
Run the six queries in §3a and §4a in ChatGPT, Claude and Perplexity and record whether Chute is
cited. That is your only real GEO measurement, and it is free.

### Explicitly NOT in the ten hours
- **Programmatic pages** — no dataset to templatize; thin-page risk on a zero-authority domain (§4d).
- **Stack Overflow** — did not surface on any dev query I ran `[VERIFIED]`; declining activity `[SECONDARY]`.
- **StackShare, Slant** — no evidence of 2026 relevance; both refused my fetches `[UNVERIFIED]`.
- **"copy files for llm" as a keyword** — Google Autocomplete returns **zero suggestions**
  `[VERIFIED]`. There is no demand for that phrasing. Same for "claude code finder".
- **Keyword-optimising anything** — scored 17.7 against a 19.3 baseline in the GEO paper and 10%
  below baseline on live Perplexity `[VERIFIED]`.
- **Any schema beyond SoftwareApplication + Organization** — FAQ and HowTo rich results are both
  dead `[SECONDARY]`.

---

## 7. Open questions I could not resolve

- **`[UNVERIFIED]` There is no published citation study restricted to developer-tool queries.**
  Everything in §3 is inferred from live SERPs plus general studies. This is the biggest gap.
- **`[UNVERIFIED]` No keyword volume numbers.** Autocomplete proves a query exists, not how often it
  is typed. Every volume figure in circulation for these terms is paywalled or fabricated.
- The GEO paper is 2024 and its engine was a `gpt-3.5-turbo` simulation with a 5-source retrieval.
  Only the Perplexity arm tested a live commercial engine. Nothing has replicated it on ChatGPT
  Search, Claude, AI Overviews or Copilot at 2026 scale that I could find.
- **The head-of-distribution numbers disagree across studies** (Wikipedia at 7.8% of ChatGPT
  citations vs "top domain rarely exceeds 5%"). They count different denominators. Do not quote
  either externally.
- Ahrefs' 75K-brand correlations are correlational and restricted to DR > 40 domains — i.e. the
  study population *excludes sites like chutedev.com*. Direction is probably right; magnitude for a
  DR-0 site is unknown.
- AlternativeTo's 7-day account rule comes from third-party submission guides; alternativeto.net
  returns 403 to non-browser fetches so I could not read the policy first-hand. **Cost of assuming
  it's true is 90 seconds. Assume it's true.**
- No AI lab has published a position on llms.txt. Absence of a commitment, not a documented refusal
  (except Google, which documented it).
- `[UNVERIFIED]` Every "schema markup makes you 2.5×/3.7× more likely to be cited" figure traces
  only to SEO-vendor blogs. I could not reach a primary study. Do not repeat them.
