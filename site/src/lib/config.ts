/** Everything that changes when a domain, a repo or an install channel changes. One file. */
export const CONFIG = {
  domain: "chutedev.com",
  repo: "https://github.com/avaluev/chute",
  /** The release page, not a bare .dmg URL: the reader needs the Gatekeeper instructions that
   *  sit beside the asset far more than they need to save one click. */
  download: "https://github.com/avaluev/chute/releases/latest",
  brew: "brew install avaluev/tap/chute",
  /** True since 2026-08-28: `avaluev/homebrew-tap` exists and installs. Verified with
   *  `brew info avaluev/tap/chute`. While this is false every surface shows the source install
   *  instead, because printing an install command that fails is worse than printing none — and
   *  the reader most likely to paste it is the sceptic deciding whether to trust a stranger's
   *  utility. `npm run check:claims` fails the deploy if this flag and the pages disagree. */
  brewLive: true,

  /** FREE AND MIT, ALL OF IT, SINCE 2026-09-08.
   *
   *  There is no price, no trial, no licence key and no store account. Chute was open-core for
   *  eleven days — a 14-day trial and a $19 one-time key, minted offline by a Cloudflare Worker
   *  from a Paddle webhook. All of it is deleted: the Worker, the Ed25519 key check, the trial
   *  clock, the buy page, and the seller identity that Paddle's domain review required to be
   *  published. That last one is why this matters beyond licensing — the review demanded a full
   *  legal name and a home address on a public page, and nothing asks for that any more.
   *
   *  Do not add a price back to this file. Add it to a NEW product. */
  license: "MIT",

  contact: "hello@chutedev.com",
  supportHours: "One person, European hours. Most replies within one business day, always within three.",

  /** Where a human can reach the author. A Telegram HANDLE, never a phone number: a handle can
   *  be abandoned, a number cannot be un-scraped. */
  social: {
    github: "https://github.com/avaluev",
    linkedin: "https://www.linkedin.com/in/valuev/",
    telegram: "https://t.me/asnkt",
  },
} as const;
