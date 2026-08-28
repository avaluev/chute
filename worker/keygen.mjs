#!/usr/bin/env node
// Ed25519 keys for Chute licences. The PRIVATE key never enters the app, this repo, or a log.
//
//   node worker/keygen.mjs new                    → a fresh keypair (run once, ever)
//   CHUTE_LICENSE_SEED=… node worker/keygen.mjs mint <email>   → one licence key, by hand
//
// The seed comes from the environment, never from argv. As an argument it was written to
// ~/.zsh_history in plaintext and was readable by any local process through `ps` for the life of
// the command — a new, permanent copy of the one secret this file's own header says must never
// be persisted anywhere.
//
// The public half is embedded in Sources/ChuteCore/License.swift. The private half goes into a
// Cloudflare Worker secret and a password manager, and nowhere else. Losing it means no new
// licences can be issued; leaking it means anyone can issue their own.
import { generateKeyPairSync, sign, createPrivateKey } from "node:crypto";

/// A licence key is `CHUTE-` + base64( signature(64 bytes) || "email|issuedAtEpoch" ).
/// Everything needed to check it travels inside the key, so the app never asks a server.
export function mint(privB64, email, issuedAt = Math.floor(Date.now() / 1000)) {
  // PKCS#8 wrapper around a bare 32-byte Ed25519 seed, so the Worker secret can be just the seed.
  const der = Buffer.concat([
    Buffer.from("302e020100300506032b657004220420", "hex"),
    Buffer.from(privB64, "base64"),
  ]);
  const key = createPrivateKey({ key: der, format: "der", type: "pkcs8" });
  const payload = Buffer.from(`${email}|${issuedAt}`, "utf8");
  const sig = sign(null, payload, key);
  return "CHUTE-" + Buffer.concat([sig, payload]).toString("base64");
}

export function newKeypair() {
  const { publicKey, privateKey } = generateKeyPairSync("ed25519");
  const raw = (k, type) => k.export({ format: "der", type }).subarray(type === "spki" ? 12 : 16);
  return { public: raw(publicKey, "spki").toString("base64"),
           private: raw(privateKey, "pkcs8").toString("base64") };
}

// CLI only when run directly — this file is also imported by the Worker and by tests.
if (import.meta.url === `file://${process.argv[1]}`) {
  const cmd = process.argv[2];
  if (cmd === "new") {
    const k = newKeypair();
    console.log("PUBLIC  (embed in Sources/ChuteCore/License.swift):\n  " + k.public);
    console.log("PRIVATE (Cloudflare Worker secret CHUTE_LICENSE_SEED — never commit):\n  " + k.private);
  } else if (cmd === "mint") {
    const privB64 = process.env.CHUTE_LICENSE_SEED;
    const email = process.argv[3];
    if (!privB64 || !email) {
      console.error("usage: CHUTE_LICENSE_SEED=<privateBase64> node worker/keygen.mjs mint <email>");
      console.error("       (the seed is read from the environment so it never enters shell history)");
      process.exit(1);
    }
    console.log(mint(privB64, email));
  } else {
    console.error("usage: keygen.mjs new | CHUTE_LICENSE_SEED=… keygen.mjs mint <email>");
    process.exit(1);
  }
}
