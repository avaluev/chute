# Recording by hand — technical spec

Everything here is performed by **you**, on the real screen. The scripted tapes in
`/Users/sxope/Documents/2026/Development/37.chute/demo/gui/tapes/` cover the Chute side; this
document covers the takes a script cannot honestly make.

---

## Why this exists

The wedge tape performed the manual ritual with cliclick and System Events and measured it at
**6.5 seconds**. The ledger says 150 s, because 150 s is what a *person* takes — looking, aiming,
reading, finding the next file. Frames 8 s to 90 s of that 95-second take are one static image
(`mse 0.13`): the robot had finished and the recorder ran on alone.

6.5 s beside Chute's 5.6 s does not argue for the product. It argues against it — and it would
have been printed under *"backed by a stopwatch, not an estimate"*.

**The rule this establishes:** a scripted take may measure the Chute side, never the manual side.
The product's latency is the same whoever triggers it. A human ritual is not.

---

## Before you start — five checks, ~2 minutes

Run this. It answers all five.

```bash
./Scripts/preflight-recording.sh
```

| # | What | Why it kills a take |
|---|---|---|
| 1 | Chute.app running (`pgrep -x ChuteApp`) | the Finder menu items do nothing, and the take films a menu with no effect behind it |
| 2 | Screen Recording granted to **Terminal** | `screencapture` exits within a second and the take is empty |
| 3 | Accessibility granted to **Terminal** | the cursor cannot be moved and menus cannot be typed into |
| 4 | `chute doctor` → 9/9 | a disabled Finder extension produces a right-click with no Chute rows |
| 5 | Do Not Disturb **on** | a notification banner inside the frame makes the take unusable |

Turn Do Not Disturb on by hand: Control Centre → Focus → Do Not Disturb.

---

## The take that matters: the manual ritual

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./demo/gui/by-hand.sh
```

It rebuilds the fixture, opens Finder at `~/Desktop/acme-app/src`, places a scratch TextEdit
window on the right, prints the choreography, counts you in, and records **open-ended** — the
recording stops when you press Return, so the take is exactly as long as the work.

### The choreography

Six files, in this order:

```
src/auth/session.ts   src/auth/token.ts   src/api/client.ts
src/api/routes.ts     src/ui/Avatar.tsx   src/ui/Nav.tsx
```

For each one:

1. Find it in the Finder window (left) and double-click it
2. `⌘A` select all
3. `⌘C` copy
4. `⌘W` close it
5. Click the TextEdit window (right), `⌘V` paste
6. **Type the file's name** after the paste — the agent has to be told what it is
7. `Return`

Then press **Return in the terminal** the instant the last paste lands.

### The four rules that decide whether the take is usable

1. **Normal pace.** Not fast, not careful — the pace you would use at 4 pm on a Thursday. This
   number goes on the landing page, so performing it quickly is lying about the product's value in
   the direction that *understates* it, and performing it slowly is lying the other way.
2. **Do not switch apps.** The frame is 1280×800 at (120,120) and records everything inside it.
3. **Do not narrate or pause to think about the recording.** If you fumble, stop, and run it again
   — a retake costs three minutes and there is no prize for salvaging a bad one.
4. **Step 6 is not optional.** A ritual that stops after the copy measures half the work and
   silently inflates the saving. That is the exact failure this apparatus exists to prevent.

### What happens when you press Return

| Step | What runs | What it protects against |
|---|---|---|
| `verify_take … 20` | duration ≥ 20 s, and frame at 1 s has `YMAX ≥ 60` | a take ended by a stray Return, and a fully black recording (limited-range black is Y=16, not 0 — the old threshold accepted it) |
| `emit_timing` | writes your seconds to `demo/out/gui/<slug>.json` | — |
| `compose_race` | 14 s of your ritual beside the Chute take, clocks burned in | — |

The race frame states *"two real recordings, aligned at their start"* and, on the last frame,
how many seconds of the ritual you are **not** being shown. It explains itself when reposted
without the page.

### Then, in order

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && open demo/out/gui/paste-a-whole-folder-into-your-agent-race.mp4
cd /Users/sxope/Documents/2026/Development/37.chute && make -C demo publish
cd /Users/sxope/Documents/2026/Development/37.chute/site && npm run check:cases
```

**`demo/out/` is gitignored.** `make -C demo publish` copies into `site/public/media/`, which is
tracked, and that is the only thing that makes a recording survive. Run it after every take.

### When the gate disagrees with you

`check:cases` compares your seconds against `docs/03-JTBD-LEDGER.md` within `max(3 s, 15 %)`.
If it fails: **the stopwatch wins.** Change the ledger, then let it cascade —
`site/src/lib/cases.ts` (`seconds`, `savedMinutes`) and `marketing/06-FACT-SHEET.md` (the
~80 min/day app-surface headline). `check:cases` re-derives the arithmetic and will not let you write a
figure the ledger does not support, including the assertion that the paid surface still carries
more minutes than the free CLI.

---

## Re-recording any hero by hand

The eight scripted tapes are the supported path and they work. Record one by hand only when its
tape produces something wrong on your machine.

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./demo/gui/tapes/<slug>.sh
```

To do it by hand instead: record the region yourself, save as
`demo/out/gui/<slug>.mov`, then run the delivery half without re-recording:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && bash -c 'source demo/gui/lib.sh; verify_take "<slug>" 8; export_web "<slug>"; verify_loop "<slug>"'
```

`export_web` produces the mp4, the webm and the poster frame at 1280 wide. `verify_loop` measures
the seam between the first and last frame and warns if the autoplaying loop will visibly jump —
**end the take where it began.**

### Social crops and a GIF, from any master recording

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./demo/reframe.sh demo/out/gui/<slug>.mov
```

Crops (never letterboxes) to 1920×1080, 1080×1080, 1080×1920 and 1080×1350 as mp4 + webm, plus a
two-pass-palette 900 px GIF and a poster frame, into `demo/out/social/`.

---

## Two cases still have no recording and no policy

`move-the-junk-an-agent-left` (`chute clean .`) and `open-a-terminal-where-you-are`
(`chute open .`). Both are Finder-surface shorts; neither has a tape. Five other cases are refused
on purpose by `demo/gen-shorts.mjs` and must never be filmed:

| Case | Why never |
|---|---|
| `share-a-file-without-a-repo` | `gist` uploads — filming it publishes a gist every rebuild |
| `keys-into-a-dotenv-without-pasting-them` | `env` reads the Keychain — a permission prompt on camera, or worse, none |
| `five-agents-one-command` | `sandbox` launches real terminals and agents — a re-record leaves five behind |
| `collect-files-over-several-copies` | `buf` reads the clipboard, which a one-liner cannot fill first |
| `an-image-as-one-line-of-text` | `dataurl` needs an image the fixture does not contain |

---

## Troubleshooting — every failure seen on this machine so far

| Symptom | Cause | Fix |
|---|---|---|
| Script exits printing nothing at all | `set -e` killed it on a failed command substitution before `die` could speak | already fixed in `take_menubar`; if it recurs, run the failing `osascript` by hand |
| `screencapture never started` | Screen Recording not granted to **this** terminal | System Settings → Privacy & Security → Screen Recording. Quit and reopen Terminal after granting |
| Right-click opens Finder's **tag** menu | the file list was addressed as "scroll area 1", which is the sidebar on a wide-sidebar Mac | fixed — it is the rightmost scroll area now |
| `cliclick` rejects a coordinate like `1225,,` | AppleScript `number & "," & number` builds a list, not a string | coerce each side `as text` before returning |
| Take films the wrong selection | Finder selects within **one container**; files from two folders silently become the subset that shares a parent | `select_files` counts the selection and dies now |
| Menu item never activates | a tracking context menu reads as an **empty** AX tree — by-name clicks can never work | type-ahead only, which is what `menu_pick` does |
| Loop "jumps" warning | the take does not end where it began | end on the same frame, or accept it for a case page that does not autoplay |

---

## The invariant, in one line

**`make -C demo/gui check` must stay green and must open nothing.** It is lint plus twelve
delivery assertions plus a dry run of every tape, it needs no screen and no permissions, and it is
the thing that told us a "safe" command was opening six files in TextEdit.
