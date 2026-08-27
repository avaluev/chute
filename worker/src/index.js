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

    const email = event.data?.customer?.email ?? event.data?.custom_data?.email;
    if (!email) return new Response("no email on the transaction", { status: 200 });

    const key = await mint(email, env.CHUTE_LICENSE_SEED);
    await email_(env, email, key);
    return new Response("issued", { status: 200 });
  },
};

/**
 * Paddle signs `${timestamp}:${rawBody}` with HMAC-SHA256.
 * Header shape: `ts=1671552777;h1=<hex>`.
 */
async function verifyPaddle(raw, header, secret) {
  if (!secret) return false;
  const parts = Object.fromEntries(
    header.split(";").map((p) => p.split("=")).filter((p) => p.length === 2)
  );
  if (!parts.ts || !parts.h1) return false;

  // A replay window. Without it a captured webhook mints a fresh key forever.
  const age = Math.abs(Date.now() / 1000 - Number(parts.ts));
  if (!Number.isFinite(age) || age > 300) return false;

  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]
  );
  const mac = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${parts.ts}:${raw}`));
  return timingSafeEqual(hex(mac), parts.h1);
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
  // Web Crypto wants PKCS#8; the secret is stored as the bare 32-byte seed, so wrap it.
  const seed = Uint8Array.from(atob(seedB64), (c) => c.charCodeAt(0));
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
  // Loud in the log, quiet to Paddle: a 500 here makes Paddle retry and mint a SECOND key.
  if (!res.ok) console.error("resend failed", res.status, await res.text());
}

export { mint, verifyPaddle };
