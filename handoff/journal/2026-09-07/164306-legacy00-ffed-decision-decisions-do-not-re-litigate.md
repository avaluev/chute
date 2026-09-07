---
session: legacy
pid: 0
host: legacy
at: 2026-09-07T16:43:06Z
commit: legacy
kind: decision
legacy-src: /Users/sxope/Documents/2026/Development/37.chute/handoff/archive/NEXT-2026-09-07-full.md:332
---
DECISIONS — do not re-litigate
- **ICP is Claude Code / Cursor users.** Everything follows from it.
- **The CLI is plumbing, not a product.** It competes with free `npx repomix` and earns nothing;
  it stays MIT and stops being marketed as thirteen jobs to learn. It IS the ad — see
  `marketing/05-CONTENT-CALENDAR.md` §4.
- **A basket entry is a PATH**, not a copy of content.
- **Nothing auto-fills the basket.**
- **`Copy Folder Tree` and `New File` stay** despite the ICP logic — a pasted tree orients an agent
  without it burning context on `ls -R`. Do not re-propose deleting these.
- **Chute does not display session STATE.** Removed 2026-09-04 after the founder asked twice. It
  claimed `Working (7)` over seven sessions of which none was working, because Terminal's `busy`
  flag and Claude Code's title glyph were both being read as evidence and neither is. Fixing the
  resolver left most sessions reading `—`. A status Chute cannot always know is a status it should
  not always claim: hooks report at turn boundaries, and an agent that ships no hooks (Antigravity)
  never reports at all. **Do not re-add groups, a badge count, or a "no status" label.** The menu is
  a list of terminals. The hooks stay for the session id, which is what resume, tmux and cost need.
- **The mark is the parachute**, decided 2026-09-03 by blind recognition, not by taste. "Chute"
  is the word and an airdrop is the tagline. Do not re-open it without running the same test.
- **`--naming` keeps two different defaults** — kebab in the terminal, underscore from Finder.
- **The app is the product; the CLI is the proof.** The app number is 80.7; 156.0 never appears
  in front of a buyer.
