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
| **D+1** | Show HN | site hero | `03-LAUNCH-POSTS.md` §Show HN **verbatim** — the deletion story and the two implementation notes are why the post works | Front page, not flagged; comments engage the `git stash create` note specifically |
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
| **D+15** | Product Hunt | `brand/out/og.png` | ≥14 days after Show HN — never the same week | Top 5 for the day; real product questions |
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

The buyer spends his day inside Claude Code and a terminal. Everything in §2 asks him to leave
that and read a post. These do not, and they compound while §2 decays.

**4a. Ship a Claude Code plugin / skill for `chute`.** The ICP's agent already reads a plugin
list. A skill that teaches the agent to call `chute bundle` when a user says "give yourself the
whole folder" puts the product's name in front of the exact person, inside the exact tool, at the
exact moment. The CLI is MIT, so this costs nothing to give away and it is the highest-leverage
line in this file. **Design it before building it** — see the standing note on custom actions in
`handoff/NEXT.md`; the same "is this a platform now?" question applies.

**4b. Be the answer to the question they already ask.** Search `@` + context + "Claude Code" on
X, r/ClaudeAI, r/cursor and the Cursor forum. People describe this exact friction weekly and get
no good answer. **Reply with the free CLI line and nothing else.** No link to the paid page, no
pitch — the tool IS the pitch, and a person who runs `chute bundle` once has had the demo. Cap:
one reply per thread, disclose ownership every single time, never DM.

**4c. `brew install avaluev/tap/chute` is a permanent ad.** It is live and it works. Every
technical post ends with it; it costs the reader nothing, it needs no trial, and it makes the
80.7-minute claim checkable in about forty seconds — which is a far better argument than any
sentence on the landing page.

**4d. Publish the deletion.** Six menu rows removed in one afternoon because the ICP's agent
already did those jobs. That is a genuinely unusual post and it earns more trust than any feature
list — it says out loud that this product has a specific user and is not trying to be everything.
It is post 5 of the launch thread and the spine of the Show HN.

**4e. The comparison page (D+21) is SEO, not combat.** `repomix`, `files-to-prompt`, plain
`@`-mentions. Name them, link them, and say where they win — `repomix` is free, cross-platform,
and scriptable, and someone who wants that should use it. A comparison page that never concedes
anything converts nobody and ranks badly.

---

## 5. Direct outreach

**Newsletter pitch, one template, four sends** (D+5 TLDR, D+9 Ben's Bites, D+18 Console.dev, and
one reserve). Three sentences: what it does, who for, the number. One link. One image attached,
not embedded. No follow-up before day 7, exactly one follow-up ever.

> Subject: A Finder right-click that hands your coding agent the files
>
> I build Chute — a 2.5 MB macOS utility for people who drive Claude Code all day. Select
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
