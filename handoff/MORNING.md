# Morning runbook — 2026-08-28

Do these in order. Each step says what to run, what you should see, and what it unblocks.
**Steps 1–3 are the only things nobody but you can do.** Everything after them is unblocked work.

Total hands-on time: about 50 minutes, plus a wait on Apple.

---

## Step 0 — Prove the build still works (3 min)

```bash
swift run chutetests && ./Scripts/smoke.sh
```

Expect `0 failed`. The exact tallies live in `marketing/06-FACT-SHEET.md` §Verification —
that is the only file that carries them, because four copies disagreed once already.
Numbers may be higher — that is fine. **Any failure: stop and paste it to me.**

Then look at the menu you are selling:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && .build/release/chute finder-actions --menu
```

Expect 8 rows. Read them as a stranger would. If a row's wording is wrong, that is the cheapest
possible moment to say so.

---

## Step 1 — Apple Developer ID (15 min of clicking, then a wait) ⛔ BLOCKS EVERYTHING PAID

Nothing can be sold until this exists. `spctl -a dist/Chute.app` currently says `rejected`, which
means every stranger who downloads Chute hits a Gatekeeper wall.

Full instructions: `/Users/sxope/Documents/2026/Development/37.chute/Scripts/notarize-setup.md`

The short version:

1. Keychain Access → **Certificate Assistant → Request a Certificate From a Certificate Authority**.
   Tick **Saved to disk** AND **Let me specify key pair information**. 2048 bits, RSA.
2. https://developer.apple.com/account/resources/certificates/add → choose
   **Developer ID Application** (not "Mac Development", not "Mac App Distribution" — only this one
   lets a stranger open the app). Upload the request. Download the `.cer`.
3. Double-click the `.cer`, then check it landed:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && security find-identity -v -p codesigning
```

Expect a line containing `Developer ID Application: … (TEAMID)`. **Note the TEAMID.**

4. https://appleid.apple.com/account/manage → App-Specific Passwords → **+** → name it
   `chute notarytool`. Copy the `xxxx-xxxx-xxxx-xxxx` value, then:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && xcrun notarytool store-credentials chute --apple-id "valuev.alexandr@gmail.com" --team-id "YOUR_TEAM_ID" --password "xxxx-xxxx-xxxx-xxxx"
```

Expect `Success. Credentials validated.`

5. Prove the whole path without publishing anything:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/release.sh --dry-run
```

Expect the last line: `notarised, stapled, and accepted by Gatekeeper: …/dist/Chute-0.1.0.dmg`

> If you are not enrolled in the Apple Developer Program yet, that is the real first step: $99/yr
> at https://developer.apple.com/programs/ and enrolment can take 24–48 hours. Start it before
> anything else today, then carry on with Step 2 while it processes.

---

## Step 2 — Point the domain (2 min) ⛔ BLOCKS THE WEBSITE

The site is live at **https://chute.pages.dev** and both custom domains are already attached to
the Cloudflare Pages project. They are stuck at `pending` because there is no DNS record behind
them, and `wrangler login` does not grant permission to create one.

**Easiest — the dashboard.** Cloudflare → `chutedev.com` → DNS → Add record, twice:

| Type | Name | Target | Proxy |
|---|---|---|---|
| CNAME | `chutedev.com` | `chute.pages.dev` | **Proxied (orange)** |
| CNAME | `www` | `chute.pages.dev` | **Proxied (orange)** |

> Orange cloud **ON**. That is the opposite of the advice for GitHub Pages, and it is correct here:
> Cloudflare Pages terminates TLS itself and there is no challenge for the proxy to break.

**Or hand me a token and I do it.** https://dash.cloudflare.com/profile/api-tokens → Create Token
→ **Edit zone DNS** → Zone Resources: Include · Specific zone · `chutedev.com`. Then:

```bash
printf '%s' 'PASTE_TOKEN_HERE' > ~/.cf-token && chmod 600 ~/.cf-token
```

Tell me and I run `./Scripts/cloudflare-setup.sh`.

Either way, check it a few minutes later:

```bash
dig +short chutedev.com && curl -sI https://chutedev.com | head -1
```

Expect an address, then `HTTP/2 200`.

---

## Step 3 — Record the eight demos (40 min, with me) ⛔ BLOCKS THE WHOLE LAUNCH

**This is the highest-value hour of your week.** There are 17 terminal tapes and **zero
recordings of the Finder menu or the menu bar** — which is to say, zero recordings of the thing
you are actually selling. All eight hero tapes are written and dry-run clean; they need a screen
and about forty minutes.

`demo/gui/record.sh` is **gone**. It clicked hardcoded pixel offsets after blind sleeps, three of
its four shots asked a human to click something, and nothing checked its output — a black take
and a good take looked identical in a directory listing. Two of its guards were broken outright:
it captioned with an ffmpeg filter this machine does not have, and its blank-frame check read an
empty measurement and would have deleted every recording the moment it was made.

**First, prove the pipeline without touching the screen** (safe, 30 seconds):

```bash
make -C demo/gui check
```

Expect `12 passed, 0 failed`, `every tape speaks only in verbs`, and all eight tapes resolving
with their fixture files present. **Any failure: stop and paste it to me.**

**Then grant permission once**, or the recorder produces nothing:

- System Settings → Privacy & Security → **Screen & System Audio Recording** → enable your
  terminal, then **quit and reopen it**. macOS only re-reads that permission on launch.
- Same pane → **Accessibility** → enable your terminal. The recorder moves the mouse.

Chute.app must also be running — the Finder menu writes a request and the app carries it out, so
without it every action is a no-op that looks like a hang.

**Record the wedge first.** It is the one that races the manual ritual against the right-click,
and it is the only tape that measures both sides:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./demo/gui/tapes/paste-a-whole-folder.sh
```

It takes over your mouse for about two minutes — **do not touch anything until it prints `done:`**.
It produces three things: the solo take for case pages and phones, a wide race for the landing
hero, and a `.json` of what the stopwatch actually read, which the deploy gate compares against
what the page claims.

Watch it back before recording the rest. Then:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && make -C demo/gui all
```

Two tapes need a word of warning, both stated in their own headers:
- `a-clean-room-for-a-risky-agent` leaves a terminal running an agent. Close it before the next take.
- `which-agent-is-waiting-for-you` needs hooks wired and a session actually waiting, or the badge
  is dark and the demo shows nothing. `chute hooks snippet` prints the JSON to paste.

Finally, publish only the GIFs a case actually refers to, and see what is still missing:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && make -C demo publish
```

---

## Step 4 — The production licence keypair (2 min)

Do this **somewhere no agent and no transcript can see it** — your own terminal, not through me.

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && node worker/keygen.mjs new
```

- **PUBLIC** half → paste into `Sources/ChuteCore/License.swift`, replacing `REPLACE_ME_BEFORE_RELEASE`
- **PRIVATE** half → your password manager, and later `wrangler secret put CHUTE_LICENSE_SEED`

Then confirm the three implementations still agree:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && node worker/contract.test.mjs
```

Expect `licence key format: Worker, keygen and app agree`.

---

## Step 5 — The email address (5 min)

`hello@chutedev.com` is printed on `/support`, `/refunds`, `/terms` and `/privacy`, and it is where
Paddle will write. **It does not exist yet.** Cloudflare → chutedev.com → Email → Email Routing →
route `hello@` to your real inbox. Free.

Test it by sending yourself a message before you tell Paddle it is real.

---

## Step 6 — Paddle account (20 min, can run in parallel with Apple)

Sole traders are **exempt** from business verification — Paddle: *"not required for individuals or
sole traders."* You need identity verification and domain review only.

**Do not submit the domain until Step 2 is done and every page returns 200.** A failed review costs
5–7 business days on resubmission. Check first:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute/site && npm run check:paddle
```

Then, once live:

```bash
for p in "" terms/ refunds/ privacy/ buy/ support/ docs/; do printf "%-38s %s\n" "https://chutedev.com/$p" "$(curl -s -o /dev/null -w '%{http_code}' -L "https://chutedev.com/$p")"; done
```

Expect `200` on every line.

---

## What I do while you do the above

- Cut and caption the eight hero demos as you record them
- Finish the case pages against the real recordings
- Write the launch thread, the Show HN post and the newsletter pitches against `marketing/06-FACT-SHEET.md`
- Build the Homebrew tap so `brew install avaluev/tap/chute` works the day the repo is ready

## What is NOT blocked and needs no decision from you

Everything above except Steps 1, 2, 3 and 5. Do not spend morning attention on anything else.

---

## The one rule for today

**Every number you publish must come from `marketing/06-FACT-SHEET.md`, and every number in there
carries the command that proves it.** Three false claims reached the live site by being copied
forward: "328 KB" (it is 2.5 MB), "28 commands" (there are 25), and two different unit-test counts
that disagreed with each other. All are now corrected. Re-measure; never carry a number forward.
