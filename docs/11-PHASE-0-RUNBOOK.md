# Phase 0 — the release blockers, step by step

**Written 2026-08-28.** Nothing ships until every item here is green. Each one is manual and each
one is a hard blocker: skip it and either the build refuses, the checkout degrades, or a stranger
who downloads Chute meets a Gatekeeper wall.

State below was **measured**, not assumed — every "reality" cell has the command that produced it.

---

## Measured state

| # | Thing | Reality on 2026-08-28 | Proof |
|---|---|---|---|
| 1 | Two CNAMEs for chutedev.com | **BLOCKED.** Zone is on Cloudflare, Pages project `chute` exists and serves `chute.pages.dev`, but the apex has no record. | `dig +short chutedev.com` → empty |
| 2 | Apple Developer ID | **BLOCKED.** One identity, self-signed. | `security find-identity -v -p codesigning` → `"Chute Local Dev"` |
| 3 | Production Ed25519 keypair | **BLOCKED.** No key can verify. | `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/License.swift:28` = `REPLACE_ME_BEFORE_RELEASE` |
| 4 | `hello@` and `keys@chutedev.com` | **BLOCKED.** No mail at all on the domain. | `dig +short MX chutedev.com` → empty |
| 5 | Paddle account, product, `pri_…` | **BLOCKED.** Both env vars empty, so the buy page degrades to trial-download. | no `.env*` in `/Users/sxope/Documents/2026/Development/37.chute/site/` |
| 6 | Worker deploy + 3 secrets | **BLOCKED**, but one command away — `wrangler` is already authenticated with `workers (write)`. | `curl https://chute-licences.avaluev.workers.dev` → `000` |
| 7 | Homebrew tap | **DONE.** And it never depended on (2) — the formula builds from source, Gatekeeper is not involved. | `brew info avaluev/tap/chute` → `stable 0.2.0 · Installed`; `chute.rb` sha256 `e7c3ea3a…`; `v0.1.0` + `v0.2.0` on origin |

### The trap that will bite

`/Users/sxope/Documents/2026/Development/37.chute/Scripts/release.sh:32` refuses a tag that already
exists, and `v0.2.0` is already pushed with no GitHub release attached. Before the first real
release, bump
`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Version.swift:12` to `0.3.0`.

**Do not delete the pushed tag.** The Homebrew formula's sha256 is computed from that exact
tarball; deleting it breaks `brew install` for anyone who already tapped.

---

## Ordering — start the slow ones first

Two items sit in a human review queue that cannot be rushed:

- **Apple enrolment** — 24–48h typical, longer if they ask for ID.
- **Paddle account, then domain review** — 1–3 days for the account. The domain review is pass/fail
  and a rejection costs 5–7 business days on resubmission.

Steps 3, 5, 6 and 4 are all same-day. Start 1 and 2 today, do the rest while they queue.

---

## STEP 1 — Apple Developer Program ($99/yr) · *start now, it queues*

1. Open <https://developer.apple.com/programs/enroll/> and sign in with `valuev.alexandr@gmail.com`.
2. Choose **Individual / Sole Proprietor** unless a registered company already exists. Individual is
   instant to fill in; an Organization enrolment needs a D-U-N-S number and adds two weeks. The name
   on the app is `Alexandr Valuev` either way.
3. Pay the $99. Expected: a confirmation email, then a second when membership activates.
4. Watch <https://developer.apple.com/account> — the **Membership details** card shows the Team ID
   once active. Write down the 10-character Team ID; step 7 needs it.

> Do not start step 7 until that card shows an active membership. Steps 2–6 need nothing from Apple.

---

## STEP 2 — Paddle account · *start now, it queues*

1. Sign up at <https://login.paddle.com/signup>. The **live** account, not sandbox — sandbox cannot
   sell.

2. Fill in the seller identity. Paddle's reviewer checks that a real, identifiable seller stands
   behind the product, and two fields are empty:

   ```bash
   open -e /Users/sxope/Documents/2026/Development/37.chute/site/src/lib/config.ts
   ```

   Lines 24–25 — shown here FILLED IN; in the file both are still `""`:

   ```ts
     seller: {
       name: "Alexandr Valuev",
       country: "Estonia",        // ← the country you invoice from
       entity: "Sole trader",     // ← registered company name, or "Sole trader"
     },
   ```

   `npm run check:paddle` fails while either is empty, so an unfinished identity cannot reach
   production.

3. Create the product. <https://vendors.paddle.com/products-v2> → **New product** → name `Chute`,
   type **Standard**. Add a price: **one-time**, `19.00 USD`. Copy the price ID — it starts `pri_`.

4. Get the client-side token. <https://vendors.paddle.com/authentication-v2> → **Client-side
   tokens** → **New token**. Copy it — it starts `live_`.

5. Write them where the build reads them. Gitignored, so the token never enters the repo:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute/site && printf 'NEXT_PUBLIC_PADDLE_TOKEN=live_PASTE_YOURS_HERE\nNEXT_PUBLIC_PADDLE_PRICE_ID=pri_PASTE_YOURS_HERE\nNEXT_PUBLIC_PADDLE_ENV=production\n' > .env.local && chmod 600 .env.local && cat .env.local
   ```

   Then open `/Users/sxope/Documents/2026/Development/37.chute/site/.env.local` and replace the two
   placeholders with the real token and price ID.

6. Prove it can never be committed:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && git check-ignore -v site/.env.local
   ```

   Expected: a line naming the ignore rule. **If it prints nothing, stop** — add `.env.local` to
   `/Users/sxope/Documents/2026/Development/37.chute/site/.gitignore` before anything else.

7. Submit the domain for review only **after** step 3 — the reviewer has to be able to load
   `https://chutedev.com`. See step 3.7.

---

## STEP 3 — The two CNAMEs · *15 minutes, free*

The Pages dashboard creates both records **and** the certificate.
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/cloudflare-setup.sh` does the same over
the API but needs a DNS-scoped token that does not exist yet — skip it.

1. Confirm the Pages project:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute/site && npx wrangler pages project list
   ```

   Expected: a row `chute │ chute.pages.dev`.

2. Put the current build on production:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/deploy-site.sh
   ```

   Expected: a `https://chute-<hash>.pages.dev` URL. This regenerates the tokens and social card and
   runs `check:paddle` — it refuses to publish while the seller fields from step 2.2 are empty.

3. Open the custom-domains panel:
   <https://dash.cloudflare.com/07ed4b0187fe0e7e1634cde4e647fcdf/pages/view/chute/domains>

4. **Set up a custom domain** → `chutedev.com` → **Continue** → **Activate domain**. Cloudflare
   creates the proxied CNAME itself; there is nothing to paste.

5. Repeat for `www.chutedev.com`.

6. Wait 2–5 minutes, then verify:

   ```bash
   dig +short chutedev.com && curl -sI https://chutedev.com | head -1
   ```

   Expected: two or more Cloudflare IPs, then `HTTP/2 200`.

7. Run the sweep Paddle's reviewer will run:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && for p in "" terms/ refunds/ privacy/ buy/ support/ docs/; do printf "%-40s %s\n" "https://chutedev.com/$p" "$(curl -s -o /dev/null -w '%{http_code}' -L "https://chutedev.com/$p")"; done
   ```

   Expected: `200` on every line. Then **open it in a browser and look at it** — twice already a
   build returned 200 with no CSS at all. Only then submit the domain at
   <https://vendors.paddle.com/account-verification>.

8. Retire the GitHub Pages copy, so there is exactly one live site:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && gh api -X DELETE repos/avaluev/chute/pages
   ```

---

## STEP 4 — `hello@` and `keys@` · *20 minutes, free*

Two different jobs, and mixing them up is the classic failure: **Cloudflare Email Routing receives,
Resend sends.** They must not both own the apex MX.

### 4a. Inbound — Cloudflare Email Routing

1. <https://dash.cloudflare.com/07ed4b0187fe0e7e1634cde4e647fcdf/chutedev.com/email/routing>
2. **Get started** → Cloudflare offers to add the MX and SPF records → **Add records and enable**.
3. **Routing rules** → **Create address**, twice:
   - `hello@chutedev.com` → forward to `valuev.alexandr@gmail.com`
   - `keys@chutedev.com` → forward to `valuev.alexandr@gmail.com`
4. Cloudflare emails a destination-verification link. Click it. Both rules go **Active**.
5. Verify:

   ```bash
   dig +short MX chutedev.com && dig +short TXT chutedev.com
   ```

   Expected: three `route*.mx.cloudflare.net` lines, and an SPF
   `v=spf1 include:_spf.mx.cloudflare.net ~all`.

6. Send a real test from a phone to `hello@chutedev.com` and confirm it lands. This is the only
   stated support channel on the site — a silently broken one is worse than none.

### 4b. Outbound — Resend

The Worker sends **from** `Chute <keys@chutedev.com>`
(`/Users/sxope/Documents/2026/Development/37.chute/worker/src/index.js:102`). That address must be
verified in Resend or every licence email is filed as spam.

7. Sign up at <https://resend.com/signup>. Free tier is 3,000 emails/month.
8. <https://resend.com/domains> → **Add Domain** → **`chutedev.com`** — the apex, not a subdomain,
   because the From address is at the apex.
9. Copy the records Resend shows into
   <https://dash.cloudflare.com/07ed4b0187fe0e7e1634cde4e647fcdf/chutedev.com/dns/records>:

   | Type | What | Action |
   |---|---|---|
   | TXT | DKIM (`resend._domainkey`) | add as given |
   | TXT | SPF | **edit the existing one**, see below |
   | MX | anything Resend offers | **skip it**, see below |

   > **MX collision.** Cloudflare Email Routing owns the apex MX from 4a.2, and a second MX breaks
   > inbound mail. Resend does not need MX to send.
   >
   > **SPF collision.** There cannot be two `v=spf1` TXT records. **Edit** the existing record rather
   > than adding a second, so it reads:
   > `v=spf1 include:_spf.mx.cloudflare.net include:amazonses.com ~all`

10. Back in Resend, **Verify**. Expected: **Verified** within a few minutes.
11. <https://resend.com/api-keys> → **Create API Key**, permission **Sending access**, name
    `chute-worker`. It starts `re_`. **It is shown once** — paste it into the password manager now;
    step 6 needs it.

---

## STEP 5 — The production Ed25519 keypair · *5 minutes, and the highest-stakes 5 minutes here*

Lose the private half and no licence can ever be issued again. Leak it and anyone can mint their
own. It must never touch a transcript, a log, an agent's context, or this repo.

1. Open a **fresh Terminal window by hand** — not through an agent. Turn off terminal logging.
2. Generate:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && node worker/keygen.mjs new
   ```

   Expected: two base64 lines, `PUBLIC` and `PRIVATE`.

3. **Private half → password manager, immediately.** Title it
   `CHUTE_LICENSE_SEED — chute production`. This is the single irreplaceable secret in the product.

4. **Public half → the app.** Edit
   `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/License.swift:28`:

   ```swift
       public static let productionPublicKey = "PASTE_THE_PUBLIC_HALF_HERE"
   ```

5. Prove the three implementations agree. The Worker, `keygen.mjs` and `License.swift` are three
   implementations in two languages, and nobody finds out they diverged until a paying customer
   pastes a key that does nothing:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && node worker/contract.test.mjs
   ```

   Expected: `licence key format: Worker, keygen and app agree`.

6. Full gate, then commit — this is the commit that makes the app licensable:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests && ./Scripts/smoke.sh
   ```

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && git add Sources/ChuteCore/License.swift site/src/lib/config.ts && git commit -m "feat: the production public key, so a licence can finally verify" && git push
   ```

7. Mint one for yourself and use it:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && read -rs CHUTE_LICENSE_SEED && export CHUTE_LICENSE_SEED && node worker/keygen.mjs mint valuev.alexandr@gmail.com; unset CHUTE_LICENSE_SEED
   ```

   Rebuild, then Chute menu bar → **Settings…** → **License** → paste → **Activate**.
   Expected: the `Trial — N days left` item disappears entirely and Settings reads
   `Licensed to valuev.alexandr@gmail.com`.

---

## STEP 6 — Deploy the Worker · *10 minutes*

Needs the seed from step 5, the Resend key from 4b.11, and Paddle from step 2. `wrangler` is already
authenticated with `workers (write)` — there is no login step.

1. Deploy:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute/worker && npx wrangler deploy
   ```

   Expected: `Published chute-licences` and a `https://chute-licences.<subdomain>.workers.dev` URL.
   **Copy that URL** — step 6.3 needs it.

2. Set the two secrets already in hand. Each prompts and reads stdin, so nothing enters shell
   history:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute/worker && npx wrangler secret put CHUTE_LICENSE_SEED
   ```

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute/worker && npx wrangler secret put RESEND_API_KEY
   ```

3. <https://vendors.paddle.com/notifications-v2> → **New destination**
   - Description: `chute licence minting`
   - URL: the workers.dev URL from 6.1
   - Events: **`transaction.completed`** only

4. Copy that destination's **secret key** (starts `pdl_ntfset_`) and set the third secret:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute/worker && npx wrangler secret put PADDLE_WEBHOOK_SECRET
   ```

5. Confirm all three landed:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute/worker && npx wrangler secret list
   ```

   Expected: exactly `PADDLE_WEBHOOK_SECRET`, `CHUTE_LICENSE_SEED`, `RESEND_API_KEY`.

6. Confirm it is alive and correctly hostile:

   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" https://chute-licences.<your-subdomain>.workers.dev
   ```

   Expected: `405` — it is POST-only. A `000` means it is not deployed.

7. In Paddle's notification detail page, **Send test event** with `transaction.completed`. Expected:
   Paddle logs a `200` and a licence email arrives. If not, watch it live:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute/worker && npx wrangler tail
   ```

---

## STEP 7 — The Developer ID certificate · *once Apple activates, 20 minutes*

Full detail lives in `/Users/sxope/Documents/2026/Development/37.chute/Scripts/notarize-setup.md`.
Summary with the links:

1. Keychain Access → **Certificate Assistant → Request a Certificate From a Certificate Authority…**
   - Email `valuev.alexandr@gmail.com`, Common Name `Alexandr Valuev`, CA Email **empty**
   - **Saved to disk** ✔ and **Let me specify key pair information** ✔ (2048, RSA)
   - Save to `~/Desktop/CertificateSigningRequest.certSigningRequest`

   > Do not skip the "let me specify" tick. Without it the private key can be generated in a way that
   > later refuses to sign, and the failure appears three steps later as an unexplained codesign
   > error.

2. <https://developer.apple.com/account/resources/certificates/add> → **Developer ID Application** —
   *not* "Mac Development", *not* "Mac App Distribution". Developer ID is the only type that lets a
   stranger open the app. Upload the CSR, download `developerID_application.cer`.

3. Double-click the `.cer`, then confirm:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && security find-identity -v -p codesigning
   ```

   Expected: a line containing `"Developer ID Application: Alexandr Valuev (TEAMID)"`.

4. <https://appleid.apple.com/account/manage> → **App-Specific Passwords** → **+** → name it
   `chute notarytool`. Copy the `xxxx-xxxx-xxxx-xxxx` value.

5. Store the notary profile once, in the keychain:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && xcrun notarytool store-credentials chute --apple-id "valuev.alexandr@gmail.com" --team-id "YOUR_TEAM_ID" --password "xxxx-xxxx-xxxx-xxxx"
   ```

   Expected: `Success. Credentials validated.`

6. Prove the whole path without publishing anything:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/release.sh --dry-run
   ```

   Expected last line:

   ```
   notarised, stapled, and accepted by Gatekeeper: …/dist/Chute-0.3.0.dmg
   ```

   > This fails on preflight first — see **The trap that will bite** above. Bump
   > `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Version.swift:12` to
   > `"0.3.0"` and commit before running it.

---

## STEP 8 — Ship, and bump the tap

1. The real release — tags, notarises, publishes the DMG:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/release.sh
   ```

2. A new tag means a new sha256:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && curl -L https://github.com/avaluev/chute/archive/refs/tags/v0.3.0.tar.gz | shasum -a 256
   ```

3. Update `version` and `sha256` in
   `/Users/sxope/Documents/2026/Development/37.chute/packaging/homebrew/chute.rb`, then push to the
   tap that already exists:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && rm -rf /tmp/homebrew-tap && git clone https://github.com/avaluev/homebrew-tap.git /tmp/homebrew-tap && cp packaging/homebrew/chute.rb /tmp/homebrew-tap/Formula/chute.rb && cd /tmp/homebrew-tap && git commit -am "chute 0.3.0" && git push
   ```

4. Verify as a stranger would:

   ```bash
   brew update && brew upgrade avaluev/tap/chute && chute --version
   ```

   Expected: `chute 0.3.0`.

---

## Notes

### "Trial — 14 days left" in the menu bar is not a bug

`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/TrialState.swift:115` prints
exactly that. The app **cannot** be licensed until step 5 is done, because
`License.swift:28` is still the placeholder and `License.verify` rejects every key that exists.

If the trial lapses before step 5 lands, this restarts it — a deliberate ceiling, documented at
`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/TrialState.swift:43`:

```bash
rm "/Users/sxope/Library/Application Support/Chute/trial.json"
```

### Quitting Terminal does not lose a Claude Code session

Sessions live in `~/.claude`, not in the Terminal window. Commit first, quit, then:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && claude --continue
```

`--continue` resumes the most recent session in this directory; `claude --resume` gives a picker.

---

## Roadmap

- **Done** — item 7 (Homebrew tap): repo public, real sha256, `brew info avaluev/tap/chute` →
  `stable 0.2.0`. Cloudflare zone + Pages project `chute` exist; `wrangler` is authenticated.
- **In progress** — nothing yet. Steps 1 and 2 are the ones to start first, because they queue.
- **Remaining** — items 1–6, in the order above. Once 1 and 2 are submitted, steps 3–6 are roughly a
  half-day with no waiting.
