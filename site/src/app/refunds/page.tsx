import type { Metadata } from "next";
import { Page, H2 } from "@/components/chrome";
import { REFUND, REFUND_CLAUSES } from "@/lib/refund-policy";
import { CONFIG } from "@/lib/config";

export const metadata: Metadata = {
  title: "Refund policy — Chute",
  description: REFUND.headline,
};

/** Renders lib/refund-policy.ts, the same source /terms#refunds renders. Neither summarises the
 *  other, so the standalone policy and the contract cannot drift apart. */
export default function Refunds() {
  return (
    <Page title="Refund policy" lead={REFUND.headline}>
      <p className="text-sm">Last updated 27 August 2026.</p>
      {REFUND_CLAUSES.map((c) => (
        <section key={c.heading}>
          <H2>{c.heading}</H2>
          {c.body.map((b) => <p key={b} className="mt-3">{b}</p>)}
        </section>
      ))}
      <p className="pt-4">
        Support address:{" "}
        <a className="text-foreground underline underline-offset-4" href={`mailto:${CONFIG.contact}`}>
          {CONFIG.contact}
        </a>
      </p>
    </Page>
  );
}
