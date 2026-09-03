# HANDOFF — the icon, the menu bar and the hooks handover — 2026-09-03/04

> A record of finished work, not a plan. The canonical entry point is `handoff/NEXT.md`.

## DONE 2026-09-03/04 (verified) — the icon, the menu bar, and the hooks handover

**The app icon is a parachute.** `Scripts/make-icon.swift` redrawn; `Resources/Chute.icns`,
`site/src/app/favicon.ico` and `brand/cards.py:draw_mark()` all regenerated from it. One command
does all three now — a mark kept in three hand-regenerated places is how a launch ships three
logos:

```bash
swift Scripts/make-icon.swift
```

**The finding, and it is the reusable one.** A design panel scoring craft, legibility and brand
ranked four candidates and put a lit-slot mark FIRST and the parachute LAST. A blind recognition
test — four unprimed viewers per image, neutral filenames, no product context, "what object is
this" — inverted it: every "document into a horizontal slot" mark read as a **paper shredder**
(4/4 at 128px for one, 4/4 at 32px for the other). The parachute read 4/4 · 5/5 · 4/4 · 4/5 at
128 · 64 · 32 · 16. A craft panel cannot catch a semantic misread, because a judge who has been
told what the product is can no longer un-know it. Full ledger in
`docs/specs/audit-2026-09-03-FINDINGS.md` §Icon redesign.

**Old icon:** 880px body on a 1024 canvas (Apple's grid is 824), no cast shadow, circular
corners. **New:** 14/28/54/104/206/412/824 at 16→1024, exact against Notes.app, shadow within 3
alpha levels at every size.

**`--naming` stays (audit P10).** Kebab for the bare CLI, underscore for the Finder menu: two
surfaces, two conventions, one binary. The defect was that it was in no help text. Fixed at
`Sources/chute/main.swift:16`; reason recorded at
`Sources/chute/Commands/FileCommands.swift:22`.

**`Scripts/build-app.sh` linked a stale object.** It globbed
`.build/release/ChuteCore.build/*.o`; SwiftPM never deletes the object of a renamed source, so
`TerminalAdapter.swift.o` sat beside `TerminalAppAdapter.swift.o` and the appex died on
`ld: 7 duplicate symbols`. Only reproduces with a warm `.build` across that rename, which is why
it survived — a cold clone builds fine. Now one object per source that still exists.

**The bundle is 2.8 MB, not 2.4.** The icns is 755 KB against 359 KB: ten natively-drawn slices
with real gradients. `build-app.sh` fails if `marketing/06-FACT-SHEET.md` disagrees, and it no
longer does. Every present-tense claim of 2.4 MB was updated; the historical ones (the changelog,
the LinkedIn `strip -x` posts) were deliberately left, and "2.4 MB" was deliberately NOT added to
the forbidden-claims table — the changelog renders it truthfully and the gate would fail on it.

**The menu bar carries the mark.** It was the SF Symbol `arrow.down.to.line` — the generic
download arrow `brand/tokens.json` says the mark must not be. `Sources/ChuteApp/MenuBarMark.swift`
draws it as a template image (alpha only; macOS tints it). Apple ships no parachute symbol —
checked. The first four drafts read as a HOT AIR BALLOON, because a balloon is a dome over a box
with short ropes; a parachute is a wide canopy, a small load, and a long steep drop. Blind test:
4/4 parachute, 0/4 balloon.

**`chute hooks merged` — one command instead of JSON you merge by hand.** The menu row used to
copy the raw `"hooks"` object. The founder pasted it back twice asking what it was, which is the
right reaction to a wall of shell with no destination, aimed at a 33 KB settings file that already
had 11 hooks from another tool in it. Chute still never writes `~/.claude/settings.json` — the
2026-08-27 rule stands. It computes the merged file and PRINTS it; the command it hands you does
the write, staged through `mktemp`, backup first, `&&` between every step.

**THREE FALSE PASSES, all found by perturbing:**
1. The first merge test was vacuous — the fixture already carried Chute's blocks, so the append
   path never ran and `blocks = [...]` (the exact bug) left the suite green.
2. `Scripts/smoke.sh`'s `HOME="$T"` isolation did NOTHING. `NSHomeDirectory()` reads the password
   database and ignores `$HOME`. All three isolated cases were reading the real
   `~/.chute/sessions`; "resume with no live session" passed only because the machine had no hook
   records, and failed the hour they were wired. `Sources/ChuteCore/Home.swift` now resolves
   `.chute` state where `$HOME` wins.
3. `nm -u … | grep -q` under `pipefail` reported the appex entry point missing from a binary that
   has it — `grep -q` exits on match, `nm` dies on the closed pipe. Same shape backed `has`/`hasnt`
   in smoke.sh and acceptance.sh: ~230 assertions that could flip at random. All here-strings now.

**Install and build now tell the truth.** `install.sh` installs over whatever copy exists rather
than always `~/Applications` (the founder's was in `/Applications`, so a "successful" install left
the old app running — a whole exchange was spent on "I see no change"). `$CHUTE_APP_DIR` overrides
it, because uninstall clears both folders and a reinstall would otherwise relocate the app.
`build-app.sh` names any installed copy whose COMMIT differs from the build's — not the timestamp,
which fired after every rebuild and taught you to ignore it.

**Verified end to end 2026-09-04:** uninstall leaves nothing (both app folders, `~/.chute`, the
CLI symlink, the appex registration, legacy Services) and correctly KEEPS the trial file, the
Homebrew CLI and every foreign hook. Cold clone-equivalent build + install: 39s. `chute doctor`
10/10.

