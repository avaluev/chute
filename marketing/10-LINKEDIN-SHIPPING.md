# LinkedIn — the shipping-wall arc

> Written 2026-09-02 from `marketing/09-APPLE-AND-DISTRIBUTION.md`. Six posts, one thread: what it
> actually costs to put a Mac app in a stranger's hands in 2026, measured rather than complained
> about.
>
> **This is an arc inside the series, not a second series.** The rules, the cadence, the
> calibration and the "what to measure" list all live in `marketing/08-LINKEDIN.md` and are not
> repeated here — two copies of a rule drift the moment one is edited. Read that file first.

## Where this arc sits

`08` is twelve posts about **building** — deletions, bugs, gates. This arc is six posts about
**shipping**, and it is the one with a clock on it: the Homebrew cask deadline landed 2026-09-01
and the consequences are not yet widely written down. Posts A and B are perishable. Run them
first, before the observation is common.

Interleave, do not batch: `08` post 1 → **A** → `08` post 2 → **B** → … Six shipping posts in a
row reads as a man having an argument with Apple, which is a genre, and the genre is not credible.

**Post F cannot be written until the enrolment completes.** It is the payoff and it is the only
one with a measured before/after. Do not fake it; hold the slot.

---

## Post A — The six steps
**Ships:** first of this arc. Perishable.

**HOOK** (97)
> I built a Mac app. Then I measured what it costs a stranger to open it: six steps and a password.

**BODY**
> `spctl -a -vv dist/Chute.app` → `rejected`.
>
> That is my own app, on my own machine, built ten minutes earlier and signed with an identity I
> made myself. macOS is not wrong to reject it. I am nobody.
>
> Here is what a person who pays me $19 walks through on macOS 26:
>
> 1. Double-click. "Apple could not verify this app is free of malware." Two buttons: **Done** and
> **Move to Trash**.
> 2. Click Done. Nothing opens.
> 3. System Settings → Privacy & Security.
> 4. Scroll to Security.
> 5. Open Anyway.
> 6. Password. Back to Finder. Launch again. Confirm again.
>
> Note what is missing from step 1: any button that opens the app. The old right-click → Open
> trick is gone. The most obvious button on the first dialog a buyer ever sees is the one that
> deletes what they just bought.
>
> I had this filed under "polish". My own GTM doc had already written the correct version, in
> bold, three weeks earlier — *a stranger can install it and see the menu* is not a nicety, it is
> the business — and I had not connected the two sentences.
>
> A product whose first-run experience is a malware warning does not have a conversion problem. It
> has a floor, and the floor is roughly zero, and no amount of landing-page copy moves it.
>
> The fix costs $99 a year. I will come back with the measured after.

**VISUAL** — PDF carousel, 6 slides, 1080×1350. One step per slide, screenshot of the real dialog,
the button labels legible. Slide 1 is the `spctl` line in mono on the brand ground. Alt text on
every slide naming the dialog text, because the dialog text is the point.

**CTA**
> The whole thing is open: github.com/avaluev/chute

---

## Post B — The door that closed on the 1st
**Ships:** second. Most perishable thing in the entire campaign.

**HOOK** (85)
> The standard indie workaround for unsigned Mac apps stopped working on September 1st.

**BODY**
> For years the answer to Gatekeeper, if your users were developers, was Homebrew. Ship a cask,
> tell people to pass `--no-quarantine`, and the check never runs. Thousands of small Mac tools
> were distributed exactly this way.
>
> As of 1 September 2026, Homebrew ends support for casks that fail Gatekeeper checks, and the
> `--no-quarantine` flag is on its way out (Homebrew/brew #20755).
>
> I found this out while writing a memo arguing that I could defer paying Apple. The escape hatch
> I was reasoning about had shut the previous day.
>
> There is a distinction worth knowing, because it is the part that survives:
>
> **Casks ship binaries. Formulae ship source.**
>
> The quarantine attribute is applied to *downloaded* files. A binary your own compiler produced
> on your own machine was never downloaded — so Gatekeeper has nothing to check, and never runs.
> That is not a workaround, it is just what the mechanism does.
>
> Which is why the free half of my project has been installable by strangers this whole time,
> with no Apple ID, no warnings, no dialogs:
>
> `brew install avaluev/tap/chute`
>
> 46 seconds, from source, clean. It never depended on Apple and it still does not.
>
> If you distribute a Mac app through a cask and it is not signed, you have a deadline that has
> already passed. If you distribute through a source formula, nothing changed for you at all.

**VISUAL** — one image, not a carousel. Two columns, plain: **cask → downloads a binary →
quarantined → Gatekeeper** against **formula → compiles locally → not quarantined → never
checked**. Mono, brand ground, no icons.

**CTA**
> Homebrew's issue is #20755 if you want to read it yourself.

---

## Post C — Six sales
**Ships:** third.

**HOOK** (86)
> I spent three weeks routing around a $99 fee. My product costs $19. That is six sales.

**BODY**
> The Apple Developer Program is $99 a year. I had it filed as a blocker in my own runbook, in
> bold, for three weeks.
>
> Then I wrote the division down.
>
> $99 ÷ $19 = 6 units a year to break even. Six.
>
> The tool claims to save one developer about 80 minutes a day. The fee, expressed in the
> product's own units, is roughly **1.2 days of one user's time**.
>
> I had not avoided a cost. I had spent three weeks of planning — the actual scarce resource — to
> defer a cost that six customers erase.
>
> What made the mistake durable is that the reasoning around it was good. My own strategy document
> says, correctly, not to buy polish for the ideal customer before the early customer has
> validated anything. Notarisation, auto-update and terminal adapters all sat in one bucket
> labelled "later".
>
> Two of those are polish. One of them is the front door.
>
> Notarisation is not a feature the ideal customer wants. It is the condition under which the
> early customer can *see the product at all* — so it gates the validation that was supposed to
> justify it. I had built a circular dependency and called it discipline.
>
> The tell was available the whole time: a sound principle, applied to an item it does not cover,
> feels *more* rigorous than checking, not less. That is what makes it expensive.
>
> If you are deferring an infrastructure cost, do the division. Not the vibe — the division.

**VISUAL** — single slide, the arithmetic set large in mono, nothing else. `$99 / $19 = 6`.

**CTA**
> The memo, with the full arithmetic: github.com/avaluev/chute

---

## Post D — Sell the key, not the binary
**Ships:** fourth. The most technically useful post in the arc.

**HOOK** (97)
> There is a way to ship a paid Mac app that Gatekeeper never sees. I am not using it. Here is why.

**BODY**
> Gatekeeper checks downloaded binaries. So do not ship a binary.
>
> The shape:
>
> — Publish the source, all rights reserved. Readable and auditable, not redistributable.
> — Ship a Homebrew formula that compiles it on the buyer's machine.
> — Gate the paid surface on an offline signature check — mine is Ed25519, no network, no account.
> — **Sell the key, not the binary.**
>
> Anyone can build it. Only a key makes it keep working. Apple is not in the path at any point,
> and no dialog ever appears.
>
> Every piece of that already exists in my repo, because it is my own development loop. I did not
> design it as a distribution strategy; I noticed it was one.
>
> I am still paying Apple. Three reasons, and the third is the real one:
>
> **It asks for a password.** A locally-built Finder extension needs a code-signing identity the
> user's machine trusts, which means asking a security-minded developer to trust a certificate.
> That is precisely the interaction they have been trained to refuse, and they are right.
>
> **It forecloses every non-brew channel.** No Product Hunt, no download button, no buyer who
> does not own a compiler.
>
> **It is a clever answer to a question with a boring one.** $99 removes the whole problem for a
> year, in 48 hours of queue time. I like the clever version more, which is exactly the signal to
> distrust it.
>
> It stays as the free and audit channel, which is what it already was. It does not become the
> front door.
>
> Being able to see the elegant path and still take the boring one is most of engineering
> judgement, and it is the part nobody posts about.

**VISUAL** — carousel, 4 slides: the four bullets of the shape, one per slide, mono. Final slide:
"and I'm not using it", with the three reasons in small type.

**CTA**
> `Sources/ChuteCore/License.swift` if you want to see the key check.

---

## Post E — Two problems in one sentence
**Ships:** fifth. The one non-technical post; it is the one that travels furthest.

**HOOK** (91)
> "Can I sell this without an Apple account?" is two questions, and I answered the wrong one.

**BODY**
> Selling and delivering are separate problems with separate blockers, and I had them fused into
> one sentence for a month.
>
> **Selling** needs a merchant of record, a seller identity, and a domain a reviewer can load.
> Apple appears nowhere. Paddle has never asked me for a Team ID and never will. Stripe, Gumroad
> and Lemon Squeezy do not know what a `.dmg` is.
>
> **Delivering** needs the buyer's operating system not to treat the file as malware. That is the
> only place Apple appears — and it appears absolutely.
>
> Fused, the question has no answer and reads as a wall. Split, it has two answers and only one of
> them costs anything.
>
> I lost the time on the join, not on either half.
>
> This keeps happening to me and I suspect it is general. The compound question feels efficient —
> one decision instead of two — and it hides the fact that the halves have different owners,
> different costs and different deadlines. You cannot schedule it, because it is not a task. You
> cannot delegate it. You cannot even tell it is stuck, because "blocked on Apple" is a sentence
> that sounds like a status.
>
> The cheap test is to try to put a price on it. If a question does not take a single number, it
> is more than one question.
>
> "Can I sell without Apple?" — no number.
> "What does it cost to take money?" — $0 in Apple terms.
> "What does it cost for the file to open?" — $99/yr.
>
> Two numbers. So it was always two questions.

**VISUAL** — none, or one plain text card. This post is short-form thinking and an image dilutes
it. Text-only is a deliberate variation in a feed of carousels.

**CTA**
> No link. This one does not need one.

---

## Post F — The measured after
**Ships:** last, and **only after `spctl -a dist/Chute.app` says `accepted`.** Hold the slot.

**HOOK** (94)
> Six steps and a password became one double-click. Here is the diff, and what it actually cost.

**BODY**
> *Blocked. Write it from the measurement, not from the plan.*
>
> The skeleton, so it can be filled in the same hour the certificate lands:
>
> — `spctl -a -vv dist/Chute.app` before and after, verbatim, both lines.
> — Wall-clock from enrolment to a stapled DMG, in hours, including the queue.
> — Every step that went wrong. `Scripts/notarize-setup.md` already predicts four of them: the
> keychain prompt nobody answers, the missing secure timestamp, the hardened runtime blocking
> Apple Events, and the appex sandbox container pinning the old identity's cdhash. If the
> predictions hold, say so — a runbook that predicted its own failures is a better story than a
> smooth run.
> — The first-run experience for a real stranger on a real second Mac. Not a simulation.
>
> **Do not publish a version of this that says "and it all worked".** If it all worked, the post
> is the four predictions and which ones fired. If nothing fired, the post is that the runbook was
> written well, and say who wrote it and when.

**VISUAL** — the two `spctl` lines, before and after, as one image. Nothing else.

**CTA**
> Fill in when it ships.

---

## Production

Nothing here needs new tooling. Post A needs six screenshots of real dialogs on a Mac that has
never seen Chute — take them during the from-scratch reinstall, not staged. Post B needs one
two-column diagram. Post C needs one number set large. Post D needs a four-slide carousel. Post E
needs nothing. Post F needs the two `spctl` lines.

**The honesty gate that applies to all six:** every measured claim in this arc is in
`marketing/09-APPLE-AND-DISTRIBUTION.md` with the command that produced it. If a post states a
number that is not in that memo, it is not a post yet.

## Gate

`site/scripts/check-claims.mjs` reads the `**HOOK** (n)` blocks in **every** `marketing/*LINKEDIN*.md`
— it was hard-coded to `08` alone, so this file's hooks would have been the only ungated copy in
the campaign. Each hook must state its own true length and stay under the 140-character mobile cut.
Both halves are checked; neither is counted by eye.
