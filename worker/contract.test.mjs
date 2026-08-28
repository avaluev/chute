// The Worker and the app must agree on the key format, byte for byte. They are written in
// different languages, months apart, and nobody finds out they diverged until a paying customer
// pastes a key that does nothing. So: pin it.
//
//   node worker/contract.test.mjs
import { mint as workerMint } from "./src/index.js";
import { mint as toolMint } from "./keygen.mjs";

const SEED = "7Jz0c4qogImeHMcHoTrn72gqI5BO1b5CQkdyHgASgQs=";   // test-only, from a transcript
const EMAIL = "buyer@example.com";
const AT = 1767225600;

// The exact string pinned in Sources/chutetests/LicenseSuite.swift. If this line has to change,
// every key ever issued has stopped verifying and the Swift suite must change with it.
const PINNED =
  "CHUTE-DwJikdIodhy2hAcsaLaEeP+ckcmwImsTV3YRb0uk9ynTmbEwOpkvDIgY4Z/k3c0JJAVuz0fIo4qFODqbzEkyCGJ1eWVyQGV4YW1wbGUuY29tfDE3NjcyMjU2MDA=";

const fromWorker = await workerMint(EMAIL, SEED, AT);
const fromTool = toolMint(SEED, EMAIL, AT);

let bad = 0;
const is = (label, got, want) => {
  if (got === want) { console.log(`  ok   ${label}`); }
  else { console.error(`  FAIL ${label}\n       got:  ${got}\n       want: ${want}`); bad++; }
};

is("keygen.mjs matches the key pinned in the Swift suite", fromTool, PINNED);

// A pipe is legal in an email local part, and NEITHER minter escapes it — they concatenate
// `email|issuedAt`. The app used to split on every pipe and reject such a key forever. Pinned
// here so the two minters and the Swift verifier can never drift apart on it again.
const PIPE_EMAIL = "a|b@example.com";
const PINNED_PIPE =
  "CHUTE-NfKttpwNJOMd6dzlOfYKrLmqDnRgsih0vf0p6YwK8WjBvFMbyw90/knRQkbtIR1EJgnjrfZtF7NJpGhMaSILAGF8YkBleGFtcGxlLmNvbXwxNzY3MjI1NjAw";
is("a pipe in the email mints the pinned key", await workerMint(PIPE_EMAIL, SEED, AT), PINNED_PIPE);
is("and keygen agrees on it", toolMint(SEED, PIPE_EMAIL, AT), PINNED_PIPE);
is("the Worker mints the identical key", fromWorker, PINNED);
is("Worker and keygen agree", fromWorker, fromTool);

console.log(bad ? `\n${bad} failed` : "\nlicence key format: Worker, keygen and app agree");
process.exit(bad ? 1 : 0);
