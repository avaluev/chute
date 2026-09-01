# LinkedIn as a distribution channel for a solo dev-tool founder — evidence file for Chute

Researched 2026-09-01. Companion to `/Users/sxope/Documents/2026/Development/37.chute/docs/research/gtm-tactics.md`
(Show HN / Product Hunt / Reddit / in-agent distribution live there and are not repeated here).

Context: Chute = $19 one-time macOS utility, free MIT CLI half. Solo founder, no LinkedIn following,
zero budget, terse/numeric voice.

**Reading key**
- `[VERIFIED]` — number came from a primary source I fetched (the study publisher's own page, an
  official doc, a peer-reviewed/arXiv paper, or the founder's own write-up).
- `[SECONDARY]` — number came from an aggregator/blog citing someone else, or from a search snippet
  I could not open. Directional only.
- `[UNVERIFIED]` — I could not trace it to any source I trust. Do not repeat it publicly.

**Standing warning.** The "LinkedIn algorithm 2026" content ecosystem is the most SEO-farmed corpus I
have researched for this project — worse than the Product Hunt one. Dozens of tool-vendor blogs
recycle the same four or five numbers with no attribution, and several invent precise-sounding
figures ("comments weigh 15x more than likes", "0–3s dwell = 1.2% engagement, 61s+ = 15.6%") that
trace to nothing. Every such number below is marked `[UNVERIFIED]` and should be treated as fiction.

---

## 0. The short version

1. **The single most reliable, primary-sourced fact in this document is the arXiv paper by LinkedIn's
   own engineers.** It says the feed ranker predicts a *set of tasks* split into passive (click,
   **long-dwell**, skip) and active (like, comment, share), and that its production win was measured
   in **time spent (+2.10%)**, not in likes. Everything the growth blogs say about "dwell time
   matters more than reactions" happens to be true, and this is why. §1a.
2. **Reach on LinkedIn is falling hard.** The largest independent study says active creators lost
   ~60% of reach in two years. You are entering a shrinking-organic-reach channel with zero
   followers. Budget LinkedIn as a **slow compounding credibility asset**, not a launch channel —
   the opposite of Show HN. §1b.
3. **The one format finding that survives cross-checking across three independent large studies is
   that document/PDF "carousel" posts win, and that plain link posts lose.** The magnitudes disagree
   wildly (7.00% vs 21.77% engagement) because the denominators differ; the *ordering* is
   consistent. §2.
4. **Buffer's 2M-post frequency study is the most directly actionable thing here for a
   zero-follower account**: posting more often raised per-post impressions at *every* tier, and
   they explicitly state it holds at 500 followers. That contradicts the folk advice to "post 2–3x a
   week max". §6a.
5. **The external-link penalty is real but much smaller than folklore claims.** The best number I
   found is **−18.8% median reach** for one link in the body — not the "−60%" or "−90%" that gets
   repeated. For a founder whose entire goal is a macOS download, a ~19% reach tax on a post that
   actually converts is a trade worth making. §4c.
6. **I found no verifiable case study of a solo developer-tool founder building distribution on
   LinkedIn with published numbers.** This is a genuine negative result, stated plainly in §3.
   The dev-tool founder success stories with real numbers all live on X/Twitter, HN and Reddit.

---

## 1. How the feed actually works in 2026

### 1a. Primary source: LinkedIn's own engineers `[VERIFIED]`

**Paper:** "An Industrial-Scale Sequential Recommender for LinkedIn Feed Ranking"
https://arxiv.org/html/2602.12354v1 (24 LinkedIn authors, published ~2026-02-12)

**Engineering blog:** "Engineering the next generation of LinkedIn's Feed", LinkedIn Engineering
Blog, ~2026-03-12 — https://www.linkedin.com/blog/engineering

What these two say, verbatim-ish:

- The ranker is a **transformer-based sequential model ("Feed SR" / "Generative Recommender")** that
  reads a member's **most recent T=1000 impressions** as an interleaved sequence of post embeddings
  and *action* embeddings — not as independent examples. It is trained on **one year of data**
  across LinkedIn's ~1.2–1.3 billion members. `[VERIFIED]`
- It has an **MMoE (multi-gate mixture-of-experts) head predicting two task groups**:
  - **passive tasks: click, skip, long-dwell** (dwelling on a post beyond a threshold)
  - **active tasks: like, comment, share** `[VERIFIED]`
  → **This is the actual, primary-source answer to "what is rewarded".** Both groups are optimised.
  Dwell is a first-class label, sitting alongside clicks; skip is an explicit negative label
  (negatives down-sampled at p=0.1 in training).
- **The reported production win is "+2.10% increase in time spent"** vs the previous DCNv2 model,
  and **+2.38% for daily-active segments.** `[VERIFIED]`
  → LinkedIn's own success metric for the new feed is *time spent*. Optimise your post for the
  reader staying on it, because that is literally the number the shipping team was graded on.
- Retrieval was rebuilt as a **unified LLM-based dual-encoder** replacing multiple legacy retrieval
  sources; it narrows hundreds of millions of candidates to ~2,000 per request at **sub-50ms**,
  with GPU-accelerated indexing and nearline embedding refresh. `[VERIFIED]`
  → Practical consequence: **retrieval is now semantic.** Your post is embedded and matched against
  a semantic representation of the viewer's interests. Writing consistently about one narrow topic
  ("macOS dev tooling for AI coding agents") is now mechanically advantaged — the embedding gets
  sharper. Topic-hopping blurs it. This is the strongest *structural* argument for a themed series
  that exists in a primary source.
- Ranking inputs named in the blog post: "viewer information (profile, headline, company,
  industry), content embeddings, engagement signals, and post metadata", plus device type, member
  profile embeddings, and aggregated affinity features. `[VERIFIED]`

**What is NOT in the primary sources**, despite being universally claimed by growth blogs:
no golden-hour rule, no hashtag rule, no edit penalty, no repost penalty, no explicit
external-link demotion coefficient, no comment-vs-reaction weighting ratio. Those are all inferred
from third-party measurement, not disclosed. Treat accordingly.

### 1b. Largest independent study: van der Blom, Algorithm Insights 2026

Richard van der Blom / Just Connecting — 7th annual edition.
Author's site: https://richardvanderblom.com/ (paid report; the site itself publishes no numbers)
`[VERIFIED that the report exists and is paid; I did not buy it]`

Numbers below are `[SECONDARY]` — reported consistently across multiple blogs and a Creator Science
podcast episode (https://podcast.creatorscience.com/richard-van-der-blom-2/, "#307: The state of
LinkedIn in 2026, based on data from 1.3 million posts"), but I could not open the report itself.

- Sample: **1.3 million posts, ~50,000 creators, H1 2026.** `[SECONDARY]`
- **Reach down ~60% for active creators over two years.** `[SECONDARY]`
- Views down ~50%, engagement down ~25%, follower growth down ~59% YoY. `[SECONDARY]`
- **One external link in the post body reduces median reach by 18.8%.** `[SECONDARY]`
  → Note how *modest* this is versus the folklore. See §4c.
- Comments containing external links are suppressed, "visibility reduced by up to 80%".
  `[SECONDARY]` → if true, this kills the classic "link in the first comment" workaround.
- Document/PDF posts at **6.60% engagement**, the top format. `[SECONDARY]`
- **"80% of the comments I receive in the first five minutes of any post are written by AI."**
  `[SECONDARY, van der Blom's own claim]` → directly relevant to §3's failure modes: the comment
  section is now substantially bot-generated, and a technical audience notices.

> **The honest read for Chute:** the headline is that organic reach is collapsing for people who
> already have followings. A brand-new account is not "down 60%" — it is starting at the current
> baseline. But it does mean the channel is harder in 2026 than every playbook written in 2023
> assumes, and that follower-count growth (−59%) is the worst-performing metric of all. **Do not set
> a follower goal. Set a "people who replied and then downloaded" goal.**

### 1c. Signal-by-signal, with the evidence grade

| Signal | What the evidence says | Grade |
|---|---|---|
| **Dwell / time spent** | A first-class training label ("long-dwell") in the production ranker; the new feed shipped on a **+2.10% time-spent** win | `[VERIFIED]` |
| **Skips** | Explicit negative label in the model | `[VERIFIED]` |
| **Comments vs reactions** | Both are "active" tasks in the same MMoE head; **no published weighting** | `[VERIFIED]` that both exist; the famous "comments = 15x a like" ratio is `[UNVERIFIED]` and I could find no source for it |
| **Semantic topic consistency** | LLM dual-encoder retrieval matches member↔content embeddings | `[VERIFIED]` mechanism, `[UNVERIFIED]` magnitude |
| **Golden hour** | Universally claimed, zero primary support. Hootsuite's own page does not use the term | `[UNVERIFIED]` |
| **Replying to your own comments** | "Replying to comments boosts overall engagement by 30%" (Buffer/Hootsuite-adjacent) | `[SECONDARY]` — plausible mechanically (each reply is an active action + resurfaces the post) but the 30% is not traceable |
| **External link in body** | −18.8% median reach (van der Blom, n=1.3M) | `[SECONDARY]` |
| **Link in first comment** | Claimed −80% visibility for link-bearing comments | `[SECONDARY]`, and it contradicts a decade of folk advice |
| **Hashtags** | No primary evidence of any effect either way. Hootsuite 2026: "hashtag stuffing is less useful than writing with clarity" | `[UNVERIFIED]` |
| **Post length** | AuthoredUp, n=372,126 posts Sep 2025–Feb 2026: 1,301–2,500 chars → **2.61–2.67% median engagement / 1,106–1,174 median impressions**, vs 1–400 chars → **2.10% / 575**. "27% higher engagement" for the long band | `[VERIFIED]` (fetched publisher's own page) |
| **Posting frequency** | Buffer, n=2M+ posts / 94k accounts: more is better at every tier (§6a) | `[VERIFIED]` |
| **Edits after publishing** | No credible study found. Folklore says edits kill reach; **no evidence either way** | `[UNVERIFIED]` |
| **Reposts** | No credible 2026 study found | `[UNVERIFIED]` |

`[UNVERIFIED — DO NOT USE]` Numbers I found circulating with no traceable source, listed so you
recognise and discard them: "posts with 0–3s dwell get 1.2% engagement vs 15.6% at 61s+";
"comments weigh 15x more than likes"; "a save drives 5x the reach of a like"; "external links = 60%
less reach"; "educational content gets 3–5x more reach". Every one of these appears only on
tool-vendor blogs with no methodology.

---

## 2. Formats — relative reach and engagement, 2026

Three independent large-sample studies. **Read the ordering, not the magnitudes** — the denominators
are different (Socialinsider measures company Pages, engagement per follower; Buffer measures posts
scheduled through Buffer, engagement per impression; Metricool measures impressions per post across
both profile types). Anyone quoting these side by side without saying that is not reading carefully.

### 2a. Socialinsider, LinkedIn Organic Benchmarks 2026 `[VERIFIED — fetched]`
https://www.socialinsider.io/social-media-benchmarks/linkedin
Sample: **1.3M posts, 16,645 business Pages, Jan 2024 – Dec 2025.** Company Pages only.

Engagement rate by format (engagement per follower):

| Format | 2024 | 2025 | YoY |
|---|---|---|---|
| **Native document (PDF carousel)** | 6.10% | **7.00%** | +14% |
| Multi-image | 6.60% | 6.45% | — |
| Video | 5.60% | 6.00% | +7% |
| Image | 4.85% | 5.30% | +9% |
| **Text-only** | 4.00% | **4.50%** | +12% |
| Poll | 4.40% | 4.20% | — |
| **Link post** | 3.30% | **3.25%** | — |

Overall platform average: **5.20%, +8% YoY.**

Also from the same study:
- **Video views fell 36% YoY across every follower tier** (e.g. 10–50k followers: 1,000 → 585 views
  per video). Meanwhile posting frequency of video **doubled** (2 → 4/month). `[VERIFIED]`
  → **Video supply is up, video demand is not.** This is the single most important 2026 format shift
  and it is the opposite of what most "video is being pushed" advice says.
- Audience growth collapsed for large accounts (100K–1M tier: 21.60% → 6.40%). Small accounts
  (1–5K) fell 40.75% → 24.50%. `[VERIFIED]`

### 2b. Buffer, best content format 2026 `[VERIFIED — fetched, 2026-03-19]`
https://buffer.com/resources/data-best-content-format-social-media/
Median engagement rate on LinkedIn:

| Format | Median ER |
|---|---|
| **Carousel (PDF)** | **21.77%** |
| Video | 7.35% |
| Image | 6.52% |
| Link | 3.81% |
| Text-only | 3.18% |

Buffer's framing: carousels get **"196% more than video and 585% more than text posts"**, while
noting "LinkedIn is evolving fast, and video is clearly the format the platform is pushing".
Buffer did not state the LinkedIn sub-sample size on that page.

### 2c. Metricool, 2026 LinkedIn Study `[VERIFIED — fetched press release]`
https://metricool.com/press-release-linkedin-study-2026/
Sample: **673,658 posts from 63,108 accounts**, Jan–Feb 2025 vs Jan–Feb 2026.

- Likes **−13%**, comments **−17%**, shares **−10%**, but **clicks +5%** and overall engagement
  **+14%**. Metricool's thesis: attention moved to **"invisible interactions"** — clicks, carousel
  swipes, video views, link taps. `[VERIFIED]`
  → For a founder selling a download, this is *good* news framed as bad news: the metric that
  correlates with your goal (clicks) is the one that went up while vanity metrics fell.
- **Personal profiles show ~63% higher engagement than Company Pages.** `[VERIFIED]`
  → **Post from Alexandr Valuev's personal profile. Do not create a Chute company page for reach.**
  (A Page is worth 20 minutes purely as a canonical link target and a "who is this" check.)
- Only **7% of Company Pages** grew enough to move up a follower tier. `[VERIFIED]`
- `[SECONDARY, from coverage of the same study]` Carousels averaged **1,451.19 impressions/post**
  vs **605.57 for video**; on Company Pages carousels 1,234.18 impressions vs images 952.90. Polls
  delivered the highest average impressions on Company Pages despite being <1% of posts.
- **Video is now the most-used format on personal profiles but underperforms carousels, images and
  multi-image.** Metricool explicitly calls this a reversal of their 2025 finding.
  `[VERIFIED from press release]`

### 2d. Where the three studies agree — the only bankable conclusions

| Conclusion | Socialinsider | Buffer | Metricool |
|---|---|---|---|
| Document/PDF carousel is the top format | ✅ #1 | ✅ #1 | ✅ #1 by impressions |
| Plain link posts are near the bottom | ✅ | ✅ | (link taps up, but link *posts* not favoured) |
| Video is oversupplied / declining per-post | ✅ views −36% | ⚠️ says platform pushes video | ✅ "adoption outpaced performance" |
| Text-only is cheap but low-ceiling | ✅ 4.50% | ✅ 3.18% (lowest) | — |

**Verdict for Chute: the default post format is a document/PDF carousel, second is multi-image,
third is a single annotated screenshot. Plain text is the fallback for a short, sharp, one-idea
post. Video is not worth the production cost at zero followers in 2026.**

Newsletters and Articles: `[SECONDARY]` newsletters are repeatedly described as delivering to
subscriber inboxes and notifications, "bypassing the algorithm". I found no large-sample study of
LinkedIn newsletter or Article reach in 2026 and no primary source. `[UNVERIFIED]` for any number.
Structurally a newsletter is the only LinkedIn surface that gives you a **push channel you own on
the platform**, which is worth something for a series — but there is no data here, only mechanism.
