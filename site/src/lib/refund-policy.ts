// THE REFUND POLICY, ONCE.
//
// Rendered in two places that a reviewer and a buyer each look for by name: the standalone
// /refunds page, and the §Refunds section of /terms. Neither is a summary or a link to the other
// — both render this, so the contract carries the policy in full and the two cannot drift apart.
//
// Paddle's domain review requires the refund policy to be "clearly accessible via navigation".
// Findable, not merely present: a policy three clicks deep fails. scripts/check-paddle.mjs pins
// both the page and the footer link.

import { CONFIG } from "./config";

// The two numbers are CONFIG's; restating them here is how a price page and a policy page
// disagree. The headline is prose and derives from the same number.
export const REFUND = {
  windowDays: CONFIG.refundDays,
  trialDays: CONFIG.trialDays,
  headline: `${CONFIG.refundDays} days, no questions asked, no reason required.`,
} as const;

export interface RefundClause { heading: string; body: string[] }

export const REFUND_CLAUSES: RefundClause[] = [
  {
    heading: "How to get a refund",
    body: [
      "Email the support address from the address you bought with, and say the word “refund”. You do not need to give a reason and you will not be asked for one.",
    ],
  },
  {
    heading: "The window",
    body: [
      `${REFUND.windowDays} days from the date of purchase. Because there is a free ${REFUND.trialDays}-day trial of the complete app before any payment, you will have used the software properly before spending anything — that is deliberate, and it is why this policy can be unconditional.`,
    ],
  },
  {
    heading: "How long it takes",
    body: [
      "Refunds are issued by Paddle.com Market Ltd, our merchant of record. We approve them the same day we read the email. Paddle normally returns the money to the original payment method within five working days, though a bank may take longer to show it.",
    ],
  },
  {
    heading: "What happens to your licence",
    body: [
      "Your key stops being a valid purchase and we ask you to stop using the app. There is no remote kill switch: Chute never contacts a server, so nothing can reach into your Mac and disable it. This is an honour-system product, and we would rather trust you than build surveillance into a tool that sells itself on not having any.",
      "The chute command-line tool is MIT licensed and yours to keep regardless. A refund does not affect it.",
    ],
  },
  {
    heading: "Duplicate purchases",
    body: [
      `Chute is a single one-time product, so refunds are always for the full amount. If you bought twice by mistake, tell us and we will refund the duplicate immediately, outside the ${REFUND.windowDays}-day window.`,
    ],
  },
  {
    heading: "Chargebacks",
    body: [
      "Please email first. A chargeback costs us a fee on top of the refund and takes months; an email takes a day and gets you the same money.",
    ],
  },
];
