import type { Metadata } from "next";
import { Page, H2 } from "@/components/chrome";
import { CONFIG } from "@/lib/config";

export const metadata: Metadata = {
  title: "Privacy — Chute",
  description: "Chute collects nothing. This page explains exactly what that means and where the two exceptions are.",
};

export default function Privacy() {
  return (
    <Page title="Privacy"
          lead="Chute collects nothing about you. Here is exactly what that means, and where the two exceptions are.">
      <p className="text-sm">Last updated 27 August 2026.</p>

      <H2>The app</H2>
      <p>
        Chute has no analytics, no crash reporter, no telemetry and no account system. It does not
        know who you are and has no way to find out. There is no “anonymous usage data”, because
        there is no code that sends anything.
      </p>
      <p>
        Everything Chute writes stays on your Mac:{" "}
        <code className="text-foreground">~/.chute/</code> for session state and pending Finder
        requests, and{" "}
        <code className="text-foreground">~/Library/Application Support/Chute/</code> for your
        trial dates and licence key. You can delete both at any time.
      </p>

      <H2>The two exceptions, in full</H2>
      <p>
        <strong className="text-foreground">1. <code>chute gist</code>.</strong> This command, and
        only when you run it, uploads the files you name to GitHub as a secret gist using your own
        GitHub credentials. It redacts API keys and tokens before uploading. Nothing else in Chute
        sends a file anywhere.
      </p>
      <p>
        <strong className="text-foreground">2. Your licence key.</strong> Buying sends your email
        address to Paddle, our payment processor and merchant of record, so they can charge you
        and email you a key. We receive your email address and the fact that you bought. We never
        see your card details. The app itself never transmits your key — it verifies a signature
        locally.
      </p>

      <H2>This website</H2>
      <p>
        Cookieless page analytics, so we can tell whether anyone read this. No cookies, no
        cross-site tracking, no advertising pixels, no session recording. Nothing that would let
        us identify a visitor.
      </p>

      <H2>Payment data</H2>
      <p>
        Paddle.com Market Ltd is the merchant of record and the data controller for your payment.
        Their privacy policy governs it, and they handle tax and card data. We store your email
        address and purchase record so we can reissue a key or process a refund. We do not sell,
        rent or share it with anyone.
      </p>

      <H2>Your rights</H2>
      <p>
        Ask and we will tell you everything we hold about you (an email address and a purchase
        record) or delete it. Email{" "}
        <a className="text-foreground underline underline-offset-4" href={`mailto:${CONFIG.contact}`}>
          {CONFIG.contact}
        </a>. Deleting your record does not deactivate your licence, because your licence was
        never checked against a server in the first place.
      </p>

      <H2>Verifying all of this</H2>
      <p>
        You do not have to take our word for it. Chute is{" "}
        <a className="text-foreground underline underline-offset-4" href={CONFIG.repo}>open source</a>
        {" "}— search it for network code. There is one HTTP call in the whole product, and it is
        the gist command.
      </p>
    </Page>
  );
}
