# HANDOFF — audit triage, truth pass, and the site rebuild — 2026-09-09

STATE: `main` / `7888959` / pushed · tests 1348/1348 (`swift run -c release chutetests`)
· smoke 183/183 (`CHUTE_HEADLESS=1 ./Scripts/smoke.sh`) · claims + cases green · eslint 0
· site deployed and verified live · tree clean

## ONE-LINE GOAL

Every public claim checkable by a gate, and a landing page that is fast and mobile-first.

## DONE (verified)

- **A video advertising a 14-day trial was live on the site.** `whats-on-port-3000.mp4`, filmed
  2026-08-28, showed a menu row reading "Trial — 14 days left", circular dots from before the
  squares, and the "Waiting for You (3)" counts removed in `2849347` for lying. Repointed at
  `screens/menu.webp`, assets deleted. Proved by extracting the frame, not by reading the file
  name.
- **Three ghost claims on the landing page** — `page.tsx` Trust list sold `unpack` and
  `clean-junk`, both deleted 2026-08-31. Gone.
- **`CLAUDE.md` opened with the fact sheet's row-one forbidden claim** for nine days.
- **"CLI under 1 MB" was false for every installable binary** (unstripped SwiftPM release is
  1,276,952 B). Fixed by making the claim TRUE — `strip -x` in the formula, 880,488 B.
- **`release.sh` could not cut the release it described.** It died without a Developer ID, so it
  had never run: the live v0.2.1 .dmg is unsigned, unstapled, spctl-rejected. Its notes said
  "Notarised by Apple." unconditionally. Signing is now optional and the notes match the build.
- **The published GitHub release notes** carried the forbidden claim + a stale 26-command count.
- **The privacy page** offered to delete a purchase record it elsewhere says never existed.
- **The site rendered every paragraph in Times New Roman** — see TRAPS.
- **204px of horizontal overflow at 390px** — seven grids missing a base `grid-cols-1`.
- **Typography**: 12 distinct font sizes → 6; monospace 18% of characters → 9%.
- **Media 1,854 KB → 383 KB**, losslessly (`menu` 239 KB → 30 KB).
- **The demo recordings showed the founder's real Finder sidebar and username.** Cropped
  1280x800 → 1020x638, holding the 1.6 aspect the `<video>` declares. Recordings KEPT, because
  three of them are what the stopwatch read and the FAQ says so.
- **A NUL byte in `--name` span forever** — see TRAPS. Fixed + tested.
- **The claims gate matched by substring** and so never fired — see TRAPS.

## IN FLIGHT

Nothing. Tree clean, nothing unpushed.

## NEXT

1. `cd /Users/sxope/Documents/2026/Development/37.chute` — upload
   `site/public/media/og.png` (1200x630) as the GitHub social preview at
   `github.com/avaluev/chute/settings`. **No API exists** — verified, the repo payload exposes no
   `open_graph` field. Four clicks, and the only item genuinely blocked on a human.
2. Optional: re-shoot the three demo recordings under a demo user account. The crop removed the
   exposure, so this is polish, not a leak any more.

## DECISIONS (do not re-litigate)

- **No `FUNDING.yml`.** `hasSponsorsListing: false` and `/sponsors/avaluev` redirects to the
  profile — the button would lead nowhere, which is the class of false affordance this week was
  spent removing. Reverse it if Sponsors is ever enabled.
- **11 of the 12 "missing recordings" are CLI cases**, where recordings were deliberately
  removed. The twelfth is a short-tier Finder row that would reuse an existing render. Not a gap.
- **Screenshot paths are FIXTURES.** `Scripts/menu-shot.swift:134` ("THE HOSTILE NAMES") invents
  `Norse Bank` and every other path to exercise truncation. Raised twice as a client-data leak;
  it never was one.
- **Variable fonts, not pinned weights.** Pinning `weight: ["400","500","600"]` measured 8 KB
  smaller (69.4 → 61.2 KB) and was rejected: nothing then ships a real 700, so every `<strong>`
  renders faux bold.
- **`col3TabStop` stays 540.** The empty strip right of `LOAD` is AppKit's own menu chrome, added
  AFTER the tab stop. 540 → 564 widened the whole menu by exactly the delta and moved the gap
  with it. Measured, reverted, documented in `StatusMenu.swift`.
- **Lossless webp for UI screenshots, LOSSY for photographic sources.** Lossless made the JPEG
  poster frames 46–66% BIGGER.

## TRAPS (paid for today — do not pay again)

- **A 404 that serves a fallback page is still a 200.** A deploy shipped an `index.html`
  referencing a stylesheet that was never uploaded; Cloudflare answered it with the fallback HTML,
  the browser refused the MIME type, and the site rendered as unstyled HTML — body in Times, 578px
  overflow — while every status-code check passed. `deploy-site.sh` now asserts CONTENT-TYPE on
  every referenced asset. Perturbed: real CSS → `text/css` passes, missing → `text/html` fails.
- **`/media/*` has no content hash and Cloudflare caches it 4h.** A "failed" media deploy is
  usually a stale edge. Re-request with `?cb=$RANDOM` before concluding anything.
- **next/font variables must sit on `<html>`, not `<body>`.** `brand.css` reads them at `:root`;
  one level up the `var()` is invalid, which makes the WHOLE declaration guaranteed-invalid, and
  custom properties are computed where declared — so `<body>` inherits the empty value rather than
  fixing it. The entire site rendered in Times. Introduced and fixed the same day.
- **A NUL byte made `writeUniquely` spin forever.**
  `appendingPathComponent("evil\0x.png")` → `""`; `URL(fileURLWithPath: "")` → the process's CWD;
  writing there throws CocoaError **516**, which IS `.fileWriteFileExists` — the exact error the
  retry loop treats as "name taken, try n+1". `candidate` returns `""` for every n, so it never
  terminated. Not a traversal: an unbounded spin from a CLI flag.
- **The claims gate matched forbidden claims by SUBSTRING.** The fact sheet writes the infinitive
  ("turn agent output back into files"); the prose wrote the third person ("turns"). One letter,
  and the gate reported green for nine days. Claims now match as word stems; perturb in BOTH verb
  forms.
- **A stale comment cost a KILL verdict.** An outside auditor read "STALE UNTIL SOMEONE PUBLISHES
  IT" in the formula and concluded `brew install` was broken. It had been fixed hours earlier.
  Correct the prose in the same commit as the value it describes.
- **`brew install` cannot detect a checksum break** — it passes on a cached tarball. Only
  `brew fetch --force avaluev/tap/chute` sees it.
- **Never run a build concurrently with a deploy** that reads the same `out/` directory.
- **`git add -A` is blocked by the guardrail hook**; `git add <paths>` and
  `git commit -- <paths>` pass.

## OPEN QUESTIONS FOR THE HUMAN

- The four demo recordings never show Chute's menu — macOS forbids recording another app's open
  context menu. Are they worth keeping at all, given the drawn menu in the hero is a better
  artefact? They currently earn their place by backing the stopwatch claim.
- An outside "Red Team" audit this morning returned **KILL**. Two of its three pillars were stale
  (the tap sha256 matched; v0.2.1 had both assets) and two security findings were false. Its
  worktree also staged real-shaped live credentials into `demo/fixtures/leaky.env.txt` while its
  report claimed zero files were modified. Worth deciding how much weight future external audits
  get before their findings drive work.
