# Launch posts

> Rewritten 2026-09-01. Every post here previously sold `unpack` — "10–20× a day: unpacking a
> multi-file answer back onto disk" — and quoted **~90 min/day**. The command was deleted on
> 2026-08-31 and the app-surface figure is **80.7 min/day**. Both are fixed below.
>
> Numbers in these posts come from `site/src/lib/cases.ts`. Do not retype one; re-derive it.
> **Every figure below is an ESTIMATE until `./demo/gui/by-hand.sh` has been run** — see the
> honesty note at the bottom, which is not optional.

---

## X / Twitter — the demo post (App+0, post 1 of 6)

> I drive Claude Code ~10h/day and I finally timed where the day actually goes.
>
> Not prompting. Not reviewing. **Telling it which files to look at.**
>
> 32× a day: typing a path into a prompt
> 17× a day: feeding it a folder one file at a time
>
> ~80 minutes. The agent can read anything — I'm the bottleneck pointing at it.
>
> [20s video: three folders selected → right-click → Copy Files as Context → ⌘V in Claude Code →
> 41 files · ~14k tokens]
>
> Chute. macOS. $19 once, 14-day trial, no account, no network code at all. Link below.

**Posts 2–6 of the thread:** 2 — the Basket (three folders, four minutes, one hand-over).
3 — the menu bar: which of five terminals is waiting on you. 4 — the CLI is MIT and free, here
is the brew line, check the numbers yourself before you pay. 5 — what got DELETED and why (six
rows, because your agent already writes files). 6 — price, refund, link.

---

## Hacker News — Show HN

**Title:** Show HN: Chute – point your coding agent at files with one Finder right-click

> I spend most of my day driving Claude Code and Codex, and almost none of my friction is the
> models. It is the pointing: telling the agent which files, dozens of times a day. The agent can
> read anything once I aim it. Aiming is manual.
>
> Chute is a small macOS utility for that. Select folders in Finder, right-click, and every file
> inside is on your clipboard as one blob with a token estimate. Or collect files from several
> folders into a basket as you browse and hand the set over at once.
>
> The more useful part of this post is what I DELETED. I built thirteen jobs, then decided the
> user was a Claude Code user, and six of them died the same afternoon: "open in Terminal" (macOS
> ships it), "move junk to Trash" (`git status` already lists it), "save clipboard as files" (the
> agent writes its own files), "new scratch folder" (the agent sandboxes itself). If your user's
> tool already does the job, the row is not a feature, it is a maintenance cost.
>
> Two implementation notes:
>
> 1. `checkpoint` had a real bug I only found because a test asserted the wrong thing.
>    `git stash create` builds a commit from the working tree without touching anything — perfect
>    for a non-destructive snapshot — but it silently excludes untracked files, which are exactly
>    what an agent creates. The fix is to point `GIT_INDEX_FILE` at a temp file and `git add -A`
>    against that private index, then `write-tree` + `commit-tree`. Full snapshot, real index
>    never touched.
>
> 2. The app bundle broke because APFS is case-insensitive: `Contents/MacOS/Chute` (the app) and
>    `Contents/MacOS/chute` (the CLI) are the same file, so the second `cp` silently replaced the
>    first. The app launched, printed CLI help, and exited.
>
> No Xcode required — SwiftPM plus a hand-written Info.plist. Zero dependencies, zero telemetry,
> the only network code is a `gist` command that shells out to your own `gh`. The CLI is MIT; the
> Finder menu and menu bar are $19 once.

**Founder's first comment must contain, in this order:** the price, the free MIT CLI with the
brew line, and the sentence "the time figures are my own measurements of my own workflow — here
is the method" linking to the fact sheet.

---

## Product Hunt

**Tagline:** Point your coding agent at the files, in one right-click

**Description:**
> Your agent can read your whole repo. You spend the day telling it which part. Chute is a 3.0 MB
> macOS utility that puts that in the Finder right-click: select folders, click once, and every
> file inside is on your clipboard as one blob with a token count. Collect files from several
> folders into a basket and hand them over at once. See which of your five terminals is actually
> waiting on you.
>
> Offline. No account. No subscription. The CLI underneath is free and MIT forever, so you can
> check every claim before you pay for any of it.

**First comment:**
> I measured my own day and found ~80 minutes going into pointing agents at files rather than
> working with them. Then I deleted six of my own menu rows, because a Claude Code user's agent
> already does those jobs. Every destructive action previews and shows you the list before it
> touches anything. Happy to answer anything about the implementation.

---

## Reddit r/ClaudeAI (and r/cursor, reworded)

**Title:** I timed how long I spend telling Claude Code which files to look at. ~80 min/day.

> Not the prompting. The pointing. 32 paths typed into prompts, 17 folders fed in a file at a
> time. So I built a Finder right-click that does it in one click, with the token count before
> I paste.
>
> The bit I did not expect: once I accepted that the user's agent already writes files to disk,
> six of my own menu rows became dead weight and I deleted them. What is left is five rows.
>
> I own this — it is $19 with a 14-day trial. The command-line half is MIT and free forever, and
> it does the same work, so try that first and do not pay if the output is not what I said.

---

## Reddit r/macapps

**Title:** A macOS utility that turns a Finder selection into agent context, with no network code at all ($19, 14-day trial)

> Not another right-click suite — it does one loop. Select folders, right-click, every file
> inside is on the clipboard as one blob with a token estimate. Or collect files across folders
> into a basket and hand them over at once, which as far as I can find nothing else on the Mac
> does. 3.0 MB, zero dependencies, no launch daemon, no telemetry, no account, no subscription.
> The CLI half is MIT. Happy to answer questions.

---

## Reddit r/commandline (App+16, the CLI re-enters)

**Title:** `chute` — a zero-dependency Swift CLI for shovelling context at coding agents (MIT)

> `chute bundle src/` gives you every file under a path as one XML blob with a token estimate.
> `chute tokens` counts before you paste. `chute checkpoint` snapshots a repo *including
> untracked files* without touching your index, worktree or HEAD. `chute ports` tells you what is
> holding 3000 and offers to kill it, after showing you what it would kill.
>
> No dependencies at all — `grep -c '.package(' Package.swift` → 0. Builds with the Command Line
> Tools; Xcode not required. MIT.

---

## THE HONESTY NOTE — read before posting any of the above

Every minute figure in this file is a **derived estimate**, not a stopwatch reading. All six
`demo/out/gui/*.json` carry `manual: null`, `site/scripts/check-cases.mjs` passes precisely
because it says so honestly, and for a tool sold on "here is the time you save", that is the
single most attackable claim in the launch.

`./demo/gui/by-hand.sh` — three minutes, founder only — turns every figure above from an estimate
into a measurement. **Run it before the first post goes out.** Until it has been run, the honest
phrasing is *"my own timings of my own workflow"*, and the fact sheet must be linked from any
post that names a number.
