# LinkedIn — the 90-day series

> Written 2026-09-01 from `docs/research/linkedin.md` (711 lines, 40 [VERIFIED] / 16 [UNVERIFIED]).
> Every rule below carries the evidence that produced it. Where the research found a flat
> contradiction it says so rather than picking the flattering side.

## What LinkedIn is for, and what it is not

**It is not the launch.** Show HN is the launch (`docs/research/gtm-tactics.md` §3). LinkedIn is
the 90-day compounding credibility asset that makes the *second* launch easier.

**Calibrate now, or you will read a good post as a failure.** The research could not find a single
verifiable solo dev-tool founder LinkedIn case study with published numbers — that gap is itself a
finding, and the optimistic reading is not the safe one. The one real calibration it did find:
three posts from a funded Postgres company, written by its CTO and CEO, got **20, 42 and 72
reactions**. It also caught a widely-circulated "1,131 likes" example that matches no real post and
flagged it as fabricated. **Twenty substantive reactions from developers is a good post.**

---

## THE RULES — nine, each with its receipt

1. **Hook inside 140 characters.** Mobile truncates at ~140, desktop at ~210. The first line is
   the entire ad. `[VERIFIED]`
2. **Body 1,300–2,000 characters.** AuthoredUp, n=372,126: 1,301–2,500 chars → 2.61% engagement and
   1,174 impressions, against 2.10% / 575 for posts under 400. **Long *and* terse** — that is not a
   contradiction, it is six short paragraphs instead of one padded one. `[VERIFIED]`
3. **Raw URL in the body. Delete the preview card.** MagicPost, n=566,957: an attached preview card
   *halves* impressions (414 vs 795); a raw in-body URL is not penalised (858 vs 786). Saywhat,
   n=397,605: 1–3 links = +43%. **Link-in-first-comment is explicitly unmeasured — do not use it.**
   `[VERIFIED]`
4. **PDF carousel is the default format.** #1 in all three independent studies (Socialinsider 7.00%,
   Buffer 21.77% median, Metricool 1,451 impressions/post vs 605 for video). `[VERIFIED as their
   claims]`
5. **Do not make video.** Views fell **36% YoY while video posting doubled**. Building a video
   pipeline is spending the scarcest thing you have on the one format going backwards. `[VERIFIED]`
6. **Personal profile, never a Page.** Metricool: profiles ~63% higher engagement; only 7% of Pages
   grew a tier. `[VERIFIED]`
7. **One narrow topic for 90 days.** LinkedIn's retrieval is now an LLM dual-encoder (arXiv
   2602.12354 + their Mar-2026 engineering blog), so topical consistency is *mechanically*
   advantaged, not just good advice. The topic: **macOS tooling for people who run AI coding
   agents.** `[VERIFIED]`
8. **Be there for the first hour and reply.** The ranker is an MMoE head predicting passive (click,
   long-dwell, skip) and active (like, comment, share) outcomes. Replies are active actions. This is
   the only "golden hour" mechanic with an actual mechanism behind it. `[VERIFIED]`
9. **3×/week, Wed–Fri, 15:00–20:00.** Buffer (n=2M) says more is always better and confirms it holds
   at 500 followers; autoposting.ai (n=621k) says daily is −26%. **A real, unresolved conflict** —
   3 is what one person can sustain at quality. Time-of-day is also contested (Buffer 15:00–20:00 vs
   Hootsuite 04:00–06:00); do not over-fit to it.

**Never:** open with a statistic about how much time developers waste · say seamless / powerful /
revolutionary / game-changing / enterprise-ready · number the posts "1/12" (there is **no data at
all** on series numbering, and it caps a reader's interest at the count) · chase followers.
Follower growth is the platform's worst-performing metric, −59% YoY, and it is not why you are here.

---

## WHAT TO MEASURE — set this up before post 1 or the channel is unfalsifiable

1. **`install-on-request`** at <https://formulae.brew.sh/analytics/install-on-request/30d/> —
   Homebrew records non-private tap installs. This is your only free, third-party, verifiable
   top-of-funnel number.
2. **Sales.**
3. **The names of people who left a substantive comment.** Twenty of those is a beachhead.

Not followers. Not impressions. After ten posts, compute your own click-through and replace every
estimate in this file with a measurement.

---

# THE TWELVE POSTS

Each is a real thing that happened in this repo. That is the whole trick: a technical audience can
smell a manufactured lesson, and every post below has a commit behind it.

Format for each: **HOOK** (≤140 chars, the only line most people read) · **BODY** (1,300–2,000) ·
**VISUAL** · **CTA** (last line, no adjective).

---

## Post 1 — The deletion
**Ships:** week 1, Wednesday. The strongest post in the series; it is also the Show HN spine.

**HOOK** (78)
> I deleted six of my own menu items in one afternoon. Every one of them worked.

**BODY**
> I spent three weeks building a Finder right-click menu for developers. Eleven items. All tested,
> all shipped.
>
> Then I wrote down who the user actually is: someone who runs Claude Code or Cursor all day.
>
> That person's agent already writes files to disk. Their OS already opens a terminal. `git status`
> already lists their untracked junk.
>
> So I put every row through one question: **does this survive a user who has git, an OS with
> terminal shortcuts, and an agent with filesystem access?**
>
> Six failed.
>
> Open in Terminal — macOS ships that.
> Move Junk to Trash — `git status` already lists it.
> Save Clipboard as Files — the agent writes its own files.
> New Scratch Folder — the agent sandboxes itself.
> Two more that were a *category*, not a job.
>
> Deleting them cost me about 60% of the value I had written down for the product. The honest
> number went from a made-up 130 minutes a day to a measured 80.
>
> The five that survived all do one thing an agent cannot do for you: they tell it **which files**.
> The agent can read anything once you point at it. Pointing is the part you still do by hand,
> forty-nine times a day.
>
> If your user's existing tools already do the job, the row is not a feature. It is a maintenance
> cost with a marketing budget attached.

**VISUAL** — PDF carousel, 8 slides, 1080×1350. Slide 1 is the hook alone (it is also the feed
thumbnail). Slides 2–7: one deleted row per slide, its name struck through, and the one-line reason
underneath in mono. Slide 8: the five survivors. ≥24pt, alt text on every slide.

**CTA**
> `brew install avaluev/tap/chute` — the CLI half is MIT and does all of it. https://chutedev.com

---

## Post 2 — The 85 milliseconds
**Ships:** week 1, Thursday.

**HOOK** (86)
> My "copy these files" command took 97ms. 85 of those were spent asking git a question.

**BODY**
> I profiled a command I had written months earlier and never timed.
>
> `chute bundle` reads files and puts them on your clipboard. On a single file it took **97 ms**. On
> forty files it took **103 ms**.
>
> That shape is the tell. If the work scaled with the files, one file would be fast. It wasn't. So
> almost all of it was a fixed cost paid before any file was read.
>
> It was this line:
>
> `Shell.run("git", ["rev-parse", "--show-toplevel"])`
>
> I used it to find the repository root so paths in the output would read `src/a.ts` instead of
> `/Users/me/very/long/path/a.ts`. Correct output. One subprocess spawn per invocation — **85 ms**.
>
> `chute tokens` paid it twice, because it resolves the root and then assembles a bundle, which
> resolves it again. 184 ms.
>
> What does `rev-parse --show-toplevel` actually return? The nearest ancestor directory containing
> `.git`. That is a walk up the path with a `stat` at each step.
>
> Eleven lines. No subprocess.
>
> bundle: 102.7 ms → **24.7 ms**
> tokens: 184.1 ms → **23.5 ms**
>
> One trap worth knowing: `.git` is not always a directory. In a linked worktree or a submodule it
> is a regular *file* containing `gitdir: …`. Check for existence, not for a directory, or you
> report "not a repository" to everyone using a worktree. My test asserts exactly that case.
>
> Shelling out to a tool is the fastest thing to write and it is almost never the fastest thing to
> run.

**VISUAL** — single 1200×1200 terminal screenshot: the before/after benchmark output, both runs
visible, real numbers. No annotation arrows. Alt text describing both figures.

**CTA**
> `brew install avaluev/tap/chute` https://chutedev.com

---

## Post 3 — The bug that only exists in the build you ship
**Ships:** week 1, Friday.

**HOOK** (105)
> My app worked perfectly on my machine and would have been broken for every single person who paid for it.

**BODY**
> macOS has a thing called the hardened runtime. You must enable it to get an app notarised, and
> notarisation is what stops a stranger's Mac showing them a scary dialog.
>
> My build script did the right thing: when it finds a Developer ID certificate, it signs with
> `--options runtime`.
>
> It signed with no entitlements.
>
> The hardened runtime blocks Apple Events by default. My app sends Apple Events constantly — reveal
> a file in Finder, open a folder in Terminal, ask the terminal what sessions are running. Every one
> of those would have failed with `errAEEventNotPermitted (-1743)`.
>
> Here is why it is the nastiest shape of bug I know:
>
> **It cannot happen on my machine.** Locally the script signs with a plain development identity and
> deliberately skips the hardened runtime, because the hardened runtime buys nothing for a build
> that never leaves the laptop. So the code path that breaks the product is the one code path I
> never run.
>
> The fix is one entitlement:
>
> `com.apple.security.automation.apple-events`
>
> And a detail that catches people: `NSAppleEventsUsageDescription` in Info.plist is a *different*
> thing, and you need both. The Info.plist string is the consent prompt the user sees. The
> entitlement is permission to ask at all.
>
> The real fix was not the entitlement. It was making the build script fail if the signed bundle
> comes out without it. Then I broke it on purpose to watch it go red.
>
> A guard you have not seen fail is a guard you are hoping about.

**VISUAL** — 1200×1200: the entitlements plist beside the `codesign -d --entitlements -` output on
the signed bundle, and the build script's refusal message underneath.

**CTA**
> https://chutedev.com

---

## Post 4 — git stash create lies about being complete
**Ships:** week 2, Wednesday. Reuse of the Show HN note; it earns its second outing here.

**HOOK** (112)
> I wanted a snapshot before letting an agent loose on a repo. The obvious git command quietly skipped half of it.

**BODY**
> `git stash create` looks perfect for this. It builds a commit object from your working tree and
> touches nothing — no index change, no HEAD move, no branch. Exactly what a non-destructive restore
> point should be.
>
> It silently excludes untracked files.
>
> Untracked files are precisely what an AI agent creates. The whole point of the snapshot is the
> new stuff.
>
> I found it because a test asserted the wrong thing and I went to check why it passed.
>
> The fix is to build the snapshot against a **private index**:
>
> `GIT_INDEX_FILE=$(mktemp) git add -A`
> `git write-tree`
> `git commit-tree`
>
> Point `GIT_INDEX_FILE` at a temporary file and `git add -A` stages everything into *that* index.
> Your real index is never touched. Then `write-tree` turns it into a tree object and `commit-tree`
> turns that into a commit. Full snapshot, including untracked files. Your worktree, your index and
> your HEAD are all exactly where you left them.
>
> Then create a branch pointing at that commit, and handle the race where two runs create it at once.
>
> The general lesson is duller than the trick: **"it didn't error" and "it did what I meant" are
> different claims**, and only one of them is testable. Every plumbing command has a scope you have
> to read, and the ones that quietly narrow that scope are the expensive ones.

**VISUAL** — PDF carousel, 6 slides. Slide 1 the hook. Slide 2 the naive command. Slide 3 what it
skips, with `git status` showing untracked files. Slides 4–5 the private-index sequence, one command
per slide. Slide 6: worktree, index, HEAD — all unchanged.

**CTA**
> `chute checkpoint .` — free, MIT. https://chutedev.com

---

## Post 5 — Four copies of one function, and two had drifted
**Ships:** week 2, Thursday.

**HOOK** (83)
> There were four copies of my string-escaping function. Two of them escaped nothing.

**BODY**
> AppleScript is a string language. If you interpolate a filename containing a quote, the literal
> ends early and the rest of the filename is executed as script. So you escape it.
>
> I had that escape function written out four times: once in a reveal-in-Finder helper, twice inside
> a single function (Terminal and iTerm, four lines apart), and once in the Finder extension.
>
> An audit told me there were three. It missed one.
>
> Two of the four did this:
>
> `.replacingOccurrences(of: "\"", with: "'")`
>
> That is not escaping. That is **silently rewriting the user's text** — turning a quote into an
> apostrophe on the way into a notification. It is safe, and it is a lie about the filename.
>
> The other two did the correct thing:
>
> `.replacingOccurrences(of: "\"", with: "\\\"")`
>
> Order matters, and it is the part people get wrong: **backslash first.** If you escape quotes
> first, you leave a trailing backslash that escapes the *closing* quote, and everything after it
> becomes executable script.
>
> One function now. Four callers. Nothing to keep in sync.
>
> The thing I keep relearning: duplicated code is not a style problem, it is a **drift** problem. Two
> copies stay identical for about as long as one person remembers both exist. Four copies of a
> security-relevant routine had already diverged and every test was green, because each copy was
> individually correct at what it did — just not at what it was for.

**VISUAL** — 1200×1200: the four call sites side by side with the two divergent lines highlighted,
then the single function underneath.

**CTA**
> https://chutedev.com

---

## Post 6 — The sentence nothing checked
**Ships:** week 2, Friday.

**HOOK** (117)
> I built a gate that fails my deploy if the site claims something false. It missed the most-read sentence on the site.

**BODY**
> I deleted a feature. The gate exists exactly so that no page keeps advertising a deleted feature —
> it reads every rendered page and fails the build if it finds a forbidden claim.
>
> Four days later the site's `<meta name="description">` and its OpenGraph description still sold
> the deleted command.
>
> The gate passed. Every check inside it called one helper:
>
> `const visible = (html) => html.replace(/<[^>]+>/g, " ")`
>
> "Text a visitor actually sees." Reasonable. It strips tags — and `<meta content="...">` **is** a
> tag.
>
> So the one sentence Google indexes, the one an AI crawler quotes, and the one that appears on
> every shared link was the single sentence no check could read.
>
> The fix is four lines: append every `<meta content>` and the `<title>` to what `visible()`
> returns. One helper, and now the forbidden-claim scan, the banned-word scan and the retired-feature
> scan all cover metadata without anyone adding a new check to remember.
>
> When I ran it, it immediately failed on something I had not been looking for: **the homepage hero
> subhead was also still selling the deleted feature.** Live. For four days.
>
> Two things I would tell past me:
>
> A checker's blind spot is invisible by construction — it passes, and passing is what you wanted.
> The only way to find one is to ask what the check *cannot* see.
>
> And if the check has never gone red, you have not tested the check. You have tested the code.

**VISUAL** — PDF carousel, 7 slides. Slide 1 the hook. Slide 2 the one-line `visible()` with the
regex highlighted. Slide 3 the meta tag it threw away. Slide 4 the four-line fix. Slide 5 the gate
going red on the hero. Slide 6/7 the two lessons.

**CTA**
> https://chutedev.com

---

## Post 7 — A megabyte of nothing
**Ships:** week 3, Wednesday.

**HOOK** (72)
> My 3.3 MB Mac app is now 2.4 MB. I did not delete a single line of code.

**BODY**
> A release Swift binary ships a large local symbol table. Nothing at runtime reads it. It is there
> for debuggers and crash symbolication.
>
> `strip -x` removes it.
>
> Each of my three binaries went from about 1.08 MB to about 744 KB — **31%**. The bundle went 3.3 MB
> → 2.4 MB, and the download went to 1.6 MB.
>
> Two details that are the whole difficulty:
>
> **`-x`, not a bare `strip`.** `-x` removes local symbols and keeps globals and undefined ones. My
> Finder extension's entry point has to be the C symbol `_NSExtensionMain`; a full strip takes it,
> and the extension then loads as a plain executable and the menu never appears. The build script
> asserts that symbol survives rather than trusting me.
>
> **Strip before signing.** Stripping a signed binary invalidates its signature, and a sandboxed
> Finder extension with a broken signature fails to load with no message anywhere. The comment above
> that line says ORDER IS LOAD-BEARING, because I will not remember in six months.
>
> The related discovery is worse than the win. That "2.5 MB" figure I had been quoting? It was
> hand-typed into **eight files** and had been wrong since the bundle quietly reached 3.3 MB.
> Nothing compared the sentence to the artifact.
>
> The build script now fails if the claimed size and `du -sh` disagree.
>
> A number in your marketing that no command can check is not a fact. It is a fact's expiry date.

**VISUAL** — 1200×1200: `ls -la` before and after on the three binaries, plus the `du -sh` line.
Real terminal, real numbers.

**CTA**
> https://chutedev.com

---

## Post 8 — A refusal is not a zero
**Ships:** week 3, Thursday. The most quotable idea in the series.

**HOOK** (94)
> My menu bar said a process was using 0% CPU. It was actually saying "I'm not allowed to look."

**BODY**
> I built a menu bar that shows which of your terminal sessions is doing work — CPU and memory per
> session.
>
> The API I used returns a struct. For processes owned by another user, it can fail. The question is
> what your code does with a failure.
>
> The easy shape is to return a zeroed struct. Nothing crashes. Every screen renders. And every
> process you are not allowed to inspect reads as **0% CPU, 0 bytes** — indistinguishable from a
> process that is genuinely idle.
>
> That is worse than an error, because an error is visible and a wrong number is not.
>
> So I measured it instead of trusting the documentation I had read: 169 pids scanned, **0 returned
> success with zeroed data** for a uid that was not mine, 14 refused outright, and pid 1 gives
> `rc = -1, errno = EPERM`. Refusals really are refusals on this OS.
>
> Then I pinned that in a test — so if a future macOS starts handing back zeros, my build fails
> instead of my numbers quietly halving.
>
> Three wrong numbers shipped in that menu bar before I learned this:
>
> CPU from `ps -o pcpu` — a **lifetime average**. Read Chrome at 21.4% when a real one-second sample
> said 0.5%.
> Memory as summed RSS — counts shared pages once per process. A session is a tree of two dozen, so
> it ran 1.78x to 1.93x high — measured, not estimated.
> CPU again, after the first fix: mach ticks read as nanoseconds. On Intel the timebase is 1/1, so
> it is *correct on the machine most people write it on*. On Apple Silicon it under-reported by 24×.
>
> Every test passed through all three, because every test checked that the field existed.
>
> **Check magnitude, not shape.** Assert against the actual RAM in the machine, the actual core
> count, a known 500 MB allocation. A number can be off by 24× and satisfy every schema you own.

**VISUAL** — PDF carousel, 9 slides. Slide 1 hook. Slides 2–4: one wrong number per slide with its
real-vs-reported figures. Slide 5: "every test passed." Slides 6–8: the three physical assertions.
Slide 9: "a refusal is not a zero."

**CTA**
> https://chutedev.com

---

## Post 9 — The MIT licence on the paid app
**Ships:** week 3, Friday.

**HOOK** (89)
> My repo said the app costs $19. My LICENSE file said anyone could take it, free, forever.

**BODY**
> Open core: the CLI is MIT, the Mac app is paid. That is the deal, and my README says so in plain
> English.
>
> A README grants nothing.
>
> My repository root had one unscoped MIT licence. No per-directory carve-out, no NOTICE, no header
> comment anywhere. As written it covered the whole repository — including the source of the app I
> intend to charge for. Anyone who cloned it had an MIT grant to the paid product, and the only
> thing arguing otherwise was marketing copy.
>
> This is the only finding from my audit that was a *legal* problem rather than a code one, and it
> cost about two hours to fix:
>
> The root LICENSE now opens with a scope note listing exactly which directories it covers.
> The two paid directories carry their own all-rights-reserved LICENSE.
> The README's licence section names the directories, not the vibe.
>
> Then the part that actually matters. The failure mode here is not "I forgot" — it is "I add a
> directory in four months and never think about this again."
>
> So my test suite now enumerates every directory under `Sources/` and fails if the LICENSE does not
> name it. Adding a new one goes red until someone says which side of the split it is on.
>
> I broke it on purpose to watch it fail.
>
> If you sell open-core: go and read your LICENSE file right now, not your README. They are
> different documents and only one of them is enforceable.

**VISUAL** — 1200×1200: the scope note at the top of the LICENSE, and the seven passing gate lines
underneath.

**CTA**
> https://chutedev.com

---

## Post 10 — APFS ate my app
**Ships:** week 4, Wednesday. Short, funny, high-shareability.

**HOOK** (87)
> My Mac app launched, printed command-line help, and exited. The bug was the filesystem.

**BODY**
> My bundle has two executables:
>
> `Contents/MacOS/Chute` — the app
> `Contents/MacOS/chute` — the CLI, so it can be symlinked onto your PATH
>
> On APFS with the default settings, those are the same file.
>
> macOS is case-*preserving* and case-*insensitive*. My build script copied the app in, then copied
> the CLI in, and the second `cp` silently replaced the first. No error. No warning. A perfectly
> valid bundle containing one binary under two names.
>
> So the app launched, found itself running as a command-line tool with no arguments, printed its
> help text to a terminal nobody was looking at, and exited immediately.
>
> The bundle was correct. The Info.plist was correct. The signature was valid. The icon appeared in
> the Dock for about a second.
>
> I now have a comment in the build script that says: **APFS is case-insensitive — the app
> executable must not be a case variant of "chute".**
>
> The generalisation, for anyone building a Mac app that also ships a CLI: your filesystem is not a
> hash map with your keys. A copy that succeeds is not a copy that added a file.

**VISUAL** — 1200×1200: the two `cp` lines, then `ls -la Contents/MacOS/` showing one file where
two were expected.

**CTA**
> https://chutedev.com

---

## Post 11 — Judgement is what agents ate
**Ships:** week 4, Thursday. The one strategy post. Ships only after nine technical posts have
earned the right to it.

**HOOK** (92)
> The best paid Mac app in my category stopped charging money and open-sourced itself in June.

**BODY**
> Repo Prompt was a native macOS app for feeding your codebase to an LLM. Well built, well liked,
> $15 a month.
>
> In May its founder stopped charging. In June he open-sourced it, cancelled every subscription and
> compensated the lifetime holders. He wrote:
>
> > "it's increasingly challenging to convince someone that they should pay me $15 a month to obtain
> > those gains when they can just prompt their agent to solve problems for them, and it 'just
> > works.'"
>
> He also joined OpenAI, so read it as a founder exit with a market argument attached rather than a
> clean verdict. But the market argument is real and I had to answer it, because I am building in
> the same category.
>
> Here is the distinction I landed on, and it now decides every line of copy I write:
>
> **Repo Prompt sold judgement — which files matter. Chute sells motion — getting bytes onto the
> clipboard.**
>
> Judgement is exactly what agents got good at. If the question is "what should I look at", the
> model will answer it better than a UI can, and it will keep getting better.
>
> Motion is different. The agent is not the thing holding the mouse. You are looking at three folders
> in Finder. Something has to get them into the conversation. That is a hand movement, and no amount
> of model capability performs it for you.
>
> So the rule I gave myself: **any sentence drifting toward "it picks the right files for you" is
> walking into the business that just closed.**
>
> If you are building anything next to an AI product, this is the question worth an afternoon: is
> the thing you sell judgement, or is it motion?

**VISUAL** — no image. Text-only, deliberately: the quote is the visual, and a manufactured graphic
around someone else's exit reads badly.

**CTA**
> https://chutedev.com

---

## Post 12 — What one audit of my own code actually found
**Ships:** week 4, Friday. The summary post; it makes the previous eleven legible as a body of work.

**HOOK** (87)
> I audited my own shipping code. Nine real defects. Every test was green the whole time.

**BODY**
> Not a hypothetical exercise — a product I was days from charging money for. Here is the list.
>
> **The MIT licence covered the paid app.** A README is not a grant.
>
> **The app signed with the hardened runtime and no entitlements** — every Apple Event it sends
> would have failed, in the notarised build only, never on my machine.
>
> **Four copies of one escape function**, two of which silently rewrote the user's text instead of
> escaping it.
>
> **Two commands exited 0 on real failures.** A script could not tell "no sessions" from "permission
> denied", or "nothing to write" from "every write failed".
>
> **A read-write sandbox exception on `/`** for a process that writes one folder.
>
> **Two unbounded C-string reads** — a 17-byte stack buffer read until it found a zero the kernel is
> trusted to write.
>
> **85 ms of subprocess** in the hot path of the product's main feature.
>
> **The site's meta description** advertising a command deleted four days earlier.
>
> **A size claim hand-typed into eight files**, wrong since the bundle grew by 40%.
>
> The suite was green through every one of them. It is about 900 unit assertions and about 170
> end-to-end checks, and it has been green the whole time.
>
> That is not an argument against tests. It is the actual lesson: **a test suite tells you the code
> does what you told it to do.** It cannot tell you that you told it the wrong thing, that the
> environment differs where it matters, or that a sentence on your website is a lie.
>
> Every one of the nine now has a gate that goes red, and I broke each gate on purpose to watch it
> fail before believing it.
>
> A guard you have never seen fail is not a guard. It is a hope with a green tick next to it.

**VISUAL** — PDF carousel, 11 slides: hook, one defect per slide with its file path in mono, then
the closing line. This is the post most likely to be saved, and saves are a passive signal the
ranker reads.

**CTA**
> `brew install avaluev/tap/chute` https://chutedev.com

---

## PRODUCTION — what has to exist before post 1

| # | Asset | Spec | State |
|---|---|---|---|
| 1 | Carousel template | 1080×1350, ≥24pt, ~880×880 safe area, mono for code, two colours | **to build** — one afternoon, then every carousel is a fill-in |
| 2 | Terminal screenshot style | 1200×1200, real output, no annotation arrows, no window chrome shadows | **to build** |
| 3 | Alt text for every slide | Describes the content, not "carousel slide 3" | per post |
| 4 | The profile | Headline names the topic, not the job title — it is a ranking input | **to do** |
| 5 | Homebrew analytics bookmark | formulae.brew.sh/analytics/install-on-request/30d/ | **to do** |

**Six of the twelve posts need no new asset at all** — they are terminal screenshots of output that
already exists. Take those first; do not let the carousel template block post 1.

## Sequencing against the rest of the plan

LinkedIn runs **from the day the site is live**, not from launch day. Nine technical posts before
Show HN means the Show HN author is not a stranger. Posts 1, 8 and 12 are the three most likely to
travel; hold 11 until the others have earned it.

Cross-reference: `marketing/05-CONTENT-CALENDAR.md` is the launch spike, this file is the
compounding asset. They share no copy — two copies of a claim drift the moment one is edited.
