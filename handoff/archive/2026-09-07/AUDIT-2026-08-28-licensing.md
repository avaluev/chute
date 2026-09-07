# Licensing / payment path audit — 2026-08-28

VERDICT: No key can be forged and no free key can be issued without the Ed25519 private key or
the Paddle HMAC secret — but the Paddle webhook has no replay/idempotency guard (a fresh replay
or an ordinary Paddle retry mints and emails a second valid key for one payment), and
`License.swift`'s pipe-splitting silently breaks (or, in one crafted shape, mis-parses) the
licence for any customer whose email legitimately contains `|`. No CRITICAL found.

Severity counts: CRITICAL 0 · HIGH 1 · MEDIUM 3 · LOW 5

Scope audited (read only, nothing modified):
- /Users/sxope/Documents/2026/Development/37.chute/worker/src/index.js
- /Users/sxope/Documents/2026/Development/37.chute/worker/keygen.mjs
- /Users/sxope/Documents/2026/Development/37.chute/worker/contract.test.mjs
- /Users/sxope/Documents/2026/Development/37.chute/worker/wrangler.toml
- /Users/sxope/Documents/2026/Development/37.chute/worker/README.md
- /Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/License.swift
- /Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/TrialState.swift
- /Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/LicenseSuite.swift

Commands actually run:
- `cd /Users/sxope/Documents/2026/Development/37.chute && node worker/contract.test.mjs` → all 3 checks `ok`.
- A scratch node script exercising `mint()` in both the Worker and `keygen.mjs` for: empty email,
  an email containing `|`, a unicode email, a 5000-char email, whitespace-padded email, and
  issuedAt of `-1`, `0`, `99999999999999`, `Number.MAX_SAFE_INTEGER` → **all matched byte-for-byte**
  between the two mint implementations in every case.
- A scratch Swift snippet reproducing exactly the `payload.split(separator: "|")` call at
  `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/License.swift:51` to confirm
  Swift's default `omittingEmptySubsequences: true` behavior on pipe-containing payloads (see
  MEDIUM-1 below for the results).

---

## HIGH

### H1 — Paddle webhook has no replay/idempotency check; a fresh replay or an ordinary Paddle retry mints a second key for one payment
`/Users/sxope/Documents/2026/Development/37.chute/worker/src/index.js:26-42` and `:50-67`.

`verifyPaddle` only checks that the HMAC is valid and that `|Date.now()/1000 - ts| <= 300`
(`worker/src/index.js:58-59`). It does not check whether this specific event (Paddle's
`event.data.id` / transaction id) has already been processed — there is no KV, D1, or any other
store (the README says so explicitly: "No database. The key is self-contained; there is nothing
to look up and nothing to leak." — `worker/README.md:59`). That's a deliberate architecture
choice, but it has this direct consequence: **any** POST with a still-fresh (≤300s old), validly
signed body reaches `mint()` and `email_()` again.

Concretely reachable, not just theoretical:
- Paddle's own webhook delivery retries (on Worker downtime, a 5xx, a timeout, or a network
  blip) resend the notification — if that retry carries a fresh signature/timestamp (normal
  webhook-retry behavior), it sails through `verifyPaddle` a second time and mints and emails a
  **second valid licence key** for the same `transaction.completed` event.
- Anyone able to capture one in-flight webhook POST (proxy misconfig, a log that captured the
  raw body, a compromised intermediary) can resend it verbatim for up to 300 seconds and get the
  same result — `timingSafeEqual` and the HMAC don't care that it's been seen before.

Exploit scenario: transaction `txn_123` completes once, is paid once; due to a transient 502 from
the Worker (or a captured/replayed POST), Paddle or an attacker resends the identical signed
payload 30 seconds later → two `CHUTE-...` keys are minted and mailed to the customer for one
$19 charge.

Smallest fix: store processed `event.data.id` values in Workers KV (cheap, and the README's "no
database" reasoning was about *licence* data, not dedup state) with a TTL slightly longer than
the 300s replay window, and reject with 200 (not retried) if the id was already seen. If KV is
truly off the table, at minimum widen the acceptance path to be idempotent by re-deriving the
same `issuedAt` from the event's own timestamp/id (e.g. `issuedAt = event.data.id` hash) so a
duplicate delivery reissues the *identical* key rather than a fresh one — cheaper than a store,
though it doesn't stop the duplicate email being sent.

---

## MEDIUM

### M1 — `License.swift` mis-splits the payload for any email containing `|`, breaking a valid customer's key (and in a crafted case, mis-parsing the email instead of rejecting)
`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/License.swift:51`:
```swift
let fields = String(decoding: payload, as: UTF8.self).split(separator: "|")
guard fields.count == 2, let epoch = TimeInterval(fields[1]), !fields[0].isEmpty else { return nil }
```
`String.split(separator:)` defaults to `omittingEmptySubsequences: true`. `|` is a legal RFC 5322
`atext` character, so `a|b@example.com` is a valid email address, and nothing in the Worker or
`keygen.mjs` rejects or escapes it before signing — they just do `` `${email}|${issuedAt}` ``.

Confirmed by direct reproduction (`swift` scratch script running the exact call above):
```
payload "a|b@example.com|1767225600"        -> fields ["a", "b@example.com", "1767225600"]  count=3  (REJECTED: valid key, valid customer, never verifies)
payload "|||abc||||1767225600"              -> fields ["abc", "1767225600"]                  count=2  (ACCEPTS, but info.email="abc", not the real signed email)
```
So: a real, paying customer whose email contains one ordinary `|` gets a `CHUTE-...` key that the
Worker and `keygen.mjs` both compute identically, but which `License.verify` will reject forever
(`fields.count != 2`) — a silent, permanent activation failure for that customer, with no error
message to explain why (by design — "never explains WHY a key failed", `License.swift:33-34`).
For the rarer edge shape where the local part is only leading/trailing pipes around a middle run
(e.g. `|||abc|||@example.com`), the key instead verifies but reports the *wrong* email in the
returned `LicenseInfo` — not a forgery risk (the signature still binds the real payload bytes,
so nobody can profit from this), but it is a real data-integrity bug if that email is ever shown
back to the customer or used for support lookups.

Smallest fix: split at the **last** `|` only, since only `issuedAt` is guaranteed pipe-free:
```swift
guard let sep = payload.lastIndex(of: UInt8(ascii: "|")) else { return nil }
let emailBytes = payload[..<sep]
let epochBytes = payload[payload.index(after: sep)...]
guard !emailBytes.isEmpty, let epoch = TimeInterval(String(decoding: epochBytes, as: UTF8.self))
else { return nil }
let email = String(decoding: emailBytes, as: UTF8.self)
```
This must land in `keygen.mjs`/Worker's payload contract too only in spirit — they don't need to
change (they never split), but the fix must be re-pinned in `contract.test.mjs` /
`LicenseSuite.swift` with a `|`-containing email added to the pinned/perturbation cases so this
regressions-guards itself.

### M2 — Private key passed as a bare CLI argument lands in shell history and process listings
`/Users/sxope/Documents/2026/Development/37.chute/worker/keygen.mjs:40-43`,
`/Users/sxope/Documents/2026/Development/37.chute/worker/README.md:54`.

`node worker/keygen.mjs mint <privateBase64> <email>` takes the Ed25519 private key as
`process.argv`. On any shell with history enabled, that key is now sitting in
`~/.zsh_history`/`~/.bash_history` in plaintext forever (or until manually purged), and for the
duration of the command it's visible to any other local process via `ps`/`/proc/<pid>/cmdline`.
This is exactly the kind of persistence the file's own top comment warns against ("The PRIVATE
key never enters the app, this repo, or a log" — `keygen.mjs:2`) but the CLI itself creates a
new, unmentioned leak path.

Smallest fix: read the private key from `stdin` or an env var (`CHUTE_PRIVATE_KEY`) instead of
`argv[3]`, e.g. `const privB64 = process.env.CHUTE_PRIVATE_KEY ?? await readStdinLine();`.

### M3 — A failed Resend call can log the customer's email into Cloudflare's logs
`/Users/sxope/Documents/2026/Development/37.chute/worker/src/index.js:122-124`:
```js
if (!res.ok) console.error("resend failed", res.status, await res.text());
```
Resend's validation-error bodies often echo the offending field's value (e.g. an invalid `to`
address) back in the error message. `console.error` here logs that full response body to
Cloudflare's Worker logs (`wrangler tail` / dashboard), which persists the customer's email
address somewhere the code's own design goal ("no database... nothing to leak",
`worker/README.md:59`) explicitly tried to avoid.

Smallest fix: `console.error("resend failed", res.status)` — drop the body, or log only its
`name`/`statusCode` fields if you need the error class.

---

## LOW

### L1 — Worker throws an uncaught error (Cloudflare's default 500) if `CHUTE_LICENSE_SEED` is unset/misconfigured
`/Users/sxope/Documents/2026/Development/37.chute/worker/src/index.js:83-86`. `atob(seedB64)` on
`undefined` decodes the literal string `"undefined"`, which is not 32 bytes, so
`pkcs8.set(seed, 16)` throws `RangeError: Source is too large`. Deploy-config error only, not
attacker-reachable, but worth a friendlier guard (`if (!seedB64) throw new Response(...)` or a
length check) instead of a raw crash on every otherwise-valid transaction.

### L2 — No length cap on the pasted licence string before `Data(base64Encoded:)`
`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/License.swift:40`. Purely
local (Settings text field), so at most a self-inflicted memory spike from pasting a huge blob —
not a remote vector. Noted for completeness per the audit's ask, no fix required.

### L3 — `keygen.mjs new` prints the private key to stdout by design
`/Users/sxope/Documents/2026/Development/37.chute/worker/keygen.mjs:38-39`. Already documented
("somewhere no transcript, log or agent can see it" — `worker/README.md:11`,
`worker/keygen.mjs:2`). No technical control backs the warning; it's comment-only. Acceptable
given it's a one-time, human-run command, but flagging since item 5 asked specifically about
secrets that get echoed.

### L4 — Trial can be reset by editing/deleting `trial.json` — deliberate, not a defect
`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/TrialState.swift:43-45`.
Deleting `~/Library/Application Support/Chute/trial.json`, or hand-editing `firstRun`/`lastSeen`
in it, restarts the trial at day zero. The rollback guard `effectiveNow = max(now, record.lastSeen)`
(`TrialState.swift:64`, tested by Perturbation 4 in `LicenseSuite.swift:80-86`) correctly defends
only against the **system clock** being wound back while the file is left alone — it does nothing
to stop the file itself being rewritten, because the file carries no signature/HMAC. The code's
own comment calls this out explicitly as an accepted ceiling at the $19 price point ("Piracy is
not the constraint at this price; obscurity is." — `TrialState.swift:45`). Reported as
requested, not scored as a bug.

### L5 — Confirmed: a licence CANNOT be spoofed via `trial.json`
`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/TrialState.swift:58`. The
`.licensed` branch is reached only if `License.verify(record.licenseKey)` succeeds — real Ed25519
verification against the compiled `productionPublicKey`. Writing an arbitrary `licenseKey` string
into the JSON file (no private key) always falls through to the date-based `.trial`/`.expired`
path. Confirmed both by code reading and by the existing `bogus` case in
`/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/LicenseSuite.swift:92-94`.
A licensed record needs exactly one thing: a `licenseKey` string that round-trips through
`License.verify` — no other field in `TrialRecord` participates once that's true.

---

## Explicit answers to the five numbered areas

1. **Byte-for-byte agreement (mint side).** PROVEN — `node worker/contract.test.mjs` passes, and
   my own edge-case script (empty email, `|`-containing email, unicode email, 5000-char email,
   whitespace padding, `issuedAt` of `-1`/`0`/huge) shows the Worker's `mint()` and
   `keygen.mjs`'s `mint()` produce byte-identical output in every case. The divergence is on the
   **verify** side: `License.swift` disagrees with what the two mint implementations happily
   produce whenever the email contains `|` — see M1.

2. **Paddle webhook verification.** Header parsing is safe against malformance (any header
   missing `ts=`/`h1=` → `false` → 401, never a crash). The 300s window uses `Math.abs()` so it
   catches both stale and future-dated timestamps, with a `Number.isFinite` guard against a
   non-numeric `ts`. `timingSafeEqual` is constant-time for equal-length inputs (the only case
   that matters for a fixed-length hex MAC). No path returns 200 for an unverified body — `mint`/
   `email_` are only reachable after `verifyPaddle` returns `true` (confirmed by reading the
   control flow in `worker/src/index.js:18-43`). **Replay:** CONFIRMED exploitable — see H1. A
   still-fresh replay, or an ordinary Paddle delivery retry, mints and emails a second key for one
   payment because there is no per-event dedup.

3. **`License.verify` crash/spoof surface.** Cannot crash: every decode step (`Data(base64Encoded:)`,
   `Curve25519.Signing.PublicKey(rawRepresentation:)`, `String(decoding:as:)`, `TimeInterval(...)`)
   either returns `nil`/a placeholder or is guarded before use — confirmed by the junk-input loop
   already in `LicenseSuite.swift:43-46` and by reading the Foundation/CryptoKit API contracts
   (none of them throw on malformed bytes). Cannot be accepted with an attacker-chosen email
   without the private key — the signature is verified over the exact payload bytes that include
   the email, so no crafted key without the seed can produce an accepted result. The one real
   defect is the `|`-splitting bug (M1), which is a parsing/data-integrity issue, not a
   signature-bypass.

4. **`TrialState` spoofing.** Trial length: CAN be extended by direct file edit/deletion —
   deliberate, documented (L4). Licence: CANNOT be spoofed via the file — cryptographically gated
   (L5). A licensed record needs only a `licenseKey` value that verifies against the compiled
   public key. Clock rollback: handled correctly for the modeled threat (system clock moved
   backward while the file is untouched) — not applicable to direct file tampering, which is a
   different, explicitly out-of-scope threat per the code's own comments.

5. **Secret logging/persistence.** `CHUTE_LICENSE_SEED`, `PADDLE_WEBHOOK_SECRET`, and
   `RESEND_API_KEY` are never logged or echoed anywhere in the reviewed files. Two persistence
   issues found: the private key passed as a `mint` CLI argument lands in shell history/`ps`
   (M2), and a Resend failure can log the customer's email into Cloudflare logs (M3). The
   deliberate one-time stdout print of the private key by `keygen.mjs new` is documented, not a
   new finding (L3).
