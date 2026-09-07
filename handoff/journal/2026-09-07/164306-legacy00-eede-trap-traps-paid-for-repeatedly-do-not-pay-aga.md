---
session: legacy
pid: 0
host: legacy
at: 2026-09-07T16:43:06Z
commit: legacy
kind: trap
legacy-src: /Users/sxope/Documents/2026/Development/37.chute/handoff/archive/NEXT-2026-09-07-full.md:246
---
TRAPS — paid for, repeatedly. Do not pay again
- **A finding you wrote down and ranked is not a guard.** `ChuteFinderSync.run` was named as
  untested by two audits and deferred by both, and the founder found the bug. If a finding is real
  enough to rank, it is real enough to deserve a gate that makes it impossible to grow — even when
  the fix itself waits.
- **A proxy is not evidence, and a stale proxy is a lie with a timestamp.** Terminal's `busy` flag
  and Claude Code's title glyph both looked like "the agent is working" and neither is. The glyph
  is the sharper lesson: it was CORRECT when it was written and was never withdrawn, so it aged
  into a false positive — and it was only ever consulted once the trustworthy source had aged out.
  Before treating an observation as a state, ask what clears it.
- **A gate that fires on noise is a gate people learn to ignore.** The CLI-binary gate added on
  2026-09-04 09:xx fired on a 1 KB move at 10:xx — on the very next commit. It compares at ±2% now,
  the band `du -sh` already gives the bundle row. Match the gate's precision to the claim's.
- **A gate that sweeps the docs and not the product is half a gate.** The forbidden-claims sweep
  covered the site, then the README, and the same forbidden sentence sat in the app's About tab the
  whole time — where a customer who has just paid reads it. When you add a check for a claim, ask
  where else that claim is rendered, and sweep the product first.
- **`&&` cannot catch a failure that exits zero.** A chained shell command is only as safe as
  the exit codes in it. `chute hooks merged` on an OLDER binary printed the wrong thing and
  succeeded; the chain dutifully moved it into place. When a generated command consumes the output
  of another command, check the OUTPUT, not just the status — and have the generator name the
  exact binary it means, never a bare word PATH will resolve for it.
- **A note is not a gate.** `check-cases.mjs` printed "9 recordings no case refers to" for days.
  Three of them were videos of deleted features, publicly reachable. Nobody read the note.
- **A hand-kept list is not a gate.** `check:claims` passed for a whole day while four files told
  people to run a deleted command, because it compared against a list of retired names nobody
  updates. It asks the dispatch switch now — and it now scans `marketing/` too, which it did not,
  which is why five launch assets sold `unpack` for a day with everything green.
- **A comment is not a guard.** `CHUTE_BUFFER_DIR` said "tests only" and enforced nothing.
- **Green with zero failures can still be a broken run.** Read the tally, never the exit code.
- **A gate that proves shape passes a deleted feature.** Lint proved grammar, plan proved
  fixtures; neither asked if the thing existed.
- **Patch a total and you will be wrong.** Derive every number from `cases.ts` after the edit.
- **A passing suite says the SOURCE is right, never that the INSTALLED APP is.** `chute doctor`
  prints the build stamp for exactly this reason.
- **`check-metrics` goes red ~1 run in 3 under load, green alone.** Measured again 2026-09-01: red
  while two builds ran, 4/4 green on a quiet machine seconds later. Do NOT widen the bound; that
  is how it would stop catching the 24× error it was built for.
- **Test suites must not touch the user's data.** The basket tests cleared his real basket until
  `CHUTE_BUFFER_DIR` was added.
- **A test fixture that unlinks its own binary dies.** The kernel SIGKILLs a copied binary the
  moment its file is gone (measured 2026-09-03, every copy method, every deletion method); a
  test built on it is red 4 runs in 10 and looks like a race. Prove the reader on a live pid.
- **`cd` persists across shell calls, and a script run from the wrong directory prints nothing.**
  `./Scripts/smoke.sh` from `site/` produced zero output and zero error. Absolute paths, always.
- **Running the full smoke blocks the founder** — it owns the clipboard for ~30 s and drives real
  Finder actions. Safe while he works: `swift build`, `swift run chutetests`, the site checks.

- **Judging an icon on craft cannot catch a semantic misread.** Before committing to any mark,
  copy it to neutral filenames in a neutral directory and ask four viewers, cold, "what object is
  this". It takes minutes. Skipping it cost an hour here: two marks were fully polished before the
  test said both read as paper shredders. Any future Chute mark in the "document meets a
  horizontal slot" family is dead on arrival — do not re-derive it.
- **A `variableLength` status item with no image and no title is ZERO POINTS WIDE.** It is in the
  menu bar, it is real, and there is nothing to see or click. Removing the badge count on
  2026-09-04 deleted `updateBadgeFromHooks()` from the launch path — and that call, whose name says
  "badge", was the ONLY thing that set the icon at startup. The other call site is `menuWillOpen`,
  which cannot help: it needs the click that needs the icon. Chute launched invisible. The image is
  set where the item is CREATED now, one line below it: an invariant that lives next to the thing
  it is about cannot be orphaned by deleting a refresh. **`screencapture` cannot check this** — it
  returns pure black without Screen Recording permission, clock and all, so it looks exactly like
  an empty menu bar. Ask a human to look.
- **A PIPE HIDES AN EXIT STATUS — three times in one day.** `… | tail`, `… | grep`, any of them:
  the pipeline reports the LAST command's status, so `./Scripts/build-app.sh | grep '^size:'`
  returns grep's 0 while the size gate exits 1, and an `&&` chain after it runs anyway. That is how
  a 3.0 MB app was installed with the fact sheet still claiming 2.9. Redirect to a file and grep
  the file. This trap was already written here when it was walked into twice more.
- **`… | tail` exits 0 with the run failing** — the pipe reports `tail`'s status. Documented here
  for `chutetests`, and paid AGAIN on 2026-09-04 for `smoke.sh`: a run reported `smoke: 148 passed,
  2 failed` and the shell said `EXIT=0`, so it read as green. Worse, `tail -15` had thrown away the
  two failure lines, so WHICH cases failed is now unknowable — four later runs were 150/150,
  including one under heavier concurrent load, and the two have not reappeared. **Redirect to a
  file, then grep it.** Never pipe a gate through `tail`.
- **A number in the fact sheet with no gate WILL drift.** Three of them had, silently, and one was
  being sold to a reader: CLI binary 727 KB claimed / 747 KB shipped, lines of Swift 11,975 /
  12,619, unit assertions 1,005 / 1,073. The two gated numbers were both correct. Gate it or expect
  it to be wrong.
- **A ✓ whose detail contradicts it is a false pass, not a formatting quirk.** `✓ Finder extension
  actually starts — not installed` was true for weeks. Read the DETAIL column of a green run at
  least once.
- **`ProcessMetrics › the listing costs N ms` fails under load.** A 5 ms budget, 0.88 ms on a quiet
  machine, 6.4-7.1 ms while node and headless Chrome eat three cores. Not a regression — check
  `git status Sources/ChuteCore/ProcessMetrics.swift` first. Do NOT loosen the threshold; it exists
  to catch the devname-cache regression.
