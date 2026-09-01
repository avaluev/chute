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
5. **`SoftwareApplication` + `FAQPage` schema is worth doing** — but the evidence supports it for
   *machine parsing and rich results*, not for a proven citation lift. Do not believe anyone who
   quotes you a citation-lift percentage for schema; I could not find one from a primary source.

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
