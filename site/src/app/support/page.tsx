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
        — for a bug, a question about whether Chute does the thing you need, or anything else.
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

      <H2>Who is behind this</H2>
      <p>
        Chute is made and supported by <strong className="text-foreground">Alexandr Valuev</strong>.
        One person, not a company with a support tier. It is free and MIT licensed, so support is
        best effort — but the source is public, which means you are never blocked waiting for me.
      </p>
      <p>
        <a className="text-foreground underline underline-offset-4" href={CONFIG.social.github}>GitHub</a>
        {" · "}
        <a className="text-foreground underline underline-offset-4" href={CONFIG.social.linkedin}>LinkedIn</a>
        {" · "}
        <a className="text-foreground underline underline-offset-4" href={CONFIG.social.telegram}>Telegram</a>
      </p>

      <H2>If Chute disappears</H2>
      <p>
        All of it is MIT licensed and the whole source is public, so it cannot be taken away from
        you. Nothing calls home and nothing verifies anything, so it keeps working whether or not
        this website, or its author, still exists. Fork it.
      </p>
    </Page>
  );
}
