---
name: chute-focus
description: Keep Chute's docs and site pointed at the app, not the CLI. Load before editing README.md, marketing/*.md, site/src/app/**, or any content/copy/docs change in this repo — landing pages, the CLI reference page, FAQ text, changelog entries, anything a reader sees.
---

# Chute focus

## The one rule

**The product is the Finder right-click menu and the menu bar.** Those are the two surfaces
Chute exists to sell. The `chute` CLI is the same engine, free and MIT, for people who prefer a
terminal — it is proof (read the source, run it, decide) and an objection-handler ("I'd just
write a script"), **never the pitch**. A page, README section or post that opens with a `chute`
command or `brew install` before it names Finder or the menu bar has the story backwards.

This is not a style preference. On 2026-09-08 the founder called the previous README and site
"bullshit information about the project" for leading with CLI commands and burying the app.

## Before you touch content

1. **Where does the CLI belong in this file?** One clearly-marked section, near the bottom,
   framed as "same engine, terminal instead of right-click" — not a feature list competing with
   the Finder menu or menu bar sections above it.
2. **Does the change move CLI content above the first Finder/menu-bar mention, or thicken the
   CLI:surface ratio near the top of the file?** If you're not sure, run the gate (below) — it
   measures this, you don't have to eyeball it.
3. **Do not delete the CLI reference pages** (`site/src/app/cli/page.tsx`, `/docs`). Demote,
   don't remove — they're where the free/MIT proof lives for someone who goes looking.

## The gate — run it after every content change

```
./Scripts/check-focus.sh
```

A ratchet, not a one-time check: it compares README.md and the top-level site pages against a
committed baseline (`Scripts/focus-baseline.txt`). Numbers may fall freely; they may never rise
without someone deliberately re-recording with `--record` — which is a visible line in a diff. If
it goes red, the fix it prints is the fix — apply it, don't re-record over it. Read its own header
comment for exactly what it measures and what it cannot catch (source text, not the rendered
page; it's a word-list heuristic, not a reader).

## The banned claims still apply

`marketing/06-FACT-SHEET.md` §"Claims that are currently FALSE" is enforced by
`site/scripts/check-claims.mjs` and applies to every file you touch here too — most relevantly:
no price, no trial, no licence key (Chute is free and MIT, full stop); never "nothing is
uploaded, ever" (`chute gist` uploads on request — say the precise version); never claim Intel
support (the build is arm64 only); no number typed by hand where a command could derive it. Run
`cd site && npm run check:claims` before calling a content change done.
