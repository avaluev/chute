import type { Metadata } from "next";
import { Page, H2 } from "@/components/chrome";
import { CONFIG } from "@/lib/config";
import { SELLER, sellerAddressLines } from "@/lib/seller";
import { REFUND, REFUND_CLAUSES } from "@/lib/refund-policy";

export const metadata: Metadata = {
  title: "Terms — Chute",
  description: "What you are buying, who is selling it, what it costs, and how to get your money back.",
};

/**
 * Paddle's domain review rejects an unidentified seller and an unstated refund policy. Both are
 * therefore load-bearing sections here, not boilerplate — §seller renders lib/seller.ts and
 * §refunds renders lib/refund-policy.ts, so neither can be edited away by accident and neither
 * can drift from the standalone /refunds page.
 *
 * Governing law ships with the seller identity, because a contract that names a trader and no
 * forum is worse than one that names neither. The clause preserves mandatory consumer rights in
 * the buyer's own country rather than trying to contract around them — the honest form, and the
 * only enforceable one in the EU and UK.
 */
export default function Terms() {
  return (
    <Page title="Terms"
          lead="What you are buying, who is selling it, what it costs, and how to get your money back.">
      <p className="text-sm">Last updated 27 August 2026.</p>

      <section id="seller" className="scroll-mt-24">
        <H2>Who is selling</H2>
        <p>
          Chute is sold by <strong className="text-foreground">{SELLER.registeredName}</strong>{" "}
          ({SELLER.legalName}), {SELLER.entityType}.
        </p>
        <address className="mt-3 not-italic">
          {sellerAddressLines().map((l) => <span key={l} className="block">{l}</span>)}
          <a className="mt-2 block text-foreground underline underline-offset-4"
             href={`mailto:${SELLER.contactEmail}`}>{SELLER.contactEmail}</a>
        </address>
        <p className="mt-3">
          Orders are fulfilled by <strong className="text-foreground">Paddle.com Market Ltd</strong>,
          who act as the merchant of record and reseller. Paddle handles the payment, the invoice
          and any sales tax or VAT, and their terms govern the transaction itself.
        </p>
      </section>

      <H2>What you are buying</H2>
      <p>
        A perpetual, non-exclusive licence to use Chute.app on Macs you own or control, for{" "}
        {CONFIG.price}, paid once. It includes every future v0.x update. A future v1.0 may be a
        paid upgrade; if it is, you will be told before it happens, and your v0.x licence keeps
        working regardless.
      </p>
      <p>
        The <code className="text-foreground">chute</code> command-line tool is separate and is MIT
        licensed. You may use, modify and redistribute it freely, including commercially, and
        nothing on this page restricts that.
      </p>

      <H2>The trial</H2>
      <p>
        {REFUND.trialDays} days, every feature, no card. When it ends the app’s Finder menu and
        menu bar stop working until a key is entered. The command-line tool is unaffected and keeps
        working forever.
      </p>

      <section id="refunds" className="scroll-mt-24">
        <H2>Refunds</H2>
        <p>{REFUND.headline}</p>
        {REFUND_CLAUSES.map((c) => (
          <div key={c.heading} className="mt-4">
            <p className="font-medium text-foreground">{c.heading}</p>
            {c.body.map((b) => <p key={b} className="mt-1">{b}</p>)}
          </div>
        ))}
      </section>

      <H2>What you may not do</H2>
      <p>
        Share, resell or publish your licence key. The key identifies your purchase; publishing it
        is the one thing that would force device checks on everyone else, which is exactly what
        this product is trying to avoid.
      </p>

      <H2>No warranty</H2>
      <p>
        Chute is provided as is. It runs destructive-looking operations on your files —{" "}
        <code className="text-foreground">unpack</code>, <code className="text-foreground">clean</code>,{" "}
        <code className="text-foreground">checkpoint</code> — and although every one of them
        previews before it acts, moves to the Trash rather than deleting, and never touches your git
        worktree, software has bugs. Keep backups. To the maximum extent the law allows, our
        liability is limited to what you paid.
      </p>

      <H2>Governing law</H2>
      <p>
        These terms are governed by the law of the {SELLER.address.country}. If you are a consumer,
        this does not deprive you of the protection of any mandatory consumer-protection law of the
        country where you live, and you may bring proceedings there. Nothing here limits rights
        that cannot lawfully be limited.
      </p>

      <H2>Changes</H2>
      <p>
        If these terms change, the version in effect when you bought governs your purchase. This
        page is in{" "}
        <a className="text-foreground underline underline-offset-4"
           href={`${CONFIG.repo}/commits/main/site/src/app/terms/page.tsx`}>git</a>, so every past
        version is public.
      </p>
    </Page>
  );
}
