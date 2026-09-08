---
session: 3a85194f-aca6-49a3-9d52-e5ce2b5777ae
pid: 7968
host: MACAVALUEV-00002.local
at: 2026-09-08T13:08:53Z
commit: e64f44a
kind: done
---
traffic light + site regrouped by the loop — `swift run -c release chutetests` → 1114/1114
Shipped this session, all verified:
- Free and MIT. License.swift, TrialState.swift and worker/ deleted, not disabled. GitHub reports MIT. The founder's home address is off site/src/lib/seller.ts and the internet.
- CI unstuck: macos-13 is a RETIRED runner label — it parses, queues forever, dies at 24h. Matrix is [macos-15, macos-26] with timeout-minutes.
- First GitHub release exists (v0.2.1); /releases/latest used to land on an empty page.
- chutedev.com was down at DNS level: Pages custom domains attached but deactivated, no CNAME. Founder added the records by hand.
- The traffic light: state-coloured row dots, a menu-bar pip, a kqueue on ~/.chute/sessions.
- Site regrouped by the loop (brief/steer/supervise/land) instead of by `paid`.

TRAPS PAID FOR TODAY:
- MenuBarMark lived in ChuteApp, which chutetests cannot import, so the menu bar icon had NEVER had an assertion — through two disappearances. It is in ChuteCore now with 38 assertions.
- A pixel-counting test PASSED while the icon was invisible. It drew perfectly, in black, on a dark bar. "It renders" is not "it can be seen": assert luminance under .darkAqua.
- A rule written only in a comment has no enforcement. "Shape carries the meaning" sat above code where blocked and waiting were the same disc.

NEXT: sound on state transition; `chute signal` / `chute watch --json`; record the Signals demo with Recordly.
