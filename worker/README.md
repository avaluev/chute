# chute-licences

The only server Chute has. Paddle webhook in, an Ed25519 licence key out, emailed to the buyer.

The app never talks to this. It verifies a signature offline against a public key compiled into
the binary. If this Worker is down, **existing customers notice nothing** — only new keys are
delayed, and one can be issued by hand in the meantime.

## Setup, once

1. **Generate the production keypair — somewhere no transcript, log or agent can see it.**

   ```bash
   node worker/keygen.mjs new
   ```

   Put the PUBLIC half into `Sources/ChuteCore/License.swift` as `productionPublicKey`, replacing
   `REPLACE_ME_BEFORE_RELEASE`. Put the PRIVATE half in a password manager and in the Worker
   secret below. **Lose it and no new licence can ever be issued; leak it and anyone can issue
   their own.**

2. **Deploy and set the three secrets.**

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute/worker && npx wrangler deploy
   cd /Users/sxope/Documents/2026/Development/37.chute/worker && npx wrangler secret put PADDLE_WEBHOOK_SECRET
   cd /Users/sxope/Documents/2026/Development/37.chute/worker && npx wrangler secret put CHUTE_LICENSE_SEED
   cd /Users/sxope/Documents/2026/Development/37.chute/worker && npx wrangler secret put RESEND_API_KEY
   ```

3. **Point Paddle at it.** Paddle dashboard → Developer tools → Notifications → New destination,
   URL `https://chute-licences.<your-subdomain>.workers.dev`, event `transaction.completed`.
   Copy the destination's secret into `PADDLE_WEBHOOK_SECRET`.

4. **Verify the domain in Resend** so `keys@chutedev.com` is not filed as spam.

## The check that matters

The Worker, `keygen.mjs` and `License.swift` must agree on the key format byte for byte. They are
three implementations in two languages, and nobody finds out they diverged until a paying customer
pastes a key that does nothing.

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && node worker/contract.test.mjs
```

Expected: `licence key format: Worker, keygen and app agree`.

## Issuing a key by hand

For a refund-and-reissue, a gift, or while the Worker is being fixed:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && read -rs CHUTE_LICENSE_SEED && export CHUTE_LICENSE_SEED && node worker/keygen.mjs mint buyer@example.com; unset CHUTE_LICENSE_SEED
```

`read -rs` takes the seed without echoing it and without putting it in shell history, which is
where it landed for as long as it was an argument — and where `ps` could read it meanwhile.

## Deliberately not here

- **No database.** The key is self-contained; there is nothing to look up and nothing to leak.
  Duplicate webhook deliveries are handled without one: `issuedAt` comes from the event, so the
  same transaction always mints the byte-identical key however many times Paddle sends it. A
  store of seen event ids would work too, and would add a binding to provision and a failure
  mode of its own to a design whose whole claim is that it holds no state.
- **No activation count, no device limit.** Both need a server the app must call, which would
  contradict the offline promise that is half of why people buy this.
