# GTM campaign — Chute

> Rewritten 2026-09-01. The previous calendar scheduled `turn-an-answer-back-into-files.mp4` on
> two separate days and wrote copy around the `unpack` command in four places. That command was deleted
> 2026-08-31; the recording was deleted 2026-09-01 along with the two other phantom demos that
> were still publicly reachable at `chutedev.com/media/`. `site/scripts/check-claims.mjs` now
> scans `marketing/` and `check-cases.mjs` now FAILS on an unreferenced recording, so this class
> of rot cannot get past a deploy again.

**Voice lock:** terse, concrete, numbers over adjectives. Never *seamless, powerful,
revolutionary, supercharge, effortlessly, unlock, elevate, game-changing, blazing fast, 10x* —
enforced by `check:claims`, not remembered. No invented metrics, no invented testimonials, no
fake urgency, no fake scarcity, no countdown timers. **Pain before product: no post opens with a
command name.**

**The assets rule, which is the one that kept this file honest:** every row below names the exact
file it ships with. **A row with no asset does not get made.** Copy is scheduled *by reference*
to `marketing/03-LAUNCH-POSTS.md` and never rewritten here — two copies of a claim drift apart
the moment one is edited.

---

## 0. The three bets this campaign makes

**Bet 1 — one job, not nine.** Every asset leads with *Copy Files as Context*: 17×/day, 150 s → 5 s,
**41.1 min/day**. That single row is over half the app's value. The other four rows are the answer
to "what else", never the opening.

**Bet 2 — go where the ICP already is, not where marketers go.** The buyer runs Claude Code or
Cursor. He is in a terminal, a GitHub repo, an agent's plugin list and two subreddits. He is not
browsing Product Hunt for a context-menu utility. §4 is the aggressive half of this plan and it
is the half the old calendar did not have.

**Bet 3 — the free MIT CLI is the ad, and the app is the product.** Not a contradiction, a
sequence: the CLI proves every number for free, in a terminal, with no trial and no account, and
a person who has run `chute bundle` once has already had the demo. The app sells the thing the
CLI cannot be — the right-click where his hands already are.

---

## 1. PRE-FLIGHT — blocking, none of §2 starts until all of these are true

| # | Gate | Command / proof | State 2026-09-01 |
|---|---|---|---|
| 1 | You can take money | Paddle live, one real card charged and refunded | **not done** |
| 2 | A key actually unlocks | `Sources/ChuteCore/License.swift:28` is a real base64 key, not `REPLACE_ME_BEFORE_RELEASE` | **not done — every buyer's key fails silently until this lands** |
| 3 | The link resolves | `dig +short chutedev.com` returns an address | **not done** |
| 4 | The download is not a scary dialog | Apple Developer enrolment ($99), Developer ID, notarised | **not done** |
| 5 | The numbers are measured, not estimated | `./demo/gui/by-hand.sh` — 3 min, founder only | **not done** |
| 6 | Cold install on a second Mac | Download the DMG, drag, launch, right-click, see the menu. Buy with a real card, receive the key, activate, refund yourself. | — |
| 7 | Every gate green | 911 unit · 172 e2e · 4 metrics · 19 cases · claims · demo lint | **green** |

Runbook for 1–4: `docs/11-PHASE-0-RUNBOOK.md`. **Gate 2 is the one that silently destroys a
launch** — `Scripts/release.sh` now refuses to build past the placeholder, which is the only
reason it cannot ship. Gate 5 is what turns every number in §2 from a claim into a measurement,
and it costs three minutes.

---

## 2. The 30 days

One wave, app-first. `D+0` = launch day. Every row: what ships, the asset path, and **what
"worked" means** — a row with no success criterion is a row nobody can learn from.

| Day | Channel | Asset | The job | Worked if |
|---|---|---|---|---|
| **D−1** | Gate day, no post | — | Pre-flight §1, all seven | All seven pass on a machine that has never seen this project |
| **D+0** | X — launch thread, 6 posts | `site/public/media/paste-a-whole-folder-into-your-agent.mp4` via `demo/reframe.sh` | The wedge, the price, the free CLI in post 4 | Click-throughs to chutedev.com; first paid conversion |
| **D+0** | GitHub repo goes public | `README.md` | The CLI is the ad. Repo description names the ICP, not the category | Stars from accounts that also star agent tooling |
| **D+1** | Show HN | the GitHub repo | **Show the MIT CLI, not the paid app.** HN's rules do not ban commercial products, they ban things a reader cannot play with — so the artifact is `brew install`, and the $19 GUI is disclosed in the founder's own first comment. `03-LAUNCH-POSTS.md` §Show HN **verbatim**. | Front page, not flagged; comments engage the `git stash create` note specifically |
| **D+2** | r/ClaudeAI | `site/public/media/paste-a-whole-folder-into-your-agent.mp4` | Workflow share. Ownership disclosed plainly, first line | Comments describe their own workaround, not just "cool" |
| **D+3** | r/cursor | same, reworded for `@`-mentions | Same job, second tribe | A comment comparing it to typing `@src/` |
| **D+4** | Write-up #1 + X | — | *"Your context menu is drawn by someone else's process"* — the FinderSync/appex boundary | Someone who ships their own extension recognises it |
| **D+5** | Newsletter pitch — TLDR | `brand/out/og.png` | Template in §5 | Editor replies within 7 days |
| **D+6** | X | `site/public/media/which-agent-is-waiting-for-you.mp4` | The live badge, not a mock | Replies describing their own five-terminal chaos |
| **D+7** | r/macapps | `site/public/media/stop-typing-file-paths.mp4` | A tools post. Price in one line, never the headline | Net-positive; no unanswered "why should I pay" |
| **D+8** | Write-up #2 + X | — | *"The sandbox container that remembers your old face"* — the appex code-identity trap | Someone quotes the exact error string back |
| **D+9** | Newsletter pitch — Ben's Bites | `brand/out/card-sessions.png` | "Your agents shouldn't cost you attention" | Editor replies within 7 days |
| **D+10** | YouTube, 4 min | edit of `site/public/media/*.mp4` | One linkable answer to "is there a video" | Watch-through past 60 s |
| **D+11** | Write-up #3 + X | — | *"The git command that lies about being complete"* — the `checkpoint` bug | A commenter repeats the bug back correctly |
| **D+12** | X, 4-card series | `brand/out/quote-1..4.png` | One fact per card, zero adjectives | Each stands alone as a retweet |
| **D+13–14** | Buffer, no post | — | Answer every open thread. Confirm PH gallery uploads | Every top-level objection answered within 24 h |
| **D+15** | Product Hunt | `brand/out/og.png` | ≥14 days after Show HN. **Budget one hour, not one week** — it is worth doing for the high-authority backlink, and rank does not predict revenue (a documented #1 with 612 upvotes converted one customer). Top-of-day needs ~400 supporters in 4 hours, which a founder with no audience does not have. | The backlink is live; any real product question is a bonus |
| **D+16** | r/commandline | `demo/out/tree.gif` | **The CLI re-enters.** A tool share for terminal people; no mention of the app unless asked | Net-positive; a comment names a command they will run |
| **D+18** | Newsletter pitch — Console.dev | `demo/out/tokens.gif` | The CLI-roundup pitch | Editor replies within 7 days |
| **D+21** | Comparison page ships | `/vs` on the site | `repomix`, `files-to-prompt`, `@`-mentions, Raycast — named, linked, and honestly scored, including where they win | Organic traffic on those tool names within 30 days |
| **D+25** | X — the numbers post | the by-hand JSON from gate 5 | "Here is the stopwatch, here is the method, here is where I was wrong" | A correction or a confirmation from someone who ran it |
| **D+30** | Review, in writing | this file | Kill criteria §6 | A decision recorded, not a vibe |

---

## 3. Ready-to-post copy

Lives in `marketing/03-LAUNCH-POSTS.md`. **Do not rewrite it here.** X thread, Show HN, Product
Hunt, r/ClaudeAI, r/macapps and r/commandline are all drafted there, post-for-post.

---

## 4. Distribution inside the ICP's own tool — the aggressive half

> Rewritten 2026-09-01 against `docs/research/gtm-tactics.md`, which replaced the guesses that
> were here with sourced evidence. Ordered by measured return per hour, not by how it feels.

The buyer spends his day inside Claude Code, Cursor and a terminal. Everything in §2 asks him to
leave that and read a post. These do not, and they compound while §2 decays.

**4a. Ship an agent skill. THIS IS THE FIRST THING TO BUILD.** Vercel's open agent-skills
ecosystem (announced 2026-01-20) installs with `npx skills add <owner/repo>` into **17 agents from
one repo** — the changelog names claude-code, cursor, codex, gemini, copilot, windsurf, opencode
and ten more. That list *is* Chute's ICP, reached by one artifact. The top skill on skills.sh has
millions of installs. The CLI is MIT, so the skill costs nothing to give away.
*Do not quote skills.sh's own totals — its 1.35M figure and third-party trackers' 60,788 are
counting different things, and citing either is how a launch gets its first correction.*
~1 day. **Highest-leverage line in this file.**

**4b. Claude Code plugin marketplace, second.** `/plugin marketplace add <owner/repo>` →
`/plugin install`, validated with `claude plugin validate .`. Do it because it buys a paste-able
one-line CTA — **not because it is a traffic source**: there is no browsable public discovery, and
tracked plugins showed 103–326 installs per week in June 2026. ~1 day.

**4c. awesome-list PRs — the highest ROI per hour in the entire plan.** One hour each, permanent,
and they rank. `punkpeye/awesome-mcp-servers` alone carries 93,127 stars. Do all of them.

**4d. Do NOT build an MCP server for distribution.** 9,652–20,222 servers are already listed;
top-directory installs are in the hundreds. Build one only if Chute grows a genuine tool surface a
model should call — which today it does not, because the human is the one holding the mouse.

**4e. `brew install avaluev/tap/chute` is a permanent ad AND your only free measurement.**
Homebrew's analytics record installs from non-private taps and publish them at
formulae.brew.sh/analytics — so top-of-funnel is a number you can read rather than estimate. Every
technical post ends with this line.

**4f. Be the answer to the question they already ask.** `@` + context + "Claude Code" on X,
r/ClaudeAI, r/cursor and the Cursor forum. **Reply with the free CLI line and nothing else** — no
link to the paid page. One reply per thread, ownership disclosed every time, never a DM.

**4g. Publish the deletion.** Six menu rows removed in one afternoon because the ICP's agent
already did those jobs. Unusual, and it earns more trust than any feature list.

**4h. The comparison page (D+21) is SEO, not combat.** repomix (28,148★), gitingest (15,367★),
code2prompt (7,620★), PasteMax (1,173★ — a free GUI doing Chute's exact job), plain `@`-mentions.
Name them, link them, say where they win. repomix wins on packing quality outright: **do not
market on packing quality.** A comparison page that concedes nothing converts nobody.

---

### THE TWO FINDINGS THAT CHANGE THE ARGUMENT

**1. The paid slot is empty, and that is a warning as much as an opening.**
Repo Prompt — the closest paid analogue, a loved native macOS app — stopped charging on
2026-05-27 and open-sourced on 2026-06-13. Its founder wrote: *"it's increasingly challenging to
convince someone that they should pay me $15 a month … when they can just prompt their agent to
solve problems for them, and it 'just works.'"* He also joined OpenAI, so this is a founder-exit
with a market-pressure justification attached, not a clean market verdict — weigh it accordingly.
The only paid survivor found is **16x Prompt at $48 one-time**.

**The distinction to build every asset on: Repo Prompt sold JUDGEMENT — which files matter. Chute
sells MOTION — getting the bytes onto the clipboard.** Judgement is what agents ate. Motion is
not, because the agent is not the thing holding the mouse. Any copy that drifts toward "Chute
picks the right files for you" is walking into the business that just closed.

**2. The answer to "why pay $19 when repomix is free" is Downie.**
A $19.99 one-time GUI over free `yt-dlp`, sold for years to people who know `yt-dlp` exists.
Gruber: *"I use Downie more often than I used yt-dlp, because it's so much easier."* **Frequency,
not capability, is the product** — 17 times a day is the argument, and it is the same argument as
the wedge. Counter-evidence, and it will be quoted at you: HN has called comparable tools
"literally a paid wrapper around a completely free program." Answer it with the frequency number
and the free CLI, never with a claim of extra capability.

**Price is safe.** The one-time band for indie macOS dev tools runs Paletro $6.99 · Rectangle Pro
$9.99 · Downie $19.99 · Bartender 6 $20 · CleanShot X $35 · Keyboard Maestro $36 · Hazel $42 ·
16x Prompt $48 · Proxyman $89 · TablePlus $99. $19 sits inside the single-gesture band. The
closest working comparable is **Lunar** — solo macOS utility, $23 lifetime, ~$108K in customer
payments in 2023, sold through Paddle; its author's channels were thoughtful HN posts, r/macapps,
a PH launch per major version, and one technical post at 30k views. On paid ads he wrote:
*"thousands of dollars down the drain."* **No ads.**

## 5. Direct outreach

**Newsletter pitch, one template, four sends** (D+5 TLDR, D+9 Ben's Bites, D+18 Console.dev, and
one reserve). Three sentences: what it does, who for, the number. One link. One image attached,
not embedded. No follow-up before day 7, exactly one follow-up ever.

> Subject: A Finder right-click that hands your coding agent the files
>
> I build Chute — a 3.0 MB macOS utility for people who drive Claude Code all day. Select
> folders in Finder, right-click once, and every file inside is on the clipboard as one blob
> with a token count. I timed my own day at ~80 minutes going into that pointing.
> The CLI half is MIT and free: `brew install avaluev/tap/chute`.
> chutedev.com — happy to send a build.

**No cold DMs. No influencer gifting. No paid placement before D+30** — you cannot tell whether
paid works until you know what organic does.

---

## 6. Metrics, and the kill criteria

| Metric | Where | Means |
|---|---|---|
| Download → first Finder action | onboarding beat 3 | **The activation event.** If they right-click once, they keep the app |
| `Copy Files as Context` share of all actions | — | Confirms the wedge. If it is not #1, the whole campaign leads with the wrong row |
| Basket usage among activated users | — | Answers the open question in `handoff/NEXT.md`: keep it or delete it |
| Trial → paid | Paddle | The only number that ends the argument |
| Refund rate > 5 % | Paddle | Positioning overpromises — fix the landing page, not the price |

**Kill criteria, decided now, in writing, so they are not re-litigated at D+30 with a stake in
the ground:**

- **< 5 paid at D+30** with front-page HN → the price is not the problem and the copy is not the
  problem. The job is not painful enough to pay for. Keep the CLI, stop the campaign.
  *Calibrate before panicking:* one documented Show HN reached the front page, 6,000 views and
  **zero sales**, and its author's own post-mortem blamed the title for sounding "too producty."
  Front page is not the outcome; it is the impression at the top of a funnel that converts at
  1–3% for developer tools. And **nobody publishes a first-party CLI→GUI conversion rate** — not
  Kaleidoscope, Proxyman, TablePlus, Dash, Warp or Raycast. At 1–3% and $19, a thousand CLI
  installs is $190–570. **Treat the free CLI as credibility, not as a funnel, until the Homebrew
  analytics show five figures.**
- **Activation < 40 %** → they downloaded and never right-clicked. Onboarding, not marketing.
- **Refunds > 10 %** → a claim on the page is not true in the product. Find it before posting again.
- **Basket unused by activated users at D+30** → delete the row, as its six predecessors were.

---

## 7. Rules against spam

- Ownership disclosed in the first line of every post, every time, without being asked.
- One post per subreddit per launch. Never cross-post the same text.
- Never reply to a competitor's thread with a link.
- Never seed a "has anyone tried" question.
- No testimonial that a real person did not write and approve.
- No number that is not in `site/src/lib/cases.ts` and derived from the ledger.
- If a thread goes negative on a true point, agree with it publicly and fix the product.

---

## 8. After day 30 — the engine, if it lived

One technical write-up a fortnight, from work actually done. One release note per shipped change.
Nothing else. **The campaign is a spike; the write-ups are the engine** — they still bring people
in at day 200, and a launch does not.
