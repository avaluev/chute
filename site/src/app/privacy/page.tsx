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
      <p className="text-sm">Last updated 9 September 2026.</p>

      <H2>The app</H2>
      <p>
        Chute has no analytics, no crash reporter, no telemetry and no account system. It does not
        know who you are and has no way to find out. There is no “anonymous usage data”, because
        there is no code that sends anything.
      </p>
      <p>
        Everything Chute writes stays on your Mac. What it keeps <em>about your use of it</em>
        lives in one place —{" "}
        <code className="text-foreground">~/.chute/</code>, holding session state and pending
        Finder requests — and you can delete it at any time. There used to be a second folder, for
        a trial clock and a licence key; both are gone with the licensing code that wrote them.
      </p>
      <p>
        Chute also writes the files you <em>ask</em> it to write, where you ask for them: a new
        file from your clipboard, a rules file from <code className="text-foreground">seed</code>,
        a <code className="text-foreground">.env</code> from your Keychain, a git branch from{" "}
        <code className="text-foreground">checkpoint</code>. That is the product doing its job,
        not data collection, and every one of those is something you typed or clicked. None of it
        leaves the machine.
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
        described Paddle as merchant of record for a paid licence. That product no longer exists,
        and neither does the data it would have collected.
      </p>

      <H2>Your rights</H2>
      <p>
        There is nothing to exercise them against: no account, no email address, no purchase
        record, nothing held anywhere to ask about or delete. Until 2026-09-08 this section
        offered to send you the data behind a licence you could buy — that section outlived the
        product it described by a day, and this one replaces it. If you want to ask anything
        anyway, email{" "}
        <a className="text-foreground underline underline-offset-4" href={`mailto:${CONFIG.contact}`}>
          {CONFIG.contact}
        </a>.
      </p>

      <H2>Verifying all of this</H2>
      <p>
        You do not have to take our word for it. Chute is{" "}
        <a className="text-foreground underline underline-offset-4" href={CONFIG.repo}>open source</a>
        {" "}— search it for network code. There is none:{" "}
        <code className="text-foreground">grep -rn URLSession Sources/</code> returns nothing, and
        no socket is opened anywhere in the codebase.
      </p>
      <p>
        Two things do reach the network, and neither is Chute doing it.{" "}
        <code className="text-foreground">chute gist</code> runs your own{" "}
        <code className="text-foreground">gh</code>, with your credentials, on the files you named,
        after redacting keys — and only when you pass <code className="text-foreground">--force</code>.
        And a handful of menu items hand a URL to your browser: the repository, the issue form,
        this site. Your browser makes those requests, the way it would if you had typed the address.
      </p>
    </Page>
  );
}
