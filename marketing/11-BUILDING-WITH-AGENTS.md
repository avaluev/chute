# The harness is the product

**How I built a macOS app with coding agents, and the gates that made it survivable.**

*Alexandr Valuev · 2026-09-02 · Every claim below names the file or the command that produces it.
The repository is public: the code, the gates, and the handoff notes written while it was going
wrong.*

---

## The premise almost nobody states

Coding agents made writing code cheap. They did not make **knowing it works** cheap. The cost
moved; it did not go away, and it landed somewhere most teams have no instrument pointed at.

The numbers for this project, measured today:

| | |
|---|---|
| Swift, hand-written and agent-written | **11,975 lines**, zero third-party dependencies |
| Unit assertions | **1,005** |
| End-to-end checks | **145** headless, **173** driving real Finder |
| Menu-item acceptance | **81**, against a deliberately hostile directory tree |
| Shell in the harness | **2,425 lines** across 14 scripts |
| Elapsed | about six weeks, one person |

Read the last two rows together. **A fifth of the project by volume is the thing that checks the
project.** That ratio is not discipline for its own sake. It is the direct consequence of one
observation:

> An agent will produce a plausible implementation of anything you describe, at a rate far beyond
> your ability to read it. So your review is not the bottleneck — your review is *already
> skipped*. What you actually ship is whatever your gates cannot catch.

Everything below is an attempt to take that seriously.

---

## Part 1 — Five ways a green suite lied to me

Each of these was green. Each shipped something wrong. I keep them written down because the
categories generalise even though the bugs do not.

### 1. It checked the shape, and the magnitude was off by 24×

The menu bar shows CPU and memory per terminal session. Three separate wrong numbers shipped:

- CPU came from `ps -o pcpu`, which is a **lifetime average**. It read a browser at 21.4% while a
  real one-second sample put it at 0.5%. Forty-fold.
- Memory summed `rss`, which counts every shared page once per process. A session is a tree of
  about twenty-four processes, so the figure ran 1.78× to 1.93× high.
- CPU again, after the first fix: mach ticks read as nanoseconds. **On Intel the timebase ratio is
  1/1, so the naive reading is exactly correct** — which is why this survives review on the machine
  most people write it on. On Apple Silicon it under-reported by 24×.

The end-to-end suite asserted that the keys `cpuPercent` and `memoryBytes` **exist**. They always
did. Every gate in the repo checked shape, so a number could be off by an order of magnitude
forever and stay green.

The fix was a gate that compares against something physical — the RAM in the machine, the cores in
the machine, a load of known size, an allocation of known size. `Scripts/check-metrics.sh`. Four
checks. A shape cannot satisfy them.

**Generalises to:** every assertion of the form "the response has a `total` field".

### 2. The wrong code was somewhere no test could reach

The unit suite links one library target. Two other targets — the AppKit app and the sandboxed
Finder extension — had **zero** coverage. Not low. Zero, because `XCTest` ships with Xcode and this
repo builds with the Command Line Tools alone.

Two separate audits counted the decision points there, both named the same function as the
highest-value thing to extract, and **both times it was ranked and deferred** — including by me,
with the finding open in front of me.

Then this line, in the deferred function:

```swift
controller.selectedItemURLs()?.first ?? controller.targetedURL()
```

It reads correctly. It is wrong for every multi-selection: select 34 items in a Python project and
`__pycache__` sorts first, so "copy the folder tree" copied thirteen `.pyc` files. 917 assertions
and 144 end-to-end checks were green, and not one of them could see that line.

**The lesson is not "write more tests".** It is that *a finding you wrote down and ranked is not a
guard*. Part 2 is what I built instead.

### 3. There was no positive case, so the negative one passed

`CHUTE_HEADLESS=1` exists so the suite runs on a machine with no GUI. One command blocked for
**90,363 milliseconds** under it.

The guard stopped one line short: the code correctly skipped reaching for Finder, then polled for
90 seconds waiting for a rename **in Finder** — a rename that cannot happen when there is no
Finder.

It was invisible to every gate because the suite had no *positive* case for that command. It had
cases for the ways it should fail and none for it working. I had written that gap down in a
planning note, labelled it "honest", and moved on. Closing it found the bug in about a minute.
The command now takes 151 ms.

**Generalises to:** any suite whose coverage of a feature is entirely error paths.

### 4. The instrument was broken, and the instrument is what finds broken things

The acceptance script takes a `--perf` flag. It printed nothing. I had defined a `timing()` helper
in the harness and never called it.

A flag that silently does nothing, in the harness written specifically to catch that class of
defect. This is my favourite bug in the project, because it is the one that says the method is
necessary rather than sufficient: **the gates need gates.**

### 5. The docs described a product that no longer existed

A command was deleted one morning. For a full day afterwards, the README, the docs page, the terms
page, a JSON command manifest and five marketing assets all still told people to run it. Every
gate was green, because the gate compared the site against a **hand-maintained list of retired
names** that nobody had updated.

Worse: the site's `<meta name="description">` — the single sentence Google and every AI crawler
read — still sold the deleted command a day after the visible copy was fixed, because the checker
stripped HTML tags before reading, and metadata is not visible text.

**The highest-leverage sentence on the site was the one sentence nothing checked.**

---

## Part 2 — The ratchet

This is the most transferable thing in the repository, and it took a shipped bug to earn.

**The problem:** some code cannot be unit tested, for real structural reasons — it needs a GUI, a
device, a sandbox, a framework that will not link in your test target. The honest response is to
extract the logic elsewhere and test it there. The *actual* response, every time, under deadline,
is to write "extract this" in a document and ship.

**The guard:** a file in an untestable target may shrink freely and **may never grow.**

`Scripts/check-untested-logic.sh`, 106 lines. It counts decision points per file — `if`, `guard`,
`switch`, `case`, `for`, `while`, `&&`, `||`, with comments stripped first so a sentence *about* a
guard is not counted as one — and compares against a committed baseline:

```
10 Sources/ChuteApp/FirstRunWindow.swift
19 Sources/ChuteApp/Onboarding.swift
29 Sources/ChuteApp/SessionMenu.swift
43 Sources/ChuteApp/main.swift
20 Sources/ChuteFinder/ChuteFinderSync.swift
...
```

171 decision points across 11 files. A file going down is always fine. A file going up fails the
build. A new file appearing in those targets fails the build.

Three properties make it work where a coverage threshold does not:

1. **It permits the debt that already exists.** A percentage target on a codebase with two
   uncoverable targets is either unreachable or set so low it permits everything. The ratchet takes
   today as the ceiling and only ever lowers it.
2. **The escape hatch is visible in a diff.** You *can* re-record the baseline. Doing so puts a
   line in a pull request that says a number went up, which is a conversation. Deferring a finding
   in a planning document is not.
3. **The failure message names the fix, not the problem.** A red run prints *"move the new branch
   into `ChuteCore` as a pure function and test it"* — which is the move five components have now
   made, each one permanently lowering the ceiling.

Perturbing the original one-line bug back into place takes one file from 20 to 22 and goes red.
I ran that before believing any of it.

**Steal this.** It is a hundred lines of shell, it needs no framework, and it converts "we should
test that eventually" from a good intention into a build failure.

---

## Part 3 — The doctrine

Seven rules. Each one is written in the repository beside the incident that produced it, because a
rule without its receipt gets argued away by the next person in a hurry — and with agents, the
next person in a hurry is you, twenty minutes later.

**1. Read the tally, not the exit code.** `command | tail` reports `tail`'s status. Silence is not
a pass. A skip is not a pass. State the denominator: *"0 found"* over 0 items is a false green.
`check-metrics.sh` refuses to score itself when no sessions are open — it prints `SKIP` and says
the gate is meaningless over zero, rather than reporting four passes.

**2. A note is not a gate.** One checker printed *"9 recordings no case refers to"* for days.
Three of them were videos of deleted features, on live public URLs. Nobody read the note. It fails
now.

**3. A hand-kept list is not a gate.** This is the big one, and Part 4 is entirely about it.

**4. A comment is not a guard.** An environment variable's documentation said *"tests only"* and
enforced nothing. A test then constructed the default object and wiped the owner's real data. The
grep that prevents it is nine lines.

**5. Perturb every new guard until it goes red.** A gate you have never seen fail is a gate you
have never seen. Break the fix, watch the guard catch it, restore with a targeted edit. Every
guard in this repo has a note saying what was perturbed to prove it. This is the single highest
return practice in the file and it costs about ninety seconds.

**6. A gate that proves shape passes a deleted feature.** Two checkers proved a demo's grammar and
its fixtures. Neither asked whether the thing being demonstrated existed.

**7. A passing suite says the source is right, never that the installed artifact is.** Different
question, different instrument. The app prints its own build SHA for exactly this reason.

---

## Part 4 — Derive gates from artifacts, never from lists

Rule 3 deserves its own section because it is the one that changed how I write everything else.

A gate whose source of truth is a second document is a second document that rots. The fix is to
make the gate interrogate **the artifact itself**.

Concretely, in this repo:

| The claim | The naive gate | What it asks now |
|---|---|---|
| These commands exist | a list of retired names | the CLI's own **dispatch switch**, parsed from source |
| These menu items exist | a list in the copy | `chute finder-actions --json` — the same table the extension draws from |
| The app is this many megabytes | a number typed in eight files | `du -sh` on the built bundle, at build time |
| The changelog is current | a human remembering | the version constant the binary, the installer and `--version` all read |
| The sitemap is complete | a hand-typed route list | the rendered output directory |
| The app passes Gatekeeper | the word "notarised" on a denylist | `spctl -a` on the actual bundle |

That last row is the cleanest illustration. The denylist version forbade a *word*, so it could not
tell a claim from a denial — it would have blocked this very article from being published on the
site, because the article discusses the wall. Asking `spctl` forbids the affirmative forms while
the artifact is rejected, and passes them the moment it is accepted. **The row retires itself.
Nobody has to remember.**

There is one more property worth naming. Deriving from the artifact makes the gate *precise*, and
precision is what keeps a gate alive. The command checker had eleven false positives on its first
run because it matched English prose: the phrase “chute production signing”, in a sentence, is not
an invocation. Scoping it to code spans only fixed that — and while writing *this* article the
gate caught me putting that very phrase back inside backticks, which is the most convincing
demonstration of it I could have staged and did not have to. **A gate that cries wolf is a gate people
learn to ignore, and a gate people ignore is worse than no gate, because it also provides
comfort.**

---

## Part 5 — What agents are actually bad at

Six weeks of close observation, stated as specifically as I can.

**They write code that reads correctly.** This is the whole problem and it is not a small one. The
multi-selection bug was one line, idiomatic, exactly what I would have written, and wrong for
every input with more than one element. Review — human or agent — is pattern-matching against
plausible, and the output is optimised for plausible. Only execution against a hostile input
distinguishes them. My hostile tree has symlink loops, a 10 MB file, 500 entries, unreadable
permissions, and files whose names contain quotes.

**They duplicate rather than reach.** One escaping function existed in four copies across four
files. **Two of the four had silently drifted** into mapping double quotes to single quotes —
rewriting the user's text instead of escaping it. Nothing was broken enough to notice. Copies do
not diverge because anyone decided to diverge them; they diverge because two sessions fixed the
same bug in different places on different days.

Grep for the second implementation. Every time.

**They optimise the thing you named.** Ask for a faster bundle command and you get a faster bundle
command. Nobody mentions that 85 of its 97 milliseconds were spent spawning `git` to answer a
question a few `stat` calls answer, or that a neighbouring command paid the same spawn twice.
Profile before you brief; the briefing determines the answer.

**They will not tell you the feature should not exist.** I deleted six of my own menu items in one
afternoon. Every one worked, every one was tested, and every one solved a problem my actual user
does not have, because their agent already writes files and their OS already opens terminals. That
deletion removed roughly 60% of the value I had written down for the product, and the honest
figure went from a projected 130 minutes a day to a measured 80.

No agent proposed it. The question that produced it — *does this survive a user who has git, an OS
with terminal shortcuts, and an agent with filesystem access?* — is judgement about a person, and
it is the one input that has to come from you.

**Where they are extraordinary:** the harness. 2,425 lines of shell that nobody enjoys writing,
that has no glory in it, and that is the highest-value code in the repository. Agents write
gates tirelessly and well. That asymmetry is, I think, the actual finding of this whole project —
**point them at the verification, not only at the feature.**

---

## Part 6 — The working loop

The parts of the process that survived contact.

**One handoff file, overwritten.** `handoff/NEXT.md`. Twelve handoff files means none is
authoritative. It carries state, one goal, done-with-evidence, in-flight, next commands, decisions
with their reasons, and a traps list. Everything is an absolute path with a line number, and every
claim carries the one line of output that proves it — never the log.

**A session's only durable output is what is committed.** Context windows end. Transcripts are not
artifacts. A fact that lives only in a conversation is already lost, so a finding gets written to
a file in the repository before the session that found it ends.

**Decisions carry their reason, permanently.** Re-deriving a settled decision is the single
largest waste in agent-assisted work, because the agent has no memory of having settled it and
will happily re-open it with a well-argued case. `DECISIONS — do not re-litigate` is a real
heading in the handoff. Superseded entries are struck through and dated rather than deleted, so
the record shows what was believed at the time.

**Checkpoint-commit each completed unit.** One commit per six hours is a six-hour blast radius.

**One flight per file.** Two agents in one file is a lost afternoon.

**Commit messages state the finding, not the change.** Reading back: *"Copy Folder Tree used
whichever item Finder sorted first, not the folder you were in"*; *"a release cannot ship past the
placeholder key"*; *"the test suite stopped clearing the owner's basket to prove the basket
works"*. The log is a defect register you get for free.

---

## Part 7 — Honest accounting

**What it cost.** About six weeks, one person, part-time, with agents doing most of the typing.
The harness is roughly a fifth of the volume and consumed considerably more than a fifth of the
attention, because gates require you to know what would be wrong — which is the expensive part and
the part that does not delegate.

**What it produced.** A 2.9 MB app with no dependencies, no launch daemon, no background service
and no network code at all; a free MIT command-line tool; 1,005 assertions; CI across three macOS
versions; and a public repository where every marketing claim is checked against the binary that
implements it before it can deploy.

**What is still broken.** One surface still carries a null in its own value ledger, because I have
not measured it and refuse to invent it. The app is not yet through Apple's notarisation, which is
the subject of a separate memo. Two targets still hold 171 untested decision points — the ratchet
guarantees only that the number falls.

**What I would do differently.** Build `check-metrics.sh` first. Three wrong numbers shipped before
the idea of testing a *magnitude* rather than a *shape* occurred to me, and that gate is 211 lines.
The general form: **for each thing you are about to claim, name the physical quantity that would
contradict it.** If you cannot name one, you do not have a claim, you have a hope.

---

## The one-paragraph version

Agents removed the cost of writing code and left the cost of trusting it exactly where it was.
The work that remains is not writing tests; it is building instruments that can actually fail —
gates that read the artifact instead of a document, that check magnitudes instead of shapes, that
ratchet debt downward instead of recording it, and that you have personally watched go red. Point
the agents at that, and they are better at it than at the feature. The feature was never the hard
part.

---

*The repository, including every gate quoted here: <https://github.com/avaluev/chute>*

*Reproduce any number in this article:*

```bash
swift build -c release && swift run -c release chutetests
CHUTE_HEADLESS=1 ./Scripts/smoke.sh
./Scripts/acceptance.sh --perf
./Scripts/check-untested-logic.sh
```
