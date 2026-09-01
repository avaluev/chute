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

### 2e. Semantic retrieval and "topic authority" — the mechanism, honestly

LinkedIn published **360Brew** (arXiv 2501.16450, submitted 2025-01-27, Firooz et al., LinkedIn
Foundation AI Technologies): a **150B-parameter decoder-only foundation model built on Mixtral
8x22B**, solving 30+ predictive tasks across LinkedIn surfaces via natural-language prompts instead
of hand-built features. `[VERIFIED that the paper exists and describes this]`
https://arxiv.org/abs/2501.16450

Combined with the LLM dual-encoder retrieval in §1a, this means **your content is represented
semantically, and so is the viewer.** Growth blogs have branded this "Topic Authority" and attached
timelines to it ("2–4 weeks for signal, 60–90 days for authority"). **Those timelines are
`[UNVERIFIED]` and appear in no paper.** The mechanism is real and primary-sourced; the numbers
bolted onto it are invented.

**The defensible version for Chute:** post about one narrow, machine-legible topic — *macOS
tooling for people who run AI coding agents* — and the semantic retrieval layer has an easier job
matching you to the right 2,000-candidate pool. Do not post about hiring, productivity, or your
opinion on remote work.

---

## 3. What works for developer-tool founders — including what I could not find

### 3a. The negative result, stated plainly

**I could not find a single verifiable case study of a solo developer-tool founder who built
distribution on LinkedIn and published real numbers.** `[VERIFIED as a negative — I looked]`

What I found instead, and why each fails the evidence bar:
- Countless agency/tool-vendor posts titled "LinkedIn for technical founders" with **zero named
  examples and zero numbers** (e.g. https://columncontent.com/developer-linkedin-presence/ — its
  only case is an unnamed "backend engineer client", no metrics).
- Podcast/blog headlines like "How a Solo Dev Reached 10K MRR Selling Only on LinkedIn"
  (podimo.com) — an unverifiable podcast summary, no name, no numbers I could check.
- Indie-hacker roundups asserting "500–5,000 followers in the first 12 months and 20–200 paying
  customers over 24 months" `[UNVERIFIED]` — no methodology, no source.

Contrast this with `/Users/sxope/Documents/2026/Development/37.chute/docs/research/gtm-tactics.md`,
where the X/Twitter, HN and Reddit stories came with founder-published numbers (Panaitiu's $108,400
year, Aidlab's 6,000 views / 0 sales). **That asymmetry is itself the finding: dev-tool distribution
success is documented on X, HN and Reddit, and undocumented on LinkedIn.**

### 3b. What I could verify: real dev-tool posts, with real (small) numbers

I fetched actual public LinkedIn posts from the Tiger Data / TimescaleDB team about their
`pg_textsearch` Postgres extension — a genuinely technical, genuinely well-executed dev-tool
campaign by people with real followings. `[VERIFIED — fetched each post]`

| Post | Author | Reactions | Comments |
|---|---|---|---|
| https://www.linkedin.com/posts/ajaykulkarni_github-timescalepgtextsearch-postgresql-activity-7406384951925035009-BS1t | Ajay Kulkarni (CEO, Tiger Data) | **72** | 2 |
| https://www.linkedin.com/posts/dmagda_you-dont-need-elasticsearch-bm25-is-now-activity-7410667799980777473-SGjl | Denis Magda | **42** | 4 |
| https://www.linkedin.com/posts/mfreed_postgres-bm25-search-activity-7394538283231514624-vFxU | Mike Freedman (CTO) | **20** | — |

Freedman's post text is worth studying because it is exactly the register Chute should use — no
adjectives, a literal SQL line, and a dated roadmap:

> "pg_textsearch is a new Postgres extension that brings BM25 keyword search natively to Postgres
> -- built from the ground up using Postgres' index access method interface. […] As simple as
> creating a Postgres index: ▶ CREATE INDEX articles_idx ON articles USING bm25(content) WITH
> (text_config='english'); Planned roadmap: ⟡ Released (last month): Full SQL interface with
> in-memory (memtable-only) storage ⟡ Nov: Out-of-core scalability… ⟡ Dec/Jan: Compressed disk
> segments, skip lists, and optimized query evaluation (BlockMax WAND)"

Note the top comment on Magda's post, from a real engineer:
> "The title is misleading. Elasticsearch (Lucene) isn't just about scoring and ranking with BM25,
> it's a whole lot of engineering masterpiece crafted over the span of 25 years."

> **Calibration, and this is the most useful number in this whole section:** a CTO and a CEO of a
> funded, well-known Postgres company, posting technically excellent content about a launch, got
> **20–72 reactions.** If your expectation for a Chute post is "hundreds of likes", reset it now.
> **A technically correct dev-tool post on LinkedIn earns double-digit reactions. Judge posts by
> who commented and who clicked, never by the reaction count.**

**A caution about a widely-cited "example".** The Tech Audience Accelerator newsletter
(https://techaudienceaccelerator.substack.com/p/hype-words-are-killing-your-technical) presents a
pg_textsearch post as having earned **"1,131 likes and 173 reposts"**. I fetched the three public
pg_textsearch posts I could find and none is close to that. `[UNVERIFIED — and contradicted by the
three posts I actually opened.]` Do not use that number, and treat the source's other claims with
matching suspicion.

### 3c. What that newsletter got right (mechanism, not numbers)

Its "boring simple" framing is consistent with everything else I read about technical audiences and
matches Freedman's real post. `[SECONDARY — an opinion piece, but a well-argued one]`

- Words it names as credibility-destroying with engineers: **"game-changing", "revolutionary",
  "groundbreaking", "seamless integration", "intuitive interfaces", "enterprise-ready"**.
  (This overlaps exactly with Alexandr's existing banned-word list. Good.)
- The stated principle: *"The more something sounds impressive, the less they believe it."*
- The replacement move is **understatement + a literal command**: "Getting started is boringly
  simple: `CREATE EXTENSION pg_textsearch;`"
- *"Nobody lies by calling their product boring."*

### 3d. Failure modes — what makes a technical audience mute you

Consolidated from the sources above plus the Hacker News thread "LinkedIn CringeBot 3000"
(https://news.ycombinator.com/item?id=49268564) `[SECONDARY — community sentiment, not data]`:

1. **Hype adjectives.** See 3c. One "seamless" and a developer stops reading, permanently.
2. **The manufactured-vulnerability post.** "I failed. Here's what it taught me about leadership."
   Engineers read this as a format, not a story.
3. **Engagement-bait openers.** The autoposting.ai study (§3e) found **82% of underperforming posts**
   opened with "I want to share something with you" / "Unpopular opinion". Those phrases are now
   *negatively* diagnostic.
4. **AI-written comments.** van der Blom's claim that **80% of comments in a post's first five
   minutes are AI-written** `[SECONDARY]` means your comment section is where credibility dies.
   Deleting obvious AI slop from your own posts is a real editorial job.
5. **One-sentence-per-line "LinkedIn poetry".** It is the visual signature of the growth-hacker
   genre. A technical reader pattern-matches it before reading a word. This is in direct tension
   with §4b's whitespace advice — resolved there.
6. **Claiming numbers you cannot show.** Post the `brew` install count, the actual benchmark, the
   real diff. A dev audience will ask for the methodology, and on LinkedIn, unlike HN, nobody
   downvotes — they just never come back.
7. **Posting a launch and nothing else.** A profile whose only content is "I shipped X" reads as an
   ad account.

### 3e. One quantitative study of founder posts, with caveats
autoposting.ai, "LinkedIn Founder Strategy: 1,200+ Analyzed"
https://autoposting.ai/blog/linkedin-founder-strategy `[SECONDARY — vendor-published, no raw data]`
Claimed method: 1,200 founder profiles over 90 days, 621,833 posts, plus 9,000+ business pages.

- **91% of underperforming posts opened with data or a claim about the size of a problem.**
  → Directly relevant: "40% of your day is spent doing X" is the *bad* opener. The scene is the
  good opener.
- **82% of underperformers opened with a generic hook** ("I want to share something with you",
  "Unpopular opinion").
- Claims top performers post **4–5×/week, not daily**, and that daily posting underperformed.
  → **This contradicts Buffer's much larger and better-documented study (§6a). See §6c.**
- Also repeats "external links = 60% reach reduction", which the two *first-party* link studies in
  §4c contradict. Treat this source as directionally interesting on *hooks* and unreliable on
  *reach*.

---

## 4. Post anatomy that survives a technical reader

### 4a. The truncation point — exact numbers

| Surface | Characters before "…see more" |
|---|---|
| Desktop | **~210** |
| Mobile app | **~140** |
| Hard post limit | **3,000** |

Source: AuthoredUp, "LinkedIn Character Limits 2026"
https://authoredup.com/blog/linkedin-character-limit `[VERIFIED — fetched publisher page]`
Also: comments cap at 1,250 chars and display in full (no truncation); headline 220 chars, ~60–70
visible in search; About 2,600 chars, ~300 visible. Standard emoji count as **2** characters;
flags/skin-tone variants **4–7**. Line breaks count.

> **Design rule: write the hook to land inside 140 characters, not 210.** Mobile is the tighter
> constraint and you cannot detect which surface a reader is on. 140 characters is roughly one
> short sentence plus a fragment.

### 4b. Length — and the tension with terseness

AuthoredUp, **n = 372,126 posts, Sep 2025 – Feb 2026** `[VERIFIED — fetched]`:

| Length | Median engagement | Median impressions |
|---|---|---|
| 1–400 chars | 2.10% | 575 |
| 1,301–2,500 chars | **2.61–2.67%** | **1,106–1,174** |

"Posts between 1,301 and 2,500 characters generate 27% higher engagement than posts under 400."

Corroborated independently:
- Saywhat / Will McTighe, **n = 397,605 posts, Q1 2026**: *"Long is the new short. 1,250–3,000
  characters perform best."* `[VERIFIED — fetched the post itself]`
- LinkPost study, **n = 438,413 posts** (heavy French-language skew, impressions available for only
  1.9% of posts — a serious limitation they disclose): *1,500+ chars = 49% more engagement than
  <300 chars.* `[SECONDARY]` https://www.linkpost.gg/en/playbooks/linkedin-algorithm-playbook-2026/study

> **Three independent large samples agree: long posts win.** This is the finding most in tension
> with Alexandr's terse voice, and the resolution is *not* to pad. It is: **many short lines, high
> information density, no adjectives.** 1,300–2,000 characters of numbers, commands and file paths
> is still terse — it is just *long and terse*, like a good commit message body or a man page. It is
> "seamless, powerful, revolutionary" filler that is banned, not length.
> Mechanically this is also just §1a: length is how you buy long-dwell.

**On line breaks:** no study I found measures whitespace. `[UNVERIFIED]` The failure mode in §3d(5)
is real, so the safe form for a technical reader is **short paragraphs (2–4 lines) separated by
blank lines**, not one-sentence-per-line. Code blocks and command lines get their own line — that is
functional, not decorative.

### 4c. Do links kill reach? The folklore is wrong, but not in the way people say

This is the best-evidenced section in the document, because two independent teams ran first-party
studies with synced analytics.

**MagicPost, n = 566,957 posts with synced analytics, June 2026** `[VERIFIED — fetched]`
https://magicpost.in/blog/linkedin-external-links-reach

| Post type | Median impressions | Median likes |
|---|---|---|
| **Attached link preview card** | **414** | 6 |
| No link | 795 | 19 |
| **Raw URL in the post body** | **858** | 20 |
| No link (same comparison) | 786 | 19 |

Their conclusion, verbatim: reach is *"roughly halved, engagement cut to a third"* for attached
preview cards, and **"In-body links are not penalized."**

By account size, attached cards (no-link → with-card):
- under 5k followers: 455 → **266**
- 5k–50k: 1,401 → 726
- 50k+: 9,140 → 3,705

They also note attached links fell from **12.2% of posts in 2022 to 5.6% in 2026** — creators
already adapted.

**Saywhat / Will McTighe, n = 397,605, Q1 2026** `[VERIFIED — fetched the post]`, verbatim:
> *"External links don't kill reach (because they're often valuable). 1–3 links = +43%. More than
> 3 = +441%."*

**van der Blom, n = 1.3M** `[SECONDARY]`: one external link in the body = **−18.8% median reach.**

> **Reconciling the three.** The variable everyone conflated is *the link preview card*, not the
> link. MagicPost's data separates them cleanly and finds the card is the thing that halves reach,
> while a raw in-body URL is neutral-to-slightly-positive. Saywhat agrees that link-rich posts win
> when the links are the point. van der Blom's −18.8% is the smallest penalty claim of the three
> and is not broken out by card-vs-raw.
>
> **Rule for Chute, and it is a big deal:** put the URL **in the post body as raw text and delete
> the auto-generated preview card before publishing.** Do not use "link in first comment" — it is
> `[UNVERIFIED]` in both directions (MagicPost explicitly says *"we did not measure it… treat this
> as a plausible workaround, not a measured one"*, and van der Blom claims link-bearing comments
> lose up to 80% visibility `[SECONDARY]`).
>
> Even in the worst case — take van der Blom's −18.8% at face value — a 19% reach tax on a post
> where the link is the conversion is obviously worth paying. **The folklore that made a generation
> of founders hide their links was measuring the preview card.**

### 4d. Hooks

- **Do not open with a statistic about the size of a problem** — 91% of underperformers do
  (§3e, `[SECONDARY]`).
- **Do not open with "Unpopular opinion" / "I want to share something with you"** — 82% of
  underperformers (§3e, `[SECONDARY]`).
- Saywhat's own prescription, verbatim: *"Hook with your receipts — tell people why they should
  listen to you"* and *"Lead with education. It's the #1 outlier driver."* `[VERIFIED as their claim]`
- LinkPost: quantified proof present in **61% of top-1% posts**; an "open loop" in 47%.
  `[SECONDARY]`

For Chute the receipt-hook writes itself and fits in 140 characters, e.g. the shape:
`"<specific number> <specific action>. <consequence>."` — a measured latency, a file count, a
diff size. Not "Developers waste hours on X."

### 4e. Where the CTA goes

No study I found measures CTA placement. `[UNVERIFIED]` What is evidenced:
- Long posts outperform (§4b) → the CTA lands at the bottom, after the dwell has already happened.
- In-body raw URLs are not penalised (§4c) → the CTA can be a real link, not a "DM me".
- Metricool: **clicks rose 5% while likes/comments/shares fell** (§2c) → clicks are the metric that
  is *growing*. Ask for the click.

Practical form: one line, no emoji, no "check it out", naming the exact command —
`brew install avaluev/chute` reads as an instruction, not an ad, and is copy-pasteable from mobile.

---

## 5. Visuals for a dev-tool founder

### 5a. Specs — official where I could get official

| Thing | Spec | Grade |
|---|---|---|
| **Document/PDF post: file size** | **max 100 MB** | `[VERIFIED]` LinkedIn Help https://www.linkedin.com/help/linkedin/answer/a564109 |
| **Document/PDF post: pages** | **max 300 pages** (also a 1M word cap) | `[VERIFIED]` same source |
| **Document/PDF post: file type** | PDF, on desktop/iOS/Android | `[VERIFIED]` same source |
| Carousel page size | 1080×1080 (square) or 1080×1350 (4:5 portrait) | `[SECONDARY]` — LinkedIn does not publish a recommended page size; this is the near-universal third-party convention |
| Practical slide count | 8–12 (LinkedIn permits far more) | `[SECONDARY]` |
| Single feed image | 1200×1200 (1:1); 1080×1350 (4:5) occupies the most mobile screen | `[SECONDARY]` |
| Image file | PNG for text/graphics, JPG for photos, <10 MB | `[SECONDARY]` |
| Video | MP4/MOV; Socialinsider: optimal **120–180s**, performance drops past 3 min; captions required (muted autoplay) | `[VERIFIED]` for the Socialinsider length finding; `[SECONDARY]` for the file specs |
| **Alt text** | Officially supported: upload image → click **"Alt text"** below it → save. Mobile: tap **ALT**. LinkedIn may auto-assign alt text if you omit it | `[VERIFIED]` LinkedIn Help https://www.linkedin.com/help/linkedin/answer/a519856 |

> **Alt text is not optional and it is not only accessibility.** §1a says content is embedded
> semantically by an LLM encoder. Alt text is machine-readable text you control on an otherwise
> opaque image. Writing "Terminal showing `chute` renaming 340 files in 1.2s" is both the correct
> accessible description and a direct input to the retrieval embedding. Do it on every slide.

Contrast norms worth keeping (`[SECONDARY]`, standard WCAG-derived guidance repeated across the
spec blogs): **≥4.5:1 text/background contrast, no text below ~24pt, keep critical content inside a
central ~880×880 safe area of a 1080×1080 slide.** The 24pt floor matters most — a carousel is read
on a phone at thumbnail size.

### 5b. What the visual should actually be

There is **no study** measuring screenshot vs diagram vs chart on LinkedIn. `[UNVERIFIED]` What the
data does support, indirectly:

- **Documents/carousels beat everything** (§2, three studies agreeing) → the *container* choice is
  settled: a PDF carousel.
- Saywhat's format share of top-1% posts: **infographics 29%, video 26%, quotes 24%, text-only 11%,
  carousels 6%, personal images 6%** `[VERIFIED as their claim]`. Note this measures *share of
  viral posts*, which is confounded by how many people make each format — it is not a per-post
  performance number and should not be read as one. The signal worth taking: **a designed,
  information-carrying still image is the most common shape of an outlier post.**
- Video views fell 36% YoY (§2a) while video posting doubled → **do not build a video pipeline.**

**Concrete visual plan for Chute, derived rather than sourced:**
1. **Terminal capture with real output and a real timing number.** This is Chute's native
   screenshot. Crop tight, large font, dark background, one command and its output. Alt text carries
   the command verbatim.
2. **Before/after of the Finder right-click menu** — the paid half's entire value is visual and
   takes one frame to explain.
3. **A carousel that is a numbered walkthrough of one real problem**, ~8 slides, each slide one
   idea and one image. Slide 1 is the hook (and must work as the feed thumbnail at 1080×1350).
   Last slide is the `brew install` line.
4. **A chart only when you have a real measurement** (install-on-request over time from
   https://formulae.brew.sh/analytics/ , per gtm-tactics.md §6c; a latency comparison). Never a
   chart of a made-up funnel.
5. **Hand-drawn diagrams**: no evidence either way. They read as authentic to technical audiences
   and cost nothing. Low-risk, unmeasured.

---

## 6. Cadence and series design

### 6a. Frequency — the best evidence contradicts the common advice

**Buffer, n = 2,000,000+ posts across 94,000+ accounts** `[VERIFIED — fetched]`
https://buffer.com/resources/how-often-to-post-on-linkedin/
Method: z-score analysis + fixed-effects regression controlling for account-level differences.

| Posts/week | Impressions lift per post | Engagement-rate lift |
|---|---|---|
| 2–5 | **+1,182** | +0.23 pp |
| 6–10 | **+5,001** | +0.76 pp |
| 11+ | **+16,946** | +1.40 pp (≈3× engagements) |

Buffer's data scientist, verbatim: *"these results are consistent no matter your audience size.
Whether you've got 500 followers or 50,000, posting more often makes every single post work
harder."* Their caveat, also verbatim: *"Post as often as you can — as long as the quality stays
high. Low-quality content posted frequently won't yield great results."*

**The conflict.** autoposting.ai `[SECONDARY]` claims daily posting causes a 26% drop in reach per
post and −45% over time from "content fatigue"; van der Blom-derived blogs repeat 2–4×/week.
Buffer's study is an order of magnitude larger, discloses its method, controls for account size, and
is published by a company with no incentive to tell you to post less. **Weight Buffer.**

> **Resolution for Chute: 3–5 posts/week is the floor, not the ceiling, and the binding constraint
> is your own quality bar, not an algorithmic penalty.** A solo founder shipping a product cannot
> write 11 good technical posts a week; 3 is realistic and Buffer's data says 3 beats 1.

### 6b. Timing

**Buffer, n = 4.8M posts, published 2026-07-22** `[VERIFIED — fetched]`
https://buffer.com/resources/best-time-to-post-on-linkedin/
- Best days: **Wednesday > Thursday > Friday.** Worst: **Monday and Tuesday.**
- Best window: **15:00–20:00 weekdays.** Top slots: Wed 16:00, Fri 15:00–16:00.
- **Mornings now underperform** — an explicit reversal of 2025, when peak engagement sat inside
  working hours.
- On the golden hour, verbatim: *"early engagement signals can influence how widely content is
  distributed"* but there is **no officially confirmed 60- or 90-minute window.**

> Note this is a real inversion of the advice in most 2024–2025 playbooks (and of Hootsuite's own
> current page, which still says 04:00–06:00 Tue/Wed). Two sources, same platform, opposite
> answers → treat time-of-day as a **low-stakes** variable. Post when you can be present to reply,
> which is the only first-hour mechanic with a plausible mechanism (each reply is an "active"
> action in §1a's MMoE head).

### 6c. Series design

Direct evidence: **none.** I found no study comparing numbered series ("1/12") against standalone
posts, and no study on optimal series length. `[UNVERIFIED]` Anything claiming otherwise (including
"numbered frameworks outperform generic lists by 20–30%", which circulates widely) is untraceable.

What can be argued from primary sources rather than invented:
- §1a: retrieval is a semantic dual-encoder over a member's last 1,000 impressions. **Topical
  consistency across posts is mechanically advantaged.** A series is a commitment device for
  topical consistency. That is the real argument for a series, and it is a good one.
- §4b: long posts win → each instalment should be a complete 1,300–2,000-character artifact, not a
  cliffhanger fragment. **A "1/12" that withholds the answer trains people to skip you.**
- §3d: technical audiences read format-signalling as marketing. An explicit "1/12" is a format
  signal.

> **Recommendation, marked as judgement not evidence:** run the series thematically without
> numbering the posts. Every post stands alone and is useful if it is the only one someone ever
> reads. If you want continuity, use a consistent trailing line ("Building Chute in public — the
> `brew` numbers are in the README") rather than a counter. Numbering caps your own optionality:
> a "1/12" obliges you to write twelve, and the twelfth will be filler.
> Length: 8–12 posts over 3–4 weeks at 3/week is one product story. Longer and you are repeating
> yourself; a technical audience notices repetition faster than any other kind of reader.

### 6d. Converting LinkedIn attention into a macOS install

Evidence-backed pieces:
- **Post from the personal profile, not a Company Page.** Metricool: personal profiles ~63% higher
  engagement; only 7% of Pages grew a tier. `[VERIFIED]` (§2c)
- **Put the raw URL in the body; kill the preview card.** MagicPost: cards halve impressions, raw
  in-body URLs do not. `[VERIFIED]` (§4c)
- **Optimise for the click, not the reaction.** Metricool: clicks +5% while likes −13%, comments
  −17%, shares −10%. `[VERIFIED]` (§2c)
- **Make the CTA a command, not a page.** `brew install avaluev/tap/chute` is one line, works from
  a phone screenshot, requires no landing page, and is measurable via Homebrew's published
  `install-on-request` analytics (see gtm-tactics.md §6c). **This is the single best
  LinkedIn→product bridge available to Chute** — it converts a read into a measurable install with
  no funnel in between, and it is the free half, so nobody feels sold to.
- Expected magnitude, from §3b: a good technical post from a *known* dev-tool CEO gets ~70
  reactions. A LinkedIn post is worth tens of clicks, not thousands. **Model LinkedIn as ~10–50
  visits per good post at zero followers, not as a launch.** `[UNVERIFIED — this is my estimate
  extrapolated from §3b, not a measured figure. Replace it with your own analytics after 10 posts.]`

Unevidenced but structurally sound: a **LinkedIn newsletter** is the only on-platform push channel
(subscribers get notified/emailed). Aggregators claim 150% YoY growth and 25–50% open rates
`[SECONDARY, untraceable]`. Worth one hour to start once you have ~10 posts of proof, worthless
before.

---

## 7. The recommended plan for Chute

Ordered by evidence strength, not enthusiasm.

**Set-up (one afternoon)**
1. Personal profile only. Headline names the machine-legible topic, not the job title —
   the profile is an input to ranking per §1a ("profile, headline, company, industry").
2. No Company Page for reach. (20 minutes for one, purely as a link target, is fine.)

**Every post**
3. Hook inside **140 characters**, receipt-shaped, no problem-size statistic, no "unpopular opinion".
4. Body **1,300–2,000 characters** — long *and* terse. Numbers, commands, absolute paths.
5. Raw URL in the body. **Delete the preview card.** Never link-in-first-comment.
6. Format: PDF carousel (1080×1350, 8–12 slides, ≥24pt, alt text on every slide) or a tight terminal
   screenshot. Not video.
7. CTA = `brew install avaluev/tap/chute`, last line, no adjective.
8. Be present for the first hour to reply — replies are "active" actions in the real ranker, and it
   is the only golden-hour mechanic with a mechanism behind it.

**Cadence**
9. **3×/week, Wed/Thu/Fri, 15:00–20:00 local-to-audience.** Buffer says more is better; 3 is what a
   solo founder can do at quality. Do not number the posts.
10. One narrow topic for 90 days: macOS tooling for people who run AI coding agents.

**Measurement — set this now or the channel is unfalsifiable**
11. The only numbers that count: (a) `install-on-request` on
    https://formulae.brew.sh/analytics/install-on-request/30d/ , (b) sales, (c) the names of people
    who commented something substantive. **Not followers.** Follower growth is the worst-performing
    metric on the platform (−59% YoY, §1b) and is not what you are here for.
12. After 10 posts, compute your own click-through. Every extrapolation in §6d is mine, not measured.

**Explicitly do not**
- Do not open with a stat about how much time developers waste. (§3e)
- Do not use "seamless / powerful / revolutionary / game-changing / enterprise-ready". (§3c)
- Do not make video. (§2a: views −36% YoY while supply doubled)
- Do not hide the link in the first comment. (§4c)
- Do not treat LinkedIn as a launch channel. Show HN is the launch (gtm-tactics.md §3);
  **LinkedIn is the 90-day compounding credibility asset that makes the second launch easier.**

---

## 8. Open questions I could not resolve

1. **No verifiable solo dev-tool founder LinkedIn case study exists** in what I could reach. This is
   the largest gap and it may mean the channel genuinely underperforms for this ICP relative to
   X/HN — or just that nobody wrote it up. Do not assume the optimistic reading.
2. **Edits after publishing and reposts:** no credible 2025–2026 study found, in either direction.
   Pure folklore.
3. **Hashtags:** no primary evidence. Claims range from "no hashtags is +5–10%" to "10+ hashtags
   is −30–50%" `[SECONDARY, untraceable]`. Freedman's real post used four hashtags and got 20
   reactions; Kulkarni's used none and got 72. n=2 proves nothing.
4. **Time-of-day:** Buffer (n=4.8M, "15:00–20:00, mornings underperform") and Hootsuite
   ("04:00–06:00 Tue/Wed") flatly contradict each other for the same year. Unresolvable from public
   data.
5. **Frequency:** Buffer (n=2M, more is always better) vs autoposting.ai (n=621k, daily posting
   −26%). I weighted Buffer on method and sample, but this is a real, unresolved conflict.
6. **van der Blom's Algorithm Insights 2026** is the most-cited study in this space and is paywalled.
   Every number attributed to it here is second-hand. If LinkedIn becomes a serious channel, buying
   it is the cheapest way to remove the largest block of `[SECONDARY]` tags in this document.
7. **Link in the first comment** remains genuinely unmeasured. MagicPost says so explicitly.
8. **Series/numbering:** no data at all. §6c is reasoning, labelled as such.
9. **LinkedIn newsletter and Article reach:** no large-sample 2026 study found. Mechanism only.
