# Can I sell a DMG without an Apple ID?

**Written 2026-09-02. Decision memo — read the verdict, then the arithmetic.**

> This exists because the question was asked as one question and it is two. Conflating them cost
> this project three weeks of planning around a wall that was in a different place than assumed.

---

## The verdict, in three lines

1. **Selling without Apple: yes, trivially.** Apple is not in the payment path. Paddle, Gumroad,
   Lemon Squeezy and Stripe do not know or care whether a `.dmg` is signed. Nothing about taking
   money requires an Apple ID.
2. **Delivering without Apple: effectively no, as of 2026.** An unnotarised app on macOS 26 Tahoe
   costs the buyer a six-step trip through System Settings, including a password. On a $19 impulse
   purchase that is not friction, it is the funnel.
3. **Enrol today. It is six sales, and it queues 24–48 hours.** $99/yr ÷ $19 = **6 units a year to
   break even.** The memo below is why the alternatives are worse, not why the fee is fair.

**The wall is not "can I sell". It is `A1` from `docs/09-GTM-DECISIONS.md` — "a stranger can
install Chute and see the menu" — which that document already calls, in bold, *the business*.**
Gatekeeper is A1's largest single term and it has been mispriced since 2026-08-26.

---

## The two questions, separated

| | Requires Apple? | Evidence |
|---|---|---|
| Take $19 from a stranger | **No** | Paddle is a merchant of record; its onboarding asks for a seller identity and a domain, never a Team ID |
| Host a `.dmg` for download | **No** | It is a file on a CDN |
| Have that `.dmg` open on the buyer's Mac without a detour | **Yes** | Notarisation requires Developer ID; Developer ID requires the $99/yr programme |
| Ship the free CLI | **No — and it already ships** | `brew install avaluev/tap/chute` builds from source; Gatekeeper is never invoked |

The fourth row is the entire problem, and the fourth row is the *only* row that needs Apple.

---

## What the buyer actually experiences today

`spctl -a -vv dist/Chute.app` → **`rejected`**, `origin=Chute Local Dev`.

That is a self-signed identity created by `Scripts/sign-identity.sh`. It stops macOS re-prompting
*the person who builds Chute* on every rebuild. It does nothing for a stranger, and the script's
own header says so.

On macOS 26 Tahoe, a stranger who downloads that DMG walks this path:

1. Double-click → *"Apple could not verify 'Chute' is free of malware."* Two buttons: **Done** and
   **Move to Trash**. There is no "open anyway" here. The most-clicked button on this dialog is
   Move to Trash.
2. Click **Done**. Nothing happens. The app does not open.
3. Open **System Settings → Privacy & Security**.
4. Scroll to **Security**.
5. Click **Open Anyway** beside a line naming the app.
6. Authenticate. Return to Finder. Launch again. Confirm a second dialog.

Six steps and a password, on a first run, for a $19 utility bought on impulse. Then the Finder
extension has to be enabled separately, which is `A1`'s *other* half.

**Do not model this as a conversion tax. Model it as a floor.** A buyer who reaches step 2 and
stops has already paid, and becomes a refund plus a review.

---

## The escape hatch that closed on 2026-09-01

The standard indie answer to Gatekeeper for a developer audience has been Homebrew:
ship a cask, tell people to pass `--no-quarantine`, and Gatekeeper never runs.

**That door shut the day before this memo was written.** Homebrew ends support for casks that fail
Gatekeeper checks as of **1 September 2026**, and the `--no-quarantine` / `--quarantine` flags are
being removed (`Homebrew/brew` issue #20755). A cask distributing an unsigned app is no longer a
plan; it is a formula that will stop working.

If any part of the GTM assumed "worst case, we go cask" — and the sequencing in
`docs/11-PHASE-0-RUNBOOK.md` reads as though it might — that assumption is now false. This is the
single most time-sensitive fact in the file.

---

## The escape hatch that is still open, and is already built

**A Homebrew *formula* that builds from source is not a cask and is not quarantined.** The
quarantine extended attribute is applied to *downloaded* binaries. A binary the user's own
compiler produced on their own machine was never downloaded, so Gatekeeper has nothing to check.

This is not a theory here. It is Phase-0 item 7, and it is already **DONE**:

> `brew install avaluev/tap/chute` → 0.2.0, from source, ~46 s, no warnings. `brew test` passes.
> *"And it never depended on (2) — the formula builds from source, Gatekeeper is not involved."*
> — `docs/11-PHASE-0-RUNBOOK.md`

So Chute already ships to strangers with no Apple ID. What ships that way is the CLI.

### Could the paid app ship the same way?

Technically, yes, and more of the pieces exist than one would expect:

- `Sources/ChuteApp/` and `Sources/ChuteFinder/` are **published source** — all rights reserved,
  readable and auditable, not redistributable. A formula that compiles them is the user building
  from source they are already permitted to read.
- `Scripts/sign-identity.sh` already creates a stable per-machine identity, which is what a Finder
  sync extension needs to keep its sandbox container.
- `Scripts/install.sh` already registers and enables the appex.
- `Sources/ChuteCore/License.swift` already gates the paid surface on an offline Ed25519 signature.
  **The product is monetised by the key, not by the binary.** Anyone can already build it; only a
  key makes it keep working past the trial.

Which means a coherent option exists: **sell the key, distribute the source, let the buyer's own
compiler defeat Gatekeeper.** `brew install avaluev/tap/chute-app` — no DMG, no Apple, no wall.

### Why that is the second choice and not the first

- It requires the buyer to have a working Swift toolchain and to accept a ~46-second build. For
  this ICP — Claude Code and Cursor users — that is close to universal, which is the strongest
  argument for it.
- It requires the buyer to trust a self-signed certificate for code signing, which asks for their
  login password and is exactly the interaction security-minded developers are trained to refuse.
- It forecloses **every non-brew channel**: Product Hunt, the plain "Download for Mac" button, any
  buyer who is a designer or a founder rather than a compiler owner.
- It is a rung-7 solution to a problem with a rung-1 answer. $99 removes it for a year in
  48 hours of queue time.

**Keep it as the permanent free and audit channel, which is what it already is. Do not make it
the paid product's only door.**

---

## The arithmetic that settles it

| | |
|---|---|
| Apple Developer Program | **$99/yr** |
| Price of Chute | **$19 one-time** |
| **Break-even** | **6 units per year** |
| Ledger value of the app surface | 80.7 min/day |
| $99 expressed in the product's own units | **~1.2 days of the time it claims to save one user** |

A fee that is recovered by six sales is not a business risk. Treating it as one for three weeks
was the risk.

The counter-argument that *does* hold: **do not pay it before the thing is worth installing.**
`docs/09-GTM-DECISIONS.md` §3 is right that ICP polish must not be bought before ECP validation.
But notarisation is not ICP polish. It is the difference between a stranger seeing the product and
a stranger seeing a malware warning — it gates the validation itself.

---

## What to do, in order, tonight

1. **Enrol.** <https://developer.apple.com/programs/enroll/> — Individual / Sole Proprietor.
   `docs/11-PHASE-0-RUNBOOK.md` §STEP 1 has the exact fields. It queues 24–48 h, so it is the only
   item here that must start before sleep.
2. **While it queues, do the five same-day blockers** — the Ed25519 key, the two CNAMEs, mail, the
   Paddle product, the Worker deploy. None of them need Apple. `docs/11-PHASE-0-RUNBOOK.md`.
3. **When the Team ID lands**, `Scripts/notarize-setup.md` end to end, then
   `./Scripts/release.sh --dry-run` and read the last line.
4. **Retire the FALSE-table row** for "notarized" the moment `spctl -a dist/Chute.app` says
   `accepted`. `site/scripts/check-claims.mjs` now derives that row from `spctl` rather than from a
   hand-typed string, so it retires itself — see §Gate below.

---

## What this memo is worth as content

The wall above is measured, dated, timely and unflattering, which is the whole recipe for the
LinkedIn series. The Homebrew deadline landed on 2026-09-01; almost nobody has written the
consequences down yet. `marketing/10-LINKEDIN-SHIPPING.md` is the six posts that come out of this
file, and every one of them cites a line in it.

**Do not write those posts as "Apple is greedy."** The measured finding is more interesting than
the grievance: *the platform fee was never the cost — the cost was three weeks of planning around
a wall I had not measured, and an escape hatch that closed while I was planning.*

---

## Gate

Two changes in `site/scripts/check-claims.mjs` back this file:

1. **The "notarized" row is derived from `spctl -a dist/Chute.app`, not from a string.** A word
   list cannot tell a claim from a denial, so it forbade the site from discussing the wall at all.
   The check now forbids the affirmative forms while the artifact is `rejected`, and passes them
   the moment it is `accepted` — the row retires itself, with no human remembering to strike it.
2. **The LinkedIn hook check scans every `marketing/*LINKEDIN*.md`**, not `08` alone. It was
   hard-coded to one filename, so this file's companion series would have shipped ungated —
   the identical failure that let five assets sell a deleted command for a day.
