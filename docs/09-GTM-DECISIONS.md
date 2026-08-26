# GTM decisions — Chute

The nine models, answered for this product rather than described. Written 2026-08-26.

---

## The one that matters most right now: 4️⃣ Assumption Mapping

Not because the others are weak — because Chute has a riskiest assumption we already have
**evidence against**, and every other model is premature until it is settled.

| # | Assumption | Risk if false | Evidence today | Test |
|---|---|---|---|---|
| **A1** | **A stranger can install Chute and see the menu** | **Fatal — nothing else matters** | **Negative.** The founder, holding the source, a compiler and an agent, could not make the context menu appear across three attempts and several hours | The onboarding module. Test on a second Mac, cold. |
| A2 | The pain is worth paying to remove | Product is a free toy | Strong-ish: 90–120 min/day measured, but measured on one person | 20 ECP users, ask for money |
| A3 | Bundling is the wedge, not paths | Wrong headline, wrong demo | None | Instrument which command gets used |
| A4 | $9 is the right number | Leaves money or volume | None | Price test at $9 vs $19 |
| A5 | They can be reached cheaply | No distribution | None | Bullseye ring 1 |

**A1 is not a UX nicety. It is the business.** A product whose core feature is invisible on
arrival has a conversion rate of zero regardless of how good the engine is — and this engine is
now 116 verified assertions strong, which is exactly the trap: quality nobody reaches.

This is why the onboarding module is being specced as a first-class subsystem and not as polish.

---

## 1️⃣ Beachhead

**Not** "AI builders" — too broad to win.

> **Solo and small-team developers who run three or more CLI coding agents at once on macOS,
> on a single screen.**

Why this one wins first: the pain is daily, self-evident, and currently unserved. The founder's
own machine — 8 Terminal windows, 5 running `claude`, no way to tell which needs a human — is
the segment's defining image.

Expansion waves, in order:
1. Beachhead: multi-agent solo devs on macOS
2. → any Claude Code / Cursor / Codex user on macOS (context bundling alone justifies it)
3. → macOS developer power users generally (the CLI stands alone)
4. → teams, with shared rule templates

## 2️⃣ Market Score

Scored 1–5 on pain, frequency, reachability, willingness to pay, ability to serve.

| Segment | Pain | Freq | Reach | WTP | Serve | Total |
|---|---|---|---|---|---|---|
| **Multi-agent solo devs (macOS)** | 5 | 5 | 4 | 3 | 5 | **22** |
| Single-agent devs | 3 | 4 | 4 | 3 | 5 | 19 |
| Enterprise dev teams | 4 | 5 | 1 | 5 | 2 | 17 |
| General Mac power users | 2 | 3 | 3 | 3 | 4 | 15 |

Enterprise scores highest on money and lowest on everything that matters at zero users:
unreachable without a sales motion, and unservable without MDM deployment and a security review.
It is wave 4, not wave 1.

## 3️⃣ ECP vs ICP

**ECP (early customer profile) — who buys the next 20 copies:**
Already complains publicly about agent context juggling. Tolerates an unsigned build, a
Terminal.app-only limitation, and manual permission grants. Wants the **CLI** most.

**ICP (ideal customer profile) — who buys the 2,000th:**
Wants it to just work. Uses Ghostty or iTerm2. Expects a signed DMG, auto-update, and zero
terminal interaction.

**The discipline:** do not build for the ICP yet. Notarization, multi-terminal adapters and
auto-update are all ICP requirements. Building them now spends the budget before a single
person has confirmed the premise. **The ECP's rough edges are affordable; the ICP's polish is not.**

## 5️⃣ Pricing Research

Nobody prices in isolation — they rank you against what they already know.

| Anchor | Price | Where Chute sits |
|---|---|---|
| Shell script they could write | free | "I could build this" — the real competitor |
| New File Menu | ~$3 | Chute does vastly more |
| QSpace Pro | ~$14 | Chute is a companion, not a replacement |
| PopClip | ~$17 | Nearest analogue: small, beloved, one-time |
| iBoysoft MagicMenu | $30/yr | The subscription Chute defines itself against |
| Raycast Pro | $8/mo | Different category, similar buyer |

**$9 one-time.** Below PopClip so the comparison flatters, decisively not a subscription, and
framed against the only number that matters: **less than one hour of the 90–120 minutes a day it
returns.** Revisit at v1.0 when signed and auto-updating — that is when $19 becomes defensible.

## 6️⃣ Positioning and Messaging

One story: **your agents should not cost you attention.**

| Audience | What they hear |
|---|---|
| Running 5 agents at once | "Know which one needs you, without hunting windows" |
| Juggling context by hand | "Eight files, one paste, with the token count" |
| Burned by subscriptions | "One payment. Offline. No account. 328 KB." |
| Nervous about a repo | "Every destructive command previews first" |

Different entry points, one conclusion. Never say "powerful", "seamless", or "revolutionary" —
the demo carries the claim or nothing does.

## 7️⃣ Bullseye — three channels, not thirty

**Inner ring (do these):**
1. **A 20-second demo video on X.** The demo *is* the ad. Zero cost, and the artefact doubles as
   the landing page hero.
2. **Show HN, led with the engineering war stories** — `git stash create` silently excluding
   untracked files; APFS case-insensitivity letting a CLI overwrite an app binary;
   `pgrep -x Terminal` never matching Terminal.app. HN rewards specific, verifiable technical
   honesty far more than it rewards a product pitch.
3. **r/ClaudeAI and r/macapps** — the beachhead segment is literally reading these.

**Deliberately not yet:** Product Hunt (an unsigned download destroys conversion — go after
notarization), paid ads (no funnel to spend against), SEO/content (months of lag), Setapp (revenue
share on an unvalidated product).

## 8️⃣ Experimentation Loop — and the tension we must resolve

The model says the best experiments come from interpreting collected intelligence rather than
inventing ideas. **Chute collects nothing. That is a deliberate promise: zero telemetry, offline,
no account.**

That promise is a genuine asset with this audience and must not be quietly broken. Resolution:

- **Instrument the website, not the app.** Download counts, landing → download conversion.
- **Local-only counters with an explicit "copy my stats" button.** The user decides, every time.
  Never automatic, never background.
- **Qualitative beats quantitative at n=20.** Twenty conversations tell you more than any funnel.

Any proposal that adds silent telemetry is rejected on positioning grounds, not just ethical ones.

## 9️⃣ Lean Analytics — retention is the PMF signal

The one number that matters: **is it still being used in week 4?**

| Metric | Target | How, without telemetry |
|---|---|---|
| Install → first successful command | > 80 % | Onboarding self-report during ECP phase |
| Time to first win | < 60 s | Measured directly with ECP users, watching |
| Commands/day by day 7 | > 20 | Local counter, voluntarily shared |
| **Week-4 retention** | **> 40 %** | Ask. Twenty people is a phone call each. |
| Refund rate | < 5 % | Store dashboard |

Below 40 % week-4 retention, the honest conclusion is that the pain is real but the habit is not,
and the answer is a better product — not more marketing.

---

## What this means for the build, concretely

1. **Onboarding is now a first-class subsystem**, ahead of Tasks 7–9 in priority, because it tests
   assumption A1 — the only one that is currently failing.
2. **Do not build ICP features** (notarization, iTerm2/Ghostty adapters, auto-update) until 20 ECP
   users exist.
3. **The demo video is a deliverable, not marketing collateral** — it is simultaneously the ad,
   the landing hero, and the onboarding's own "this is what success looks like" reference.
