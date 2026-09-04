# Positioning — Chute

> Rewritten 2026-09-01. The previous version sold `unpack` — "paste an answer back, get real
> files" — as the headline. That command was deleted on 2026-08-31 because the ICP's agent
> already writes files to disk. Three assets kept selling it for a day. See §Gate at the bottom.

## Who this is for, and it is not "Mac users"

**People who drive Claude Code or Cursor all day.** Their agent already reads and writes files.
That single fact deletes most of what a general-purpose right-click suite sells, and it is the
reason six Finder rows were removed rather than polished (`handoff/HANDOFF-2026-08-31-icp.md`).

What is left is the part the agent CANNOT do for them: **telling it which files to look at.**
The agent can read anything once it is pointed at it. Pointing is manual, it happens dozens of
times a day, and nobody has automated it.

## One line

**Chute — point your agent at the files, in one right-click.**

## One paragraph

You already have an agent that can read your whole repo. You spend your day telling it *which
part*. Chute puts that in the Finder right-click: select the folders, click once, and every file
inside is on your clipboard as one blob with a token count — 17 times a day, 150 seconds down to
5. It is a 2.9 MB macOS app with no account, no subscription and no network code. The `chute`
CLI underneath is free and MIT forever, which is how you check every claim on this page before
you pay for any of it.

## The wedge — one job, one number

**Copy Files as Context.** 17×/day · 150 s by hand · 5 s with Chute · **41.1 min/day.**

That is over half the app's entire value in one menu row, and it is the row that makes someone
say *do that again*. Every asset leads with it. Nothing else goes above it.

Second: **Add to Context Basket** (8.2 min/day) — collect files from several folders across
several minutes, then hand the set over at once. It is the only row in the menu that nothing
else on the Mac ships, which makes it the demo that cannot be answered with "I'd script that".

## Category

Not a context-menu suite. Not a file manager. **The pointing layer for coding agents.**
Every competitor sells Windows-style right-click menus to general Mac users who existed before
agents did. Chute sells minutes to people who bill by the hour and run five agents at once.

## Positioning statement

> For developers who run Claude Code or Cursor all day, **Chute** puts "here are the files" in
> the Finder right-click, where their hands already are. Unlike context-menu suites like
> MagicMenu or iRightMouse — designed for general Mac users before agents existed — Chute does
> one loop: point the agent at the files, without typing a path.

**The app is the product; the CLI is the proof.** Decided 2026-08-28. The free CLI led the plan
for eight days, which trained the audience to want the free thing and then asked them to pay for
it. It stays free and MIT forever — it is the objection-handler, the audit trail and the
trial-substitute for the sceptic — but it is a footnote in the hero and one page at `/cli`.

## The honest arithmetic, which is also the sales argument

| Surface | Min/day | What it is |
|---|---|---|
| Finder menu | 75.8 | 5 rows, 9 actions — the paid app |
| Menu bar | 4.9 | which agent is waiting, zombie ports |
| **App total** | **80.7** | **the number on the page** |
| Free MIT CLI | 75.3 | yours for nothing, forever |
| All 19 jobs | 156.0 | never quote this at a buyer |

Derived from `site/src/lib/cases.ts`; `site/scripts/check-cases.mjs` fails the deploy if it
drifts from `docs/03-JTBD-LEDGER.md`. **Never quote 156.** Two thirds of it is free, a buyer
does that arithmetic in his head, and the answer he reaches is "so don't buy it."

## Proof points

| Claim | Evidence anyone can run |
|---|---|
| ~80 minutes a day | `site/src/lib/cases.ts`, re-derived from the ledger on every build |
| Safe in a repo an agent is about to rewrite | Preview-by-default, `clean` moves to Trash, `checkpoint` can only ever add a branch |
| Actually private | Zero network code except the `gist` command you invoke yourself |
| Not bloatware | 2.9 MB, zero third-party dependencies, no launch daemon, no background service |
| The claims are checkable | 911 unit assertions · 172 end-to-end · CI on macOS 13/14/15 |

## The competitive fact that decides how this is written

**Repo Prompt — the closest paid analogue, a well-liked native macOS app for feeding code to
LLMs — stopped charging on 2026-05-27 and open-sourced on 2026-06-13.** Its founder:
*"it's increasingly challenging to convince someone that they should pay me $15 a month … when
they can just prompt their agent to solve problems for them, and it 'just works.'"* (He also
joined OpenAI, so read it as a founder exit with a market-pressure justification, not a verdict.)

**Repo Prompt sold JUDGEMENT — which files matter. Chute sells MOTION — getting the bytes onto
the clipboard.** Judgement is what agents ate. Motion is not, because the agent is not the thing
holding the mouse.

Every asset must stay on the motion side of that line. **Any sentence drifting toward "Chute
picks the right files for you" is walking into the business that just closed.** And the packing
itself is not the pitch: repomix (28,148★) wins on packing quality outright and is free.

Evidence and the full field: `docs/research/competitors.md`.

## Objections

| They say | Answer |
|---|---|
| "My agent can already read files." | Yes. It cannot decide *which* ones. That is the 41 minutes. |
| "I'd just type `@src/`." | Then type it 17 times today. Chute is one click for eight files in three folders, with the token count before you paste. |
| "Raycast already does this." | Raycast is a launcher overlay. Chute lives where the files are — the Finder right-click — and knows what an agent needs. |
| "I'll write a shell script." | You'll write four, forget the flags, and never handle binaries, token counts or path traversal. The script is `chute`, it's MIT, and it's free — take it. |
| "repomix is free and better." | It is, at packing. Use it. This is a right-click you do 17 times a day without leaving Finder — **the precedent is Downie**, a $19.99 one-time GUI over free `yt-dlp` that has sold for years to people who know `yt-dlp` exists. Frequency, not capability, is the product. |
| "It's a paid wrapper around a free program." | Yes. So is Downie, so is every GUI anyone has ever bought. The free program is included, it is MIT, and it never expires — if the wrapper is not worth $19 to you, keep the free program. |
| "Another subscription?" | One payment. No account. Works offline forever. |
| "So the paid bit is a right-click menu?" | Yes, and that is the honest answer. The free CLI does all of it and you still won't type those paths 32 times a day. A sandboxed Finder extension is also the one part you cannot reasonably build yourself. |

## Voice

Terse. Concrete. Numbers over adjectives. Banned words are enforced, not advised — the list is in
`marketing/06-FACT-SHEET.md` and `site/scripts/check-claims.mjs` fails the deploy on any of them.
Show a 20-second screen recording instead of a feature list.

**Structural rule that matters more than any word list: pain before product.** No section, post
or page opens with a command name.

## Gate

Every `chute <command>` named in `marketing/*.md` is now checked against the CLI's dispatch switch
by `site/scripts/check-claims.mjs`. That file used to scan `README.md` and `docs/` only, which is
exactly why five marketing assets sold a deleted command for a day with every gate green.
