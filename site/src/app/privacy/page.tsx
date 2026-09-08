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

      <H2>The one exception, in full</H2>
      <p>
        <strong className="text-foreground"><code>chute gist</code>.</strong> This command, and
        only when you run it, uploads the files you name to GitHub as a secret gist using your own
        GitHub credentials. It redacts API keys and tokens before uploading. Nothing else in Chute
        sends a file anywhere.
      </p>

      <H2>This website</H2>
      <p>
        No analytics of any kind. No cookies, no cross-site tracking, no advertising pixels, no
        session recording, and no script that counts you. There is nothing here that would let us
        identify a visitor, or tell us that you visited at all.
      </p>

      <H2>Payment data</H2>
      <p>
        There is none. Chute is free and MIT licensed: there is no store, no checkout, no payment
        processor and no customer record, because nothing is sold. Until 2026-09-08 this section
        described Paddle as merchant of record for a $19 licence. That product no longer exists,
        and neither does the data it would have collected.
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
