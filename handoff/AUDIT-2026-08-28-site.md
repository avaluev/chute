# AUDIT — chutedev.com site + deploy gates — 2026-08-28

**VERDICT: NOT clear to submit for Paddle domain review.** All three gate scripts currently
report green (0 failures) against the existing `site/out` build, but they are green because none
of them checks the two things that are actually wrong: `/changelog` describes the Finder menu
using titles that were renamed in the same day's commit and states a stale version/size, and
`/privacy` asserts the site runs analytics that do not exist anywhere in the repo. Fix those two
pages, then re-run all three gates (they will still pass, because neither defect is inside their
checked surface — see §2).

Read this after `git log --oneline -3` in
`/Users/sxope/Documents/2026/Development/37.chute` — commit `e82fe41` (13:23) merged
`fix/finder-menu-clarity-and-checkpoint`, renaming several Finder action titles and adding
`checkpoint` to the Finder menu for the first time. `site/out` was built at 00:53, i.e. *before*
that merge, but the *site source* (`site/src/**`) was last touched at 00:51–00:53 too — so the
site's own text has not been updated for the rename either. Everything below compares site copy
in `/Users/sxope/Documents/2026/Development/37.chute/site/src` against the current (post-13:23)
product, via `swift run chute finder-actions --menu` and `git show` on the rename commit.

---

## Findings

### HIGH — `/changelog` names pre-rename Finder action titles verbatim
**File:** `/Users/sxope/Documents/2026/Development/37.chute/site/src/app/changelog/page.tsx:17`
```
"Finder right-click: copy full paths, copy files with contents (with a token count), copy a
folder tree at three depths, paste an image from the clipboard, new markdown file, open in
Terminal."
```
Evidence of the rename (`git show e82fe41 -- Sources/ChuteCore/FinderActions.swift`):
```
-  title: "Copy Files with Contents ({n})"     +  title: "Copy Files as Context ({n})"
-  title: "Paste Image from Clipboard"          +  title: "Image from Clipboard"
-  title: "New Markdown File"                   +  title: "Empty Markdown File"
-  title: "New Clean Room for an Agent"          +  title: "New Scratch Folder"
```
"copy files with contents", "paste an image from the clipboard" and "new markdown file" are the
**old** titles, word for word. The current menu (`swift run chute finder-actions --menu`, run
2026-08-28) also has three rows this list never mentions at all: **Save Clipboard as Files…**,
**Set Up for an Agent ▸** (Add Agent Rules / New Scratch Folder / Save a Checkpoint), and
**Move Junk to Trash…**. The changelog entry predates most of the shipped Finder surface.

Same entry also says `version: "0.1.0", date: "Unreleased"` and `"25 CLI commands, zero
dependencies, 2.5 MB."` — but `brew info avaluev/tap/chute` (run read-only during this audit)
reports the tap installs **0.2.0**, and the site's own FAQ and `/cli` page both say the CLI
binary is **788 KB**, not 2.5 MB (`site/src/app/page.tsx:44`: *"A 2.5 MB app and a 788 KB
command-line binary"*; `site/src/app/cli/page.tsx:39`: *"...no account, 788 KB."*). The
changelog's "2.5 MB" figure contradicts two other pages on the same site.

**Failure scenario:** a Paddle reviewer or a technical buyer opens `/changelog` (linked from
nowhere in nav, but publicly reachable and indexable — see LOW-2), reads a feature list that
doesn't match the app they just downloaded, and a size figure that contradicts `/cli` on the same
domain. Internal inconsistency on a legal/marketing page is exactly the kind of thing that reads
as untrustworthy to a reviewer explicitly checking for "a clear description of your product."

**Smallest fix:** rewrite the `RELEASES[0].notes` array in
`/Users/sxope/Documents/2026/Development/37.chute/site/src/app/changelog/page.tsx` to the current
action titles and version `0.2.0`, and change `2.5 MB` to `788 KB` (or drop the size claim from
this line entirely, since it's already stated correctly on two other pages).

### HIGH — `/privacy` claims the site runs analytics that do not exist in the codebase
**File:** `/Users/sxope/Documents/2026/Development/37.chute/site/src/app/privacy/page.tsx:45-50`
```
<H2>This website</H2>
<p>
  Cookieless page analytics, so we can tell whether anyone read this. No cookies, no
  cross-site tracking, no advertising pixels, no session recording. Nothing that would let
  us identify a visitor.
</p>
```
Verified during this audit:
```
grep -rln "analytics|plausible|fathom|umami|goatcounter|gtag" site/src site/public site/next.config.ts
  → only site/src/app/privacy/page.tsx itself (the claim text)
grep -io "plausible|fathom|umami|goatcounter|gtag|analytics" site/out/index.html
  → no matches
```
There is no analytics script tag, no third-party script in `layout.tsx`
(`/Users/sxope/Documents/2026/Development/37.chute/site/src/app/layout.tsx`), nothing in
`next.config.ts`, and nothing in the built `out/index.html`. The privacy page describes a
capability the site does not have.

**Failure scenario:** this is a public legal document making a specific, falsifiable technical
claim ("cookieless page analytics"). Anyone who reads the page source or a network tab to verify
it (which is exactly what a privacy-conscious buyer of a "zero telemetry" tool is likely to do,
per the site's own FAQ answer "Does it phone home? No.") finds the claim is false. Either ship the
analytics or remove the sentence — right now the privacy page is wrong in the "we do more than we
say" direction, which is the more damaging direction for a privacy policy to be wrong in.

**Smallest fix:** delete the "This website" analytics paragraph in
`/Users/sxope/Documents/2026/Development/37.chute/site/src/app/privacy/page.tsx:45-50`, or replace
it with the true statement ("No analytics on this website either — same policy as the app").

### MEDIUM — `checkpoint` (JTBD 12) is classified as CLI-only/free, but it is now a paid Finder action
**File:** `/Users/sxope/Documents/2026/Development/37.chute/site/src/lib/cases.ts:244-254`
```ts
slug: "a-snapshot-before-you-let-it-run",
jtbd: 12, surface: "cli", tier: "short", paid: false,
```
`Sources/ChuteCore/FinderActions.swift:233-246` (current, post-13:23 merge) defines
`checkpoint-here` as a real row under **Set Up for an Agent ▸ Save a Checkpoint**, with a comment
explicitly noting the change: *"JTBD #12... the largest number in the ledger that had no Finder
surface at all"* (past tense — it now does). `cases.ts` was not updated to reflect this: the site
still tells readers checkpoint is free-CLI-only (`surface: "cli"`), when the app now also exposes
it as a paid right-click action.

**Effect:** `PAID.length` (used verbatim on the landing page: *"eight rows"*, `/buy` page,
`/cases`) and `appMinutes` (the "130.7 min/day" figure the app is sold on — confirmed via
`npm run check:cases` output) both undercount by omitting checkpoint's 3.3 min/day from the paid
column. This understates rather than overstates the app's value, so it's not a false claim in the
dangerous direction, but it is demonstrably wrong relative to the current product, and it's the
same drift pattern as the HIGH findings above: site copy not updated after a same-day Finder-menu
change.

**Smallest fix:** in `cases.ts`, change the `a-snapshot-before-you-let-it-run` case to
`surface: "finder", paid: true` (matching every other Finder-menu case), then run
`node scripts/check-cases.mjs` — its internal rule (`if (!c.paid && c.surface !== "cli") bad(...)`)
will re-validate the new classification is self-consistent.

### MEDIUM — none of the three gates cross-check site copy against `Sources/` (root cause of the above)
`check-cases.mjs` validates `cases.ts` against `docs/03-JTBD-LEDGER.md` only. `check-claims.mjs`
validates rendered pages against a hand-maintained blocklist in `marketing/06-FACT-SHEET.md`.
`check-paddle.mjs` validates page/asset/seller/refund presence. **None of the three ever reads
`Sources/ChuteCore/FinderActions.swift` or `Sources/chute/main.swift`** — the actual source of
truth for what's in the Finder menu and what CLI commands exist. That's why the checkpoint
misclassification (MEDIUM above) and the stale changelog titles (HIGH above) both shipped: nothing
in the deploy gate can detect "the site names a Finder action that doesn't exist" or "the site is
missing a Finder action that does exist" or "the CLI command count/names on `/docs` drifted from
`Sources/chute/main.swift`."

**Concrete way this breaks silently in future:** rename or remove a Finder action in
`FinderActions.swift`, ship it, and every one of the three gates still exits 0 — verified by
running all three against the current build (all green) while the checkpoint/changelog drift
above already existed uncaught.

**Smallest fix:** not attempting to fully close this gap (it requires a Swift↔TS bridge), but the
cheapest partial fix is a new assertion in `check-cases.mjs`: for every `CASES` entry with
`surface: "finder"`, grep `Sources/ChuteCore/FinderActions.swift` for a `title:` string
containing a matching keyword, and fail if none is found — catches removed/renamed actions a case
still refers to, though not the reverse (an action with no case).

### MEDIUM — `check-claims.mjs`'s core check is a static blocklist, not a truthfulness check
**File:** `/Users/sxope/Documents/2026/Development/37.chute/site/scripts/check-claims.mjs:48-65`
`FALSE_CLAIMS` is parsed from marketing/06-FACT-SHEET.md's *"Claims that are currently FALSE"*
table — i.e. a list of **previously discovered** false claims. Any claim that is false but was
never caught and added to that table is invisible to this gate. This is demonstrated directly by
this audit: both HIGH findings above (stale changelog titles, fabricated analytics claim) are
false, user-facing claims on pages this script reads (confirmed: `check:claims` output says
`38 rendered pages read` and `4 forbidden claims read from the fact sheet` / `0 failed`) — the
script simply has no way to know they're wrong, because nobody had put them on the FALSE list yet.

**This is the "vacuous pass" the audit was asked to look for:** `npm run check:claims` prints
*"every claim on the site is one the fact sheet stands behind"* — a statement that sounds like a
general truthfulness guarantee but is actually only true of the ~4 specific historical strings in
the table. A brand-new invented number or capability sails through with 0 failures.

**Smallest fix:** none that's cheap and general — this is what §MEDIUM above (cross-check against
Sources) is for. At minimum, rename the closing log line so it doesn't overstate what was checked,
e.g. `"no previously-flagged false claim reappeared"` instead of `"every claim on the site is one
the fact sheet stands behind."`

### LOW — `check-paddle.mjs`'s page/asset checks cover only the 7 REQUIRED routes, not the whole site
**File:** `/Users/sxope/Documents/2026/Development/37.chute/site/scripts/check-paddle.mjs:49-127`
`REQUIRED = ["/", "/buy", "/terms", "/refunds", "/privacy", "/support", "/docs"]`. Section 6c
("every referenced asset resolves") only scans `Object.values(pages)`, i.e. those 7 pages. It
never reads `/cases`, the 25 `/cases/<slug>` pages, `/cli`, or `/changelog`. A 404'd demo GIF on
a case page (there are 6 of them, per `demo:` fields in `cases.ts`) would not be caught by
`check:paddle`. (`check-claims.mjs` does scan every rendered page — `readdirSync` recursively over
`out/` — but only for the FALSE_CLAIMS/banned-word text checks, not asset existence.)

**Concrete way this breaks uncaught:** delete or rename a file under `site/public/media/` that a
`/cases/<slug>` page's `demo` field still points to — `check:paddle`, `check:claims` and
`check:cases` (which only *notes* "referenced media that no case refers to" — the opposite
direction, see `check-cases.mjs:143-155`) all pass; the broken image ships.

**Smallest fix:** widen `check-paddle.mjs`'s asset-resolution loop (section 6c) to scan every
`.html` file in `out/`, the same way `check-claims.mjs`'s `pages()` helper already does, rather
than only the 7 `REQUIRED` routes.

### LOW — hardcoded domain literal instead of `CONFIG.domain`
**File:** `/Users/sxope/Documents/2026/Development/37.chute/site/src/app/layout.tsx:14,22`
```ts
metadataBase: new URL("https://chutedev.com"),
...
url: "https://chutedev.com",
```
`src/lib/config.ts:3` documents itself as *"Everything that changes when a price, a domain or a
store account changes. One file."* — `CONFIG.domain = "chutedev.com"`. Every other page that
needs the domain uses it correctly (e.g. `site/src/app/cli/page.tsx:14`:
`` `https://${CONFIG.domain}/cli/` ``). `layout.tsx` is the one place that didn't. Not currently
wrong (values match), but it's the exact hardcoding the file's own comment warns against, and a
future domain change would silently miss these two spots since nothing greps for stray literals.

**Smallest fix:**
```ts
import { CONFIG } from "@/lib/config";
metadataBase: new URL(`https://${CONFIG.domain}`),
...
url: `https://${CONFIG.domain}`,
```

### LOW — `/cases` index skips heading level (h1 → h3, no h2)
**File:** `/Users/sxope/Documents/2026/Development/37.chute/site/src/app/cases/page.tsx:19` (h1)
renders `<CasesGrid>` → `<CaseCard>` in
`/Users/sxope/Documents/2026/Development/37.chute/site/src/components/case-bits.tsx:75`, whose
only heading is `<h3>{c.pain}</h3>` — no `<h2>` anywhere on the page in between. Every other page
that uses `CaseCard` wraps it in a `Section`/`H2` first (home page, `/cli`), so this is the one
page where the hierarchy skips a level — a WCAG 1.3.1/2.4.6 best-practice miss, not a hard
failure, and screen-reader users navigating by heading level will see h1 followed directly by
several h3s.

**Smallest fix:** give `/cases` an `<h2>` (visually hidden or styled as a section label) before
`<CasesGrid>`, e.g. wrapping the filter bar with a "Filter by" or "All jobs" `<h2>`.

### No findings — Paddle checkout degradation (task question 3)
`BuyButton` (`/Users/sxope/Documents/2026/Development/37.chute/site/src/components/buy-button.tsx:16-36`)
and `CheckoutBridge`
(`/Users/sxope/Documents/2026/Development/37.chute/site/src/components/checkout-bridge.tsx:53-93`)
both check `CONFIG.paddle.token`/`priceId` before touching the Paddle SDK. With both empty (their
current state, confirmed via `CONFIG.paddle.token = process.env.NEXT_PUBLIC_PADDLE_TOKEN ?? ""`),
`BuyButton` renders a plain-language explanation ("Checkout is not open yet — Chute is still in
its trial-only release") and a working trial-download CTA — never a dead/disabled button with no
explanation. `CheckoutBridge` only activates when Paddle redirects back with `?_ptxn=`, and if the
token is still missing at that point it shows a `role="alert"` message with a mailto fallback,
never a blank page. This is the safe, honest degradation the task asked about — no defect found.

### No findings — colour contrast tokens (task question 4)
Sampled every foreground/background pairing defined in
`/Users/sxope/Documents/2026/Development/37.chute/site/src/app/brand.css:28-51` against WCAG 2.1
relative-luminance contrast: `--muted-foreground` (#8A93A6) on `--background` (#0D0F17) ≈ 6.2:1;
`--color-accent-chute` (#8FDB70) on background ≈ 11.4:1; `--primary-foreground` (#0D0F17) on
`--primary` (#8FDB70) button fill ≈ 11.4:1; `--destructive` (#E06C75) on background ≈ 6.0:1. All
comfortably clear WCAG AA's 4.5:1 for normal text. No finding.

### No findings — alt text
Every `<Image>` usage in `site/src` (`page.tsx:101,162`, `case-bits.tsx:58-59`) carries a
non-empty, meaningful `alt` — either `alt={c.fix}` (the case's own one-line description) or a
written caption. No raw `<img>` tags, no missing or empty `alt=""` on a meaningful image.

### No findings — "no network code except gist" claim
`grep -rn "URLSession|URLRequest|dataTask" Sources` → zero matches anywhere in
`/Users/sxope/Documents/2026/Development/37.chute/Sources`, including the `gist` command, which
shells out to the user's own `gh` binary rather than opening a socket itself. The trust-section
claim on the home page (`site/src/app/page.tsx:207`, *"There is no network code in Chute at all...
Check it: grep -rn URLSession Sources/"*) is accurate and independently reproducible exactly as
worded.

---

## 1. Truthfulness — summary
Price ($19), trial (14 days), refund window (30 days), "offline / no account / zero telemetry",
brew install command, and the Finder-menu row count ("eight rows") all check out against
`Sources/` and `docs/03-JTBD-LEDGER.md`. The two real problems are `/changelog` (stale pre-rename
Finder titles + wrong version/size) and `/privacy` (analytics claim with no implementation) — see
HIGH findings above. The `checkpoint` Finder-menu classification in `cases.ts` is stale in the
undercounting direction (MEDIUM). No old Finder-menu titles were found anywhere else in
`site/src` (`Copy Files with Contents`, `Write Clipboard Files Here`, `New Markdown File`, `Paste
Image from Clipboard`, `New Clean Room for an Agent` — none appear outside `/changelog`).

## 2. Gate scripts — summary
All three (`check-paddle.mjs`, `check-cases.mjs`, `check-claims.mjs`) ran clean against the
existing `site/out` build (commands and full output captured during this audit). Each does real,
non-vacuous work within its stated scope (page/asset existence, seller/refund text, cases-vs-ledger
arithmetic, blocklist enforcement) — none loops over an empty list or has a check that can never
fail by construction. Their actual weakness is scope: none reads `Sources/` (Swift) at all, so
Finder-menu/CLI-command drift is invisible to all three (MEDIUM); `check-claims.mjs`'s truthfulness
check is a historical blocklist, not a general one (MEDIUM); `check-paddle.mjs`'s asset-resolution
check only covers 7 of the site's ~38 rendered pages (LOW).

## 3. Paddle checkout path — summary
Safe and honest. See "No findings" above.

## 4. Accessibility/correctness — summary
Contrast and alt text: no findings. Heading order: one skip on `/cases` (LOW). One hardcoded
domain literal that should read `CONFIG.domain` (LOW). No 404 links found among footer/header nav
targets (spot-checked all 8 footer links against actual routes in `site/out`); `/changelog` exists
but is not linked from nav (orphan page, not a defect by itself).
