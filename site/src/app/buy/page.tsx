import type { Metadata } from "next";
import { Page, H2 } from "@/components/chrome";
import { BuyButton } from "@/components/buy-button";
import { CheckoutBridge } from "@/components/checkout-bridge";
import { CONFIG } from "@/lib/config";

export const metadata: Metadata = {
  title: "Buy Chute — $19 once",
  description: "One payment. No subscription, no account. 14 days free first, and the command-line tool is free forever.",
};

export default function Buy() {
  return (
    <Page title="Buy Chute"
          lead={`${CONFIG.price} once. No subscription, no account, no renewal to forget about.`}>
      {/* Paddle's "default payment link" points here, so this page must be able to HOST a
          checkout, not merely describe one. See components/checkout-bridge.tsx. */}
      <CheckoutBridge />
      <BuyButton />

      <H2>What the payment is for</H2>
      <p>
        The <code className="text-foreground">chute</code> command-line tool is free and MIT
        licensed, and stays that way whatever happens to this page. The {CONFIG.price} buys the
        app: the Finder right-click menu, the menu-bar session switcher, the local-server list and
        the ⌥⌘N hotkey — the sandboxed, signed Finder extension being the part that is genuinely
        hard to build yourself.
      </p>

      <H2>How the licence works</H2>
      <p>
        After paying you get a key by email. Open Chute from the menu bar, choose
        Settings… → License, paste it, press Activate. That is the whole flow.
      </p>
      <p>
        The key is an Ed25519 signature that your Mac verifies on its own.{" "}
        <strong className="text-foreground">Chute never contacts a server to check a licence</strong>{" "}
        — not at activation, not at launch, not ever. No account, no device limit, no
        “deactivate before reinstalling”. If this website disappears tomorrow, your copy keeps
        working.
      </p>

      <H2>Refunds</H2>
      <p>
        {CONFIG.refundDays} days, no questions asked. Email{" "}
        <a className="text-foreground underline underline-offset-4" href={`mailto:${CONFIG.contact}`}>
          {CONFIG.contact}
        </a>{" "}
        and say the word “refund”. You do not have to explain, and you can keep using the free CLI.
      </p>

      <H2>Before you pay</H2>
      <p>
        Do not. Take the {CONFIG.trialDays}-day trial first — every feature, no card required. If
        it has not saved you an hour by day fourteen, it was never going to.
      </p>
    </Page>
  );
}
