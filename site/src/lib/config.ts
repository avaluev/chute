/** Everything that changes when a price, a domain or a store account changes. One file. */
export const CONFIG = {
  domain: "chutedev.com",
  repo: "https://github.com/avaluev/chute",
  download: "https://github.com/avaluev/chute/releases/latest",
  brew: "brew install avaluev/tap/chute",
  /** True since 2026-08-28: `avaluev/homebrew-tap` exists and installs 0.2.0. Verified with
   *  `brew info avaluev/tap/chute`. While this is false every surface shows the source install
   *  instead, because printing an install command that fails is worse than printing none — and
   *  the reader most likely to paste it is the sceptic deciding whether to trust a stranger's
   *  $19 utility. `npm run check:claims` fails the deploy if this flag and the pages disagree. */
  brewLive: true,
  price: "$19",
  trialDays: 14,
  refundDays: 30,
  contact: "hello@chutedev.com",
  supportHours: "One person, European hours. Most replies within one business day, always within three.",

  /** Paddle's reviewer checks that a real, identifiable seller stands behind the product.
   *  FILL THESE IN before submitting for verification — `npm run check:paddle` fails while any
   *  is empty, so an unfinished identity cannot reach production. */
  seller: {
    name: "Alexandr Valuev",
    country: "",   // e.g. "Estonia" — the country you invoice from
    entity: "",    // registered company name, or "Sole trader" if you trade as yourself
  },

  /** Paddle. Empty until the seller account exists — the buy page checks and degrades to the
   *  trial download rather than opening a checkout that cannot complete. */
  paddle: {
    token: process.env.NEXT_PUBLIC_PADDLE_TOKEN ?? "",
    priceId: process.env.NEXT_PUBLIC_PADDLE_PRICE_ID ?? "",
    environment: (process.env.NEXT_PUBLIC_PADDLE_ENV ?? "production") as "production" | "sandbox",
  },
} as const;
