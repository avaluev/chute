import type { Metadata } from "next";
import { Page, H2 } from "@/components/chrome";
import { CONFIG } from "@/lib/config";

export const metadata: Metadata = {
  title: "Support — Chute",
  description: "How to get help, how fast, and who you are talking to.",
};

export default function Support() {
  return (
    <Page title="Support" lead="How to get help, how fast, and who you are actually talking to.">
      <H2>Email</H2>
      <p>
        <a className="text-foreground underline underline-offset-4" href={`mailto:${CONFIG.contact}`}>
          {CONFIG.contact}
        </a>{" "}
        — for anything: a licence key that will not activate, a refund, a bug, or a question about
        whether Chute does the thing you need.
      </p>
      <p>{CONFIG.supportHours}</p>

      <H2>Bugs</H2>
      <p>
        Chute can write its own bug report. In the menu bar choose{" "}
        <strong className="text-foreground">Report a Problem…</strong> — it copies a redacted
        diagnostic summary to your clipboard and opens a prefilled issue. The diagnostics contain
        no file contents and no secrets; you can read the whole thing before you paste it.
      </p>
      <p>
        Public issues live at{" "}
        <a className="text-foreground underline underline-offset-4" href={`${CONFIG.repo}/issues`}>
          {CONFIG.repo.replace("https://", "")}/issues
        </a>. If you would rather not report in public, email instead.
      </p>

      <H2>Lost your licence key?</H2>
      <p>
        Email from the address you bought with and we will resend it. Keys are reissuable
        indefinitely and there is no device limit to reset — your key was never tied to a machine.
      </p>

      <H2>Who is behind this</H2>
      <p>
        Chute is made and supported by{" "}
        <strong className="text-foreground">{CONFIG.seller.name}</strong>
        {CONFIG.seller.entity ? `, trading as ${CONFIG.seller.entity}` : ""}
        {CONFIG.seller.country ? `, ${CONFIG.seller.country}` : ""}. One person, not a company
        with a support tier. Orders are fulfilled by Paddle.com Market Ltd as merchant of record.
      </p>

      <H2>If Chute disappears</H2>
      <p>
        The command-line tool is MIT licensed and its whole source is public, so it cannot be
        taken away from you. The app verifies its licence offline and never calls home, so it
        keeps working whether or not this website, this business, or its author still exists.
      </p>
    </Page>
  );
}
