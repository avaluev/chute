import type { Metadata } from "next";
import { Page, H2 } from "@/components/chrome";
import { CONFIG } from "@/lib/config";

export const metadata: Metadata = {
  title: "Terms — Chute",
  description: "Chute is MIT licensed. These are the terms, which are the MIT licence and very little else.",
};

/**
 * THIS PAGE USED TO BE A SALES CONTRACT and it is now a licence notice.
 *
 * Until 2026-09-08 Chute was $19 with a 14-day trial, sold through Paddle as merchant of record.
 * Paddle's domain review rejects an unidentified seller, so this page carried the founder's full
 * legal name, entity type and home address in Bishkek — published solely to satisfy that review.
 *
 * There is no Paddle, no price and no seller. The identity came down with them, which is the
 * point worth recording: that address was on the public internet for one reason, and the reason
 * is gone. Do not reintroduce it. If a future product needs a seller identity, it gets its own
 * page and its own decision.
 */
export default function Terms() {
  return (
    <Page title="Terms"
          lead="Chute is free and MIT licensed. That makes this page short.">
      <H2>The licence</H2>
      <p>
        Chute — the macOS app, the Finder extension and the <code>chute</code> command-line tool —
        is released under the MIT licence. You may use it, copy it, modify it, and distribute it,
        commercially or otherwise, provided the copyright notice travels with it. The full text is
        in{" "}
        <a className="text-foreground underline underline-offset-4" href={`${CONFIG.repo}/blob/main/LICENSE`}>
          LICENSE
        </a>{" "}
        in the repository, and it is the authoritative version. Nothing on this page overrides it.
      </p>

      <H2>Price</H2>
      <p>
        There is none. No purchase, no subscription, no licence key, no account, and no trial that
        ends. Chute was sold for $19 with a 14-day trial for eleven days in 2026; that product was
        withdrawn and the licensing machinery deleted rather than switched off.
      </p>

      <H2>Warranty</H2>
      <p>
        There is none of that either, and the MIT licence says so in capital letters: the software
        is provided &ldquo;as is&rdquo;, without warranty of any kind. Chute previews destructive
        actions before it takes them, moves files to the Trash rather than deleting them, and
        never touches your git worktree, index or HEAD — but it runs on your machine, against your
        files, and you are the one who decides to run it.
      </p>

      <H2>What Chute does with your data</H2>
      <p>
        Nothing leaves your machine. There is no telemetry, no analytics, no crash reporting and
        no network code at all, with one exception you invoke deliberately: <code>chute gist</code>{" "}
        uploads the files you name, using your own GitHub credentials, after redacting keys. The{" "}
        <a className="text-foreground underline underline-offset-4" href="/privacy/">privacy page</a>{" "}
        goes through it properly.
      </p>

      <H2>Support</H2>
      <p>
        Best effort, by one person, at{" "}
        <a className="text-foreground underline underline-offset-4" href={`mailto:${CONFIG.contact}`}>
          {CONFIG.contact}
        </a>{" "}
        or in{" "}
        <a className="text-foreground underline underline-offset-4" href={`${CONFIG.repo}/issues`}>
          GitHub issues
        </a>. Free software carries no support obligation, and pretending otherwise would be the
        dishonest part. See{" "}
        <a className="text-foreground underline underline-offset-4" href="/support/">Support</a>{" "}
        for what to expect in practice.
      </p>

      <H2>Contributions</H2>
      <p>
        Pull requests are welcome and are accepted under the same MIT licence. There is no
        contributor licence agreement to sign.
      </p>
    </Page>
  );
}
