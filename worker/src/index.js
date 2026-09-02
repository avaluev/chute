/**
 * Paddle webhook → an Ed25519 licence key → the buyer's inbox.
 *
 * Paddle Billing dropped the licence-key feature Paddle Classic had, so minting is ours. This is
 * the only server Chute has, it holds one secret, and the app never talks to it — the app checks
 * a signature offline. If this Worker is down, existing customers notice nothing; only new keys
 * are delayed, and `node worker/keygen.mjs mint` issues one by hand in the meantime.
 *
 * Secrets (wrangler secret put NAME):
 *   PADDLE_WEBHOOK_SECRET  the notification destination's secret, from the Paddle dashboard
 *   CHUTE_LICENSE_SEED     base64 of the 32-byte Ed25519 seed from `keygen.mjs new`
 *   RESEND_API_KEY         Resend, free tier
 *   PADDLE_API_KEY         optional — lets the Worker look a customer up by id when the
 *                          notification carries `customer_id` and no email (Paddle Billing's
 *                          default shape); without it such a transaction returns 500 and Paddle
 *                          retries until it is set
 */

const PREFIX = "CHUTE-";

export default {
  async fetch(request, env) {
    if (request.method !== "POST") return new Response("POST only", { status: 405 });

    // The raw body must be read ONCE and verified byte-for-byte. Parsing then re-serialising
    // changes whitespace and key order, and the signature stops matching for no visible reason.
    const raw = await request.text();
    const signature = request.headers.get("Paddle-Signature") ?? "";

    if (!(await verifyPaddle(raw, signature, env.PADDLE_WEBHOOK_SECRET))) {
      // Deliberately vague. A verifier that distinguishes "bad signature" from "stale timestamp"
      // is a free oracle for anyone probing it.
      return new Response("rejected", { status: 401 });
    }

    const event = JSON.parse(raw);
    if (event.event_type !== "transaction.completed") {
      return new Response("ignored", { status: 200 });   // 200, or Paddle retries forever
    }

    // THE ONE FACT EVERYTHING HANGS ON, AND IT USED TO FAIL SILENTLY. A Paddle Billing
    // `transaction.completed` carries `customer_id`; the embedded `customer.email` is not
    // promised, and the checkout sets no custom_data. A transaction with no email returned
    // 200 "no email" — Paddle's delivery log green, no key minted, nothing red anywhere. A 500
    // makes Paddle retry (harmless: the key is a pure function of the event) and shows up.
    const email = event.data?.customer?.email
      ?? event.data?.custom_data?.email
      ?? (await customerEmail(env, event.data?.customer_id));
    if (!email) {
      console.error("no email on transaction", event.data?.id ?? "?", "customer", event.data?.customer_id ?? "?");
      return new Response("no email on the transaction", { status: 500 });
    }

    // IDEMPOTENCE, WITHOUT A DATABASE. Paddle retries a delivery on any 5xx, timeout or network
    // blip, and a retry carries a fresh signature and timestamp — so it passes `verifyPaddle`
    // again. With `issuedAt` taken from the clock, that minted a SECOND, DIFFERENT valid key for
    // one $19 payment; a captured POST replayed inside the 300s window did the same.
    //
    // A KV store of seen event ids would fix it and was the obvious suggestion, but it adds a
    // binding to provision, a failure mode of its own, and state to an architecture whose whole
    // claim is that it holds none. Deriving `issuedAt` from the EVENT instead makes the
    // operation idempotent by construction: the same transaction always produces the same bytes,
    // so a retry re-mints the IDENTICAL key. The customer may get the mail twice; they can never
    // get two different licences, and there is nothing to provision or to go stale.
    const occurred = Date.parse(event.occurred_at ?? event.data?.billed_at ?? event.data?.created_at ?? "");
    // No usable timestamp is not "use the clock": that is the second-different-key bug the
    // paragraph above is about, one fall-through away. Refuse; Paddle retries the same event.
    if (!Number.isFinite(occurred)) return new Response("no timestamp on the event", { status: 500 });
    const issuedAt = Math.floor(occurred / 1000);

    const key = await mint(email, env.CHUTE_LICENSE_SEED, issuedAt);
    // A mail that did not go out is not an issued licence: money taken, key minted into the
    // void, Paddle told "issued" and never retrying, and — by design — no address in any log to
    // reissue by hand from. 500 costs at most a duplicate email of the identical key.
    if (!(await email_(env, email, key))) return new Response("email failed", { status: 500 });
    return new Response("issued", { status: 200 });
  },
};

/**
 * Paddle signs `${timestamp}:${rawBody}` with HMAC-SHA256.
 * Header shape: `ts=1671552777;h1=<hex>`.
 */
async function verifyPaddle(raw, header, secret) {
  if (!secret) return false;
  const pairs = header.split(";").map((p) => p.split("=")).filter((p) => p.length === 2);
  const ts = pairs.find(([k]) => k === "ts")?.[1];
  // Paddle sends several h1 values while a secret is being rotated; any one matching is a
  // valid delivery. `Object.fromEntries` kept only the last, which rejected every webhook for
  // the rotation window if the new secret was not the last one listed.
  const h1s = pairs.filter(([k]) => k === "h1").map(([, v]) => v);
  if (!ts || h1s.length === 0) return false;
  const parts = { ts };

  // A replay window. Without it a captured webhook mints a fresh key forever.
  const age = Math.abs(Date.now() / 1000 - Number(parts.ts));
  if (!Number.isFinite(age) || age > 300) return false;

  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]
  );
  const mac = hex(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${parts.ts}:${raw}`)));
  // No early exit: every candidate is compared, so the count of candidates is all a timing
  // observer learns.
  return h1s.map((h) => timingSafeEqual(mac, h)).includes(true);
}

/** `customer.email` when the notification only carries `customer_id`. null without a key. */
async function customerEmail(env, customerId) {
  if (!customerId || !env.PADDLE_API_KEY) return null;
  const base = env.PADDLE_ENV === "sandbox" ? "https://sandbox-api.paddle.com" : "https://api.paddle.com";
  const res = await fetch(`${base}/customers/${encodeURIComponent(customerId)}`, {
    headers: { Authorization: `Bearer ${env.PADDLE_API_KEY}` },
  });
  if (!res.ok) { console.error("customer lookup failed", res.status); return null; }
  const body = await res.json();
  return typeof body?.data?.email === "string" ? body.data.email : null;
}

/** Constant time in the length that matters: never `a === b` on a secret. */
function timingSafeEqual(a, b) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

const hex = (buf) =>
  [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");

/** `CHUTE-` + base64( signature(64) || "email|issuedAtEpoch" ) — the exact shape License.swift reads. */
async function mint(email, seedB64, issuedAt = Math.floor(Date.now() / 1000)) {
  // A missing secret used to reach `atob(undefined)`, which decodes the literal text "undefined",
  // and the failure surfaced as `RangeError: Source is too large` from `pkcs8.set` — on every
  // otherwise-valid purchase, with nothing in the message naming the cause. Say it plainly.
  if (typeof seedB64 !== "string" || seedB64.length === 0) {
    throw new Error("CHUTE_LICENSE_SEED is not set — run `npx wrangler secret put CHUTE_LICENSE_SEED`");
  }
  // Web Crypto wants PKCS#8; the secret is stored as the bare 32-byte seed, so wrap it.
  const seed = Uint8Array.from(atob(seedB64), (c) => c.charCodeAt(0));
  if (seed.length !== 32) {
    throw new Error(`CHUTE_LICENSE_SEED must be 32 bytes of base64, got ${seed.length}`);
  }
  const pkcs8 = new Uint8Array(48);
  pkcs8.set([0x30,0x2e,0x02,0x01,0x00,0x30,0x05,0x06,0x03,0x2b,0x65,0x70,0x04,0x22,0x04,0x20]);
  pkcs8.set(seed, 16);

  const key = await crypto.subtle.importKey("pkcs8", pkcs8, { name: "Ed25519" }, false, ["sign"]);
  const payload = new TextEncoder().encode(`${email}|${issuedAt}`);
  const sig = new Uint8Array(await crypto.subtle.sign("Ed25519", key, payload));

  const blob = new Uint8Array(sig.length + payload.length);
  blob.set(sig); blob.set(payload, sig.length);
  return PREFIX + btoa(String.fromCharCode(...blob));
}

async function email_(env, to, key) {
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${env.RESEND_API_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      from: "Chute <keys@chutedev.com>",
      to,
      subject: "Your Chute licence key",
      text: [
        "Thank you for buying Chute.",
        "",
        "Your licence key:",
        "",
        key,
        "",
        "Open Chute from the menu bar, choose Settings… → License, paste the key and press",
        "Activate. It is checked on your Mac — Chute never contacts a server to verify a licence.",
        "",
        "The chute command-line tool stays free and MIT licensed:",
        "  brew install avaluev/tap/chute",
        "",
        "Anything wrong, just reply to this email.",
      ].join("\n"),
    }),
  });
  // Loud in the log, quiet to Paddle: a 500 here makes Paddle retry (now harmless — the retry
  // re-mints the identical key — but still a second email).
  //
  // The STATUS ONLY. Resend's validation errors echo the offending field back, so logging the
  // body puts the customer's email address into Cloudflare's logs — the one thing this design
  // set out not to keep anywhere.
  if (!res.ok) console.error("resend failed", res.status);
  return res.ok;
}

export { mint, verifyPaddle, customerEmail };
