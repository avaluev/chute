# Launch posts

## X / Twitter — the demo post
> I run coding agents ~10h/day and I finally measured where the time actually goes.
>
> Not prompting. Not reviewing. **Moving files around for the agent.**
>
> 25–40× a day: copying paths into a prompt
> 15–20× a day: hand-bundling files into one message
> 10–20× a day: unpacking a multi-file answer back onto disk
>
> ~90 minutes a day. So I built the thing.
>
> [20s video: select 8 files → right-click → Bundle Context → paste → ~14k tokens]
>
> Chute. macOS. Free 14-day trial, $19 after. Offline, and not one line of network code. Link below.

## Hacker News — Show HN
**Title:** Show HN: Chute – Turn a Finder selection into agent-ready context

> I spend most of my day driving Claude Code and Codex, and I noticed almost none of my friction
> was the models. It was the plumbing: copying paths, bundling files by hand into one message,
> and unpacking multi-file answers back onto disk one block at a time.
>
> I counted 24 of these jobs and timed them. It came to 90–120 min/day.
>
> Chute is a small macOS utility for that loop. Select files in Finder, get clean paths or an
> XML bundle of their contents with a token estimate. Paste an agent's answer, get the file tree
> back. Snapshot a repo before letting an agent run.
>
> Two implementation notes that might interest people here:
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
> No Xcode required to build it — SwiftPM plus a hand-written Info.plist. Zero dependencies.
> Zero telemetry; the only network code is the gist command.

## Product Hunt
**Tagline:** Turn your Finder selection into agent-ready context
**Description:**
> Chute is a 2.5 MB macOS utility for people who run coding agents all day. Select files → get
> clean paths, or every file's contents in one paste-ready blob with a token count. Paste an
> agent's multi-file answer → get real files back. Snapshot your repo before letting an agent
> run wild.
>
> Right-click in Finder, a global hotkey, or the CLI. Offline, no account, one payment.

**First comment:**
> I built this because I measured my own day and found 90+ minutes going into moving files around
> for agents rather than working with them. Every destructive command previews before it acts —
> I wanted something I could trust in a repo an agent was about to refactor. Happy to answer
> anything about the implementation.

## Reddit r/macapps
**Title:** I made a macOS utility that turns a Finder selection into LLM context, with no network code at all (free trial, $19)
> Not another right-click suite — it does one loop well: context into your agent, artifacts back
> out. Bundle 8 files into one XML blob with a token estimate, unpack a multi-file answer into a
> real file tree, snapshot a repo before an agent touches it. No telemetry, no account, no
> subscription. Happy to answer questions.
