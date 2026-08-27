# Positioning — Chute

## One line
**Chute — drop context into your agent.**

## One paragraph
Chute is a macOS app for people who spend their day driving coding agents. Right-click a folder
in Finder and every file inside it is on your clipboard as one blob with a token count.
Right-click again and an agent's multi-file answer becomes real files — after it shows you the
list. The menu bar tells you which of your nine terminals is actually waiting for you. It is
offline, has no account, and costs one payment. The command-line tool underneath is free and
MIT forever, and it is how you check the claim before you pay it.

## Category
Not a "right-click enhancer". Not a file manager. **Context plumbing for agent workflows.**
The category framing matters: every competitor sells Windows-style context menus to general Mac
users. Chute sells minutes back to people who bill by the hour and run five agents at once.

## The wedge
`chute bundle` — select eight files, get one XML blob with a token count on the clipboard.
Nobody else does this. It is the single largest time saving in the ledger (41 min/day) and it is
the thing that makes someone say "wait, do that again".

## Positioning statement
> For AI product builders who run coding agents all day, **Chute.app** is a macOS app that turns
> your Finder selection into agent-ready context and turns agent output back into files. Unlike
> context-menu suites like MagicMenu or iRightMouse, which were designed for general Mac users
> before agents existed, Chute is built for one loop: context in, artifacts out.

**The app is the product; the CLI is the sample.** Decided 2026-08-28, replacing the two-wave
launch in `05-CONTENT-CALENDAR.md`. The free CLI led the old plan for eight days, which trained
the audience to want the free thing and then asked them to pay for it. It stays free and MIT
forever — it is the proof, the objection-handler and the trial-substitute for the sceptic — but
it is a footnote in the hero and one page at `/cli`, not the launch.

**What makes this defensible now:** the four highest-value jobs in the ledger — unpack (28.5
min/day), seed (9.9), sandbox (7.3), clean (6.6) — were CLI-only until 2026-08-28. The app
demonstrated ~73 min/day while the free tool demonstrated ~125, so a buyer's own arithmetic told
them not to buy. It is now **130.7 min/day for the app against 86.8 for the CLI**, and
`site/scripts/check-cases.mjs` fails the deploy if that ever inverts again.

## Proof points
| Claim | Evidence |
|---|---|
| The app saves 130.7 min/day | `site/src/lib/cases.ts`, re-derived from `docs/03-JTBD-LEDGER.md` on every build |
| Safe with your repo | Preview-by-default, path-traversal refusal, checkpoint that cannot touch your worktree |
| Actually private | No network code except the gist command you invoke yourself |
| Not bloatware | 328 KB app, zero dependencies, no launch daemon |

## Objections
| They say | Answer |
|---|---|
| "Raycast already does this" | Raycast is a launcher overlay. Chute lives where the files are — the Finder right-click — and knows what an agent needs. |
| "I'll write a shell script" | You will write four, forget the flags, and never handle binaries, token counts, or path traversal. Free 14-day trial. |
| "Another subscription?" | One payment. No account. Works offline forever. |
| "So the paid bit is just a right-click menu?" | Yes — that is the honest answer, and it is worth $19 because the free tool does all of it and you still won't type those paths 32 times a day. A signed, sandboxed Finder extension is also the one part you cannot reasonably build yourself. |
| "Unsigned app?" | Fair — v0.1 is direct-download. Notarization ships with the launch build; do not launch before it. |

## Voice
Terse. Concrete. Numbers over adjectives. Never say "revolutionary", "seamless", "powerful".
Show a 20-second screen recording instead of a feature list.
