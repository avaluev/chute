---
session: legacy
pid: 0
host: legacy
at: 2026-09-07T16:43:06Z
commit: legacy
kind: decision
legacy-src: /Users/sxope/Documents/2026/Development/37.chute/handoff/archive/NEXT-2026-09-07-full.md:166
---
THE THREE THINGS ONLY THE FOUNDER CAN DO
1. **The stopwatch.** `./demo/gui/by-hand.sh`, ~3 minutes. All six `demo/out/gui/*.json` carry
   `manual: null`. Every minute figure in the launch is an ESTIMATE until this runs, and for a
   tool sold on "here is the time you save" that is the most attackable claim in the campaign.
   `marketing/03-LAUNCH-POSTS.md` §Honesty note blocks the first post on it.
2. **The Basket test.** Three files, three folders, `~/Desktop/chute-basket-test/` → Add to
   Context Basket → Copy Basket as @mentions → paste into Claude Code. **If that is not obviously
   faster than typing three `@` paths, delete it** like the other six. Do not polish it before
   answering.
3. **Apple enrolment — START IT BEFORE SLEEPING.** It is the only blocker with a 24–48 h human
   review queue, so every hour it is not started is an hour added to the launch date.
   <https://developer.apple.com/programs/enroll/>, Individual / Sole Proprietor,
   `docs/11-PHASE-0-RUNBOOK.md` §STEP 1. The reasoning is settled in
   `marketing/09-APPLE-AND-DISTRIBUTION.md` — **do not re-litigate it**, and in particular do not
   re-open "ship a cask instead", which stopped being possible on 2026-09-01.
4. **Phase 0 — the rest of the money.** `Sources/ChuteCore/License.swift:28` is still `REPLACE_ME_BEFORE_RELEASE`;
   it is not valid base64, so **every buyer's key would fail silently** and `LicenseSuite` cannot
   see it (it verifies against its own keypair). `Scripts/release.sh` now refuses to build past
   it. Then: `dig +short chutedev.com` (empty), Apple enrolment ($99), Paddle. Runbook:
   `docs/11-PHASE-0-RUNBOOK.md`. **The whole campaign is blocked on these** —
   `marketing/05-CONTENT-CALENDAR.md` §1 is the gate list.

---
