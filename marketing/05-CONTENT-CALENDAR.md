# Content calendar — Chute

Voice lock: terse, concrete, numbers over adjectives. Never *seamless, powerful, revolutionary,
supercharge, effortlessly*. No invented metrics, no invented testimonials, no fake urgency.
Every row below names the exact asset it ships with — a row with no asset does not get made.

Existing drafts in `/Users/sxope/Documents/2026/Development/37.chute/marketing/03-LAUNCH-POSTS.md`
(X demo post, Show HN, Product Hunt, r/macapps) are **scheduled by reference below, not rewritten** —
two copies of the same claim drift apart the moment one gets edited.

## 1. One wave, app-first

**SUPERSEDED 2026-08-28.** This file used to run two waves: the free CLI carried days 1–8 on its
own, and the paid app followed on day 9. It was the right plan for a product whose paid surface
demonstrated less of the ledger than its free one — which was true until the four Finder actions
landed. It is no longer true, and the two-wave shape had a cost that was always going to be
paid: **eight days of teaching an audience to want the free thing, then asking them for $19.**

One wave now, `App+N` throughout, where **App+0 is the day the notarized DMG and the live Paddle
checkout both exist.** Not one of them — both. A launch post pointing at a Gatekeeper wall, or at
a Buy button that opens nothing, spends the only attention this product gets on a broken funnel.

The CLI has not been demoted in the product, only in the sequence. It stays free, MIT and
complete; it is the hero's second line, the whole of `/cli`, and the answer to every "this should
be free" reply. It re-enters the calendar at App+16 as top-of-funnel, where it belongs.

**If the certificate slips, nothing ships.** That is the deliberate difference from the old plan,
which kept Wave 0 running so something was always going out. Posting CLI content into the silence
before an app launch is how you arrive at App+0 having already spent the audience.

## 2. Day-by-day

| Day | Channel | Asset | Job | Worked if |
|---|---|---|---|---|
| App-1 | Gate day, no post | — | Cold-install on a second Mac: download the DMG, drag, launch, right-click, see the menu. Buy with a real card, receive the key, activate, refund yourself. | Both work first time, on a machine that has never seen this project |
| App+0 | X — launch thread, 6 posts | `demo/out/gui/paste-a-whole-folder-into-your-agent.mov`, reframed | The app, $19, 14-day trial. The CLI is named once, in post 4. | Click-throughs to chutedev.com; first paid conversions |
| App+1 | Show HN | site hero | Title and body reused verbatim from `03-LAUNCH-POSTS.md:18-45` — the two implementation notes are the whole reason the post works. Founder's first comment names the price and the free CLI. | Front page, not flagged; comments engage the implementation notes specifically |
| App+2 | Reddit r/ClaudeAI | `turn-an-answer-back-into-files` demo | Workflow share. Ownership disclosed once, plainly, up front. | Comments describe their own workaround, not just "cool" |
| App+3 | Reddit r/macapps | `which-agent-is-waiting-for-you` demo | A tools post. Price in one line, never the headline. | Net-positive; no unanswered "why should I pay" |
| App+4 | Write-up #1 + X | — | *"Your context menu is drawn by someone else's process"* — the FinderSync/appex boundary | A commenter who ships their own extension recognises it |
| App+5 | Newsletter — TLDR | `brand/out/og.png` | Pitch now the app is real and signed | Editor replies within 7 days |
| App+6 | X | `demo/out/gui/menubar.mov` | The live badge, not a mock | Replies describing their own multi-terminal chaos |
| App+7 | Reddit r/ChatGPTCoding | `unpack` demo | Secondary audience; tests expansion wave 2 | A "does this work with Codex/Cursor" comment |
| App+8 | Write-up #2 + X | — | *"The sandbox container that remembers your old face"* — the appex code-identity trap | Someone quotes the exact error string back |
| App+9 | Newsletter — Ben's Bites | `brand/out/card-sessions.png` | "Your agents shouldn't cost you attention" | Editor replies within 7 days |
| App+10 | YouTube, 4 min | edit of `demo/out/gui/*.mov` | One linkable explainer for the "is there a video" replies | Watch-through past 60 s |
| App+11 | Write-up #3 + X | — | *"The git command that lies about being complete"* — the `checkpoint` bug | A commenter repeats the bug back correctly |
| App+12 | X, 4-card series | `brand/out/quote-1..4.png` | One fact per card, zero adjectives | Each stands alone as a retweet |
| App+13–14 | Buffer, no post | — | Answer every open thread. Confirm PH gallery uploads. | Every top-level objection answered within 24 h |
| App+15 | Product Hunt | `brand/out/og.png` | ≥14 days after Show HN — never the same week | Top 5 for the day; real product questions |
| App+16 | Reddit r/commandline | `demo/out/tree.gif` | **The CLI re-enters here.** A tool share for terminal people, no mention of the app unless asked. | Net-positive; a comment names a command they will run |
| App+18 | Newsletter — Console.dev | `demo/out/tokens.gif` | The CLI-roundup pitch | Editor replies within 7 days |

**The one number to watch in week one:** landing → download. If it is healthy and download →
purchase is not, the page is fine and the product's first run is not — go and fix onboarding,
not the copy. If landing → download is weak, the argument on the page is not landing and the
demos are the first thing to look at, because they are what the argument rests on.

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
