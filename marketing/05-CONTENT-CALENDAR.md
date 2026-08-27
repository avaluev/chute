# Content calendar — Chute

Voice lock: terse, concrete, numbers over adjectives. Never *seamless, powerful, revolutionary,
supercharge, effortlessly*. No invented metrics, no invented testimonials, no fake urgency.
Every row below names the exact asset it ships with — a row with no asset does not get made.

Existing drafts in `/Users/sxope/Documents/2026/Development/37.chute/marketing/03-LAUNCH-POSTS.md`
(X demo post, Show HN, Product Hunt, r/macapps) are **scheduled by reference below, not rewritten** —
two copies of the same claim drift apart the moment one gets edited.

## 1. The two waves

**Wave 0 — day 2 — the free CLI.** Repo public, `brew install avaluev/tap/chute` live. Costs
nothing, needs no Apple certificate, and can start the moment this file is committed. It carries
days 1–8 on its own: CLI demos, a newsletter pitch, one technical write-up, two subreddits.

**Wave 1 — day 9 — the paid app. BLOCKED on the Apple Developer ID / notarization**
(`/Users/sxope/Documents/2026/Development/37.chute/handoff/NEXT.md`, NEXT §1). Every Wave 1 row
below is labelled `App+N` — days since the notarized build actually ships — instead of a fixed
date. **If the certificate slips, Wave 0 does not stall**: keep posting CLI content and technical
write-ups on the fixed Day-N cadence, and let every `App+N` row slide as one block behind it. Show
HN and Product Hunt both belong to Wave 1 (the war stories are about the signed app); Product Hunt
is `App+15`, which keeps it ≥ 14 days after Show HN — never the same week, per
`/Users/sxope/Documents/2026/Development/37.chute/docs/09-GTM-DECISIONS.md` §7.

## 2. Day-by-day

| Day | Channel | Asset | Job | Worked if |
|---|---|---|---|---|
| 1 | Infra (no post) | n/a | Repo public, tap live: `brew install avaluev/tap/chute` | Install succeeds on a clean Mac, `chute doctor` reports 9/9 |
| 2 | X/Twitter — Wave 0 launch | `/Users/sxope/Documents/2026/Development/37.chute/demo/out/bundle.gif` | Announce the CLI is free, MIT, forever | Replies ask "is there an app"; no unanswered "just a shell script" |
| 3 | Reddit r/commandline | `/Users/sxope/Documents/2026/Development/37.chute/demo/out/tree.gif` | Put 28 commands in front of terminal power users, as a tool share not an ad | Net-positive score; a comment names a command they'll actually run |
| 4 | Newsletter — Console.dev | `/Users/sxope/Documents/2026/Development/37.chute/demo/out/tokens.gif` | Pitch a one-line mention in a CLI-tool roundup | Editor replies yes or no within 7 days |
| 5 | X/Twitter | `/Users/sxope/Documents/2026/Development/37.chute/demo/out/sessions.gif` | Preview "which agent is waiting" — no ship date promised | Replies asking "when can I buy this" |
| 6 | Technical write-up #1 + X cross-post | `/Users/sxope/Documents/2026/Development/37.chute/demo/out/checkpoint.gif` | Publish war story 1 (§4) | Referral clicks once linked from HN/X later; a comment repeats the bug back correctly |
| 7 | Reddit r/macapps | `/Users/sxope/Documents/2026/Development/37.chute/demo/out/ports.gif` | Schedule 03's r/macapps draft (reference, not rewritten) — reach Mac-tool readers while the app waits on the cert | Net-positive score; no pile-on left unanswered on "why no notarized build yet" |
| 8 | Gate day (no post) | n/a | Check Developer ID status. If issued: shoot the 4 GUI recordings — `cd /Users/sxope/Documents/2026/Development/37.chute/demo/gui && ./record.sh all` | 4 files exist at `/Users/sxope/Documents/2026/Development/37.chute/demo/out/gui/{bundle,menubar,hotkey,ports}.mov` |
| 9 / App+0 | X/Twitter — Wave 1 launch thread | `/Users/sxope/Documents/2026/Development/37.chute/demo/out/gui/bundle.mov`, reframed via `/Users/sxope/Documents/2026/Development/37.chute/demo/reframe.sh` to `.../demo/out/social/bundle-square.mp4` | Announce the $19 notarized app, 14-day trial | Click-throughs to chutedev.com; first paid conversions |
| 10 / App+1 | Show HN | site hero = `/Users/sxope/Documents/2026/Development/37.chute/demo/out/bundle.gif` | Schedule 03's Show HN draft verbatim (title + body, §3-D below) | Front page, not flagged; comments engage the two implementation notes specifically |
| 11 / App+2 | Reddit r/ClaudeAI | `/Users/sxope/Documents/2026/Development/37.chute/demo/out/bundle.gif` | New post (§3-E) — reach the beachhead segment already complaining about context juggling | Comments describe their own workaround, not just "cool" |
| 12 / App+3 | Reddit r/ChatGPTCoding | `/Users/sxope/Documents/2026/Development/37.chute/demo/out/unpack.gif` | Same workflow share, secondary audience | A "does this work with Codex/Cursor" comment (tests expansion wave 2) |
| 13 / App+4 | Technical write-up #2 + X cross-post | `/Users/sxope/Documents/2026/Development/37.chute/demo/out/doctor.gif` | Publish war story 2 (§4) | A commenter quotes the exact error string back — proof someone else hit it |
| 14 / App+5 | Newsletter — TLDR | `/Users/sxope/Documents/2026/Development/37.chute/brand/out/og.png` | Pitch the broad dev-newsletter audience now the app is real and signed | Editor replies within 7 days |
| 15 / App+6 | X/Twitter | `/Users/sxope/Documents/2026/Development/37.chute/demo/out/gui/menubar.mov` (reframed) | Show the live menu-bar badge, not a mock | Replies describing their own multi-terminal chaos |
| 16 / App+7 | Newsletter — Changelog | link to write-up #1, no image | Pitch the dev-tooling podcast/newsletter on the open-core CLI angle | Editor replies within 7 days |
| 17 / App+8 | Technical write-up #3 + X cross-post | `/Users/sxope/Documents/2026/Development/37.chute/demo/out/gui/bundle.mov` (reframed) | Publish war story 3 (§4) | A reply from someone who ships their own Finder/Services extension |
| 18 / App+9 | YouTube, 4 min | edit of `/Users/sxope/Documents/2026/Development/37.chute/demo/out/gui/*.mov` via `.../demo/reframe.sh`, output `.../demo/out/social/bundle-wide.mp4` | One linkable explainer for the "is there a video" comments piling up on HN/Reddit | Watch-through past 60 s in YouTube Studio (first-party, no telemetry conflict) |
| 19 / App+10 | Newsletter — Ben's Bites | `/Users/sxope/Documents/2026/Development/37.chute/brand/out/card-sessions.png` | Pitch the AI-tooling audience on "your agents shouldn't cost you attention" | Editor replies within 7 days |
| 20 / App+11 | X/Twitter, 4-tweet mini-series | `/Users/sxope/Documents/2026/Development/37.chute/brand/out/quote-1.png` .. `quote-4.png` | One fact per card (90–120 min/day, 328 KB, 28 commands, no telemetry) — zero adjectives | Each stands alone as a retweet with no added context needed |
| 21 / App+12 | Buffer (no new post) | n/a | Answer every open thread from days 9–20; the "should be free" and "I'll write a shell script" replies (§5) | Every top-level objection has a reply within 24 h of the original post |
| 22–23 / App+13–14 | Buffer (no post) | n/a | Confirm PH gallery images are uploaded: `/Users/sxope/Documents/2026/Development/37.chute/brand/out/og.png` + the four `card-*.png` | PH's own listing preview passes |
| 24 / App+15 | Product Hunt | `/Users/sxope/Documents/2026/Development/37.chute/brand/out/og.png` | Schedule 03's PH tagline + description + first comment verbatim | Top 5 for the day; comments ask real product questions, not just upvote-and-run |

`App+15` sits 14 days after `App+1` (Show HN) — satisfies "never the same week" with one day of
slack. If Wave 1 slips, Wave 0's days 1–8 rhythm (one CLI post every 1–2 days, one write-up) is
what keeps running; nothing here depends on the app existing until day 9.

## 3. Ready-to-post copy

### A — X/Twitter, Wave 0 launch (day 2)
> The Chute CLI is free, MIT, forever:
>
> `brew install avaluev/tap/chute`
>
> 28 commands. Select files in Finder, bundle their contents into one blob with a token count.
> Paste an agent's multi-file answer back into real files. Snapshot a repo before an agent runs.
>
> Zero dependencies. Zero telemetry. No account. 328 KB.
>
> The Finder menu and menu-bar switcher (Chute.app) are next, priced separately.
>
> [attach: bundle.gif]

### B — Reddit r/commandline (day 3)
**Title:** Wrote a 28-command CLI for people who bundle files for an LLM by hand every day (free, MIT, `brew` tap)
> I run coding agents most of the day and kept doing the same four things by hand: copying paths
> into a prompt, bundling several files into one message, unpacking a multi-file answer back onto
> disk, and snapshotting a repo before letting an agent loose in it.
>
> `chute` is the CLI I wrote for that. `chute bundle src/ --format xml` gives you every file's
> contents in one blob with a token estimate. `chute unpack` turns fenced code blocks in your
> clipboard back into a real file tree — previews by default, writes with `--force`. `chute
> checkpoint .` snapshots everything, including untracked files, without touching your real git
> index.
>
> 28 commands total, all covered by an e2e suite. Zero dependencies, zero network calls except
> the gist command, no account.
>
> `brew install avaluev/tap/chute` — MIT, free forever. Repo: github.com/avaluev/chute. Happy to
> answer questions about any of the commands.

### C — X/Twitter, Wave 1 launch thread (day 9 / App+0), 6 posts
**1/6** — reuse `/Users/sxope/Documents/2026/Development/37.chute/marketing/03-LAUNCH-POSTS.md:4-16`
verbatim (the "I run coding agents ~10h/day" post). Do not rewrite it.
> **2/6** Claude Code already reads your files. It cannot see your Finder selection, your
> clipboard, the terminal you lost, or the port you can't find. That gap is what Chute closes.
>
> **3/6** Chute.app adds the Finder menu (right-click → bundle, unpack, tree, paths) and a menu
> bar that shows which of your agents is waiting on you — colour-coded per project, one click to
> bring that terminal forward.
>
> **4/6** $19 one-time, 14-day free trial. No subscription, no account. The 28-command CLI stays
> free and MIT forever either way — the app buys you the Finder menu and the menu bar, nothing else
> is paywalled.
>
> **5/6** Every destructive command previews before it acts. `unpack` refuses to write outside its
> target directory. `checkpoint` builds a snapshot without ever touching your real git index or
> worktree.
>
> **6/6** macOS 13+. 328 KB. Zero telemetry — the only network code is the gist command, and only
> when you run it yourself. chutedev.com

### D — Show HN (day 10 / App+1)
**Title (verbatim, reuse):** Show HN: Chute – Turn a Finder selection into agent-ready context
**Body:** reuse `/Users/sxope/Documents/2026/Development/37.chute/marketing/03-LAUNCH-POSTS.md:18-45`
verbatim — do not rewrite the two implementation notes; they are the whole reason this post works
on HN. New for this slot, the founder's own first comment once the thread is live:
> Founder here. The app (Finder menu + menu bar) is $19 one-time with a 14-day trial; the CLI
> underneath it is MIT and free — `brew install avaluev/tap/chute` if you just want the 28
> commands. Ask me anything about the sandboxing, the notarization process, or the two bugs above.

### E — Reddit r/ClaudeAI (day 11 / App+2)
**Title:** How I stopped hand-bundling files for Claude Code (built a small tool, sharing the workflow)
> I run 3–5 `claude` sessions at once and the part that actually ate my time wasn't the model, it
> was getting context to it: selecting files in Finder, copying paths one at a time, or
> hand-assembling a "here are 8 files" message.
>
> What I use now: select the files in Finder, right-click → Bundle Context, and I have one XML
> blob with a token count on the clipboard, ready to paste into Claude Code. When Claude answers
> with several files, right-click → Unpack Markdown Here writes them back to disk (it previews the
> file list first — I don't want anything writing blind into a repo).
>
> It's a macOS thing I built (Chute), not affiliated with Anthropic. CLI is free/MIT
> (`brew install avaluev/tap/chute`); the Finder integration is a $19 one-time app with a 14-day
> trial. Posting because the bundling workflow specifically might save you the same 15–20
> times-a-day of tab-hopping it used to cost me — curious if others have solved this differently.

### F — Newsletter pitch email (generic template, days 4/14/16/19)
**Subject:** A 328 KB macOS CLI for people running Claude Code / Codex all day
> Hi [name],
>
> Chute is a free, MIT command-line tool (`brew install avaluev/tap/chute`) for people who run
> coding agents most of the day. It bundles a Finder selection into one paste-ready blob with a
> token count, unpacks a multi-file agent answer back into real files, and snapshots a repo before
> an agent runs — 28 commands, zero dependencies, zero telemetry, no account.
>
> There's a paid macOS app on top (Finder menu + menu-bar agent-status switcher, $19 one-time,
> 14-day trial) but the CLI stands alone and is what I'd suggest linking if you cover dev tools.
>
> Repo: github.com/avaluev/chute · Site: chutedev.com. Happy to answer anything about the
> implementation — the sandboxed Finder extension in particular has some genuinely weird macOS
> behavior behind it.
>
> [name]

## 4. Three technical write-ups

All three are drawn from `/Users/sxope/Documents/2026/Development/37.chute/handoff/NEXT.md` §TRAPS
— real bugs that cost real hours, not manufactured "engineering content."

1. **"Your context menu is drawn by someone else's process"** — the FinderSync/appex boundary.
   Covers: `representedObject` does not survive the trip to Finder (a FinderSync menu is drawn by
   Finder itself; only plain properties like `tag` cross that boundary, so dispatching on
   `representedObject` made every menu item a silent no-op), and why menu icons ship as
   pre-rendered bitmaps rather than SF Symbols — a symbol's rendering configuration dies at the
   same boundary (see commits `d32268b`, `bb817e0` in this repo). One action table
   (`ChuteCore/FinderActions.swift`) now feeds the menu, the app, and the tests, because two
   copies had already drifted.

2. **"The sandbox container that remembers your old face"** — the appex code-identity trap. A
   sandboxed extension's container ACL pins the code identity that created it; after any re-sign,
   macOS refuses to launch it (`(AppSandbox) code identity <cdhash> not in ACL for container`)
   while `pluginkit` still happily reports it registered and enabled — so the menu vanishes with
   no error anywhere a normal person would look. The fix order matters: delete the container,
   `pluginkit -r`, relaunch the host app, `pluginkit -a`, `-e use`, restart Finder — clearing the
   container alone is not enough. This is the exact failure mode that makes "just re-sign it" the
   wrong instinct for anyone shipping a sandboxed Finder/Services extension.

3. **"The git command that lies about being complete"** — the `checkpoint` bug. `git stash create`
   looks like the right primitive for a non-destructive snapshot: it builds a commit from the
   working tree without touching `HEAD`, the index, or the worktree. It also silently excludes
   untracked files — exactly the files an agent tends to create. The fix points `GIT_INDEX_FILE`
   at a temp file, `git add -A` against that private index, then `write-tree` + `commit-tree`:
   a full snapshot, the real index never touched. Found only because a test asserted the wrong
   thing and failed loud instead of green.

## 5. Rules against spam

**Per-subreddit framing**
- r/ClaudeAI, r/ChatGPTCoding — a workflow share from someone who uses these agents daily, never
  "check out my app." Disclose ownership up front, once, plainly.
- r/macapps — a tools post. Lead with what it does, not the price. Mention $19/CLI-free in one
  line, not the headline.
- r/commandline — the CLI only. No mention of the paid app unless someone asks; this audience
  wants the free tool, not a pitch.

**Never post**
- The same link to the same subreddit twice. No cross-posting the identical text to more than one
  sub in the same week.
- A reply that argues. Every objection gets one factual answer, then silence.
- "Limited time," a countdown, a fake stock number, or a manufactured deadline anywhere.
- A screenshot as the only content — always ship a real GIF/video asset (§2) or working code.

**"This should be free"**
> The CLI is free, MIT, forever — `brew install avaluev/tap/chute`. The $19 buys the sandboxed
> Finder extension and the menu bar, which is the part that took the actual engineering (see the
> write-ups). You can use the whole thing without ever paying anything.

**"I'll write a shell script"**
> You will write four, forget the flags, and never handle binaries, token counts, or path
> traversal. 14-day free trial if you want to compare it to what you'd actually ship.

**"Unsigned / why no notarization yet"** (only relevant before App+0)
> Fair — the CLI is unsigned by nature (it's a script you can read). The app is notarized before
> it ships; that's why there's no download link for it yet.
