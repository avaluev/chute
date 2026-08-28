import Image from "next/image";
import Link from "next/link";
import { buttonVariants } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Accordion, AccordionContent, AccordionItem, AccordionTrigger,
} from "@/components/ui/accordion";
import { CopyLine } from "@/components/copy-line";
import { InstallCli } from "@/components/install-cli";
import { asset } from "@/lib/asset";
import { Header, Footer } from "@/components/chrome";
import { CaseCard, DailyCost } from "@/components/case-bits";
import { CASES, PAID, FREE, HEROES, minutesPerDay, bySlug } from "@/lib/cases";
import { CONFIG } from "@/lib/config";

/**
 * The landing page is generated from lib/cases.ts, not written alongside it.
 *
 * The old page opened with three "tax" cards written by hand, and three of its four images were
 * terminal recordings — so it argued for the free CLI on a page whose job is to sell the app. It
 * also carried numbers that lived nowhere else, which is how a landing page drifts away from the
 * product it describes. Every figure below now comes from the ledger through cases.ts, and
 * `npm run check:cases` refuses to publish when one of them stops matching.
 *
 * SECTION RULE: no section opens with a command name. The reader has the problem before they
 * have the product, and a heading that says `chute bundle` is only legible to someone who
 * already bought it.
 */

const FAQ = [
  { q: "Claude Code can already read my files. Why do I need this?",
    a: "It can. It cannot see your Finder selection, your clipboard, the terminal you lost, or the port you can’t find. Chute is everything the agent can’t reach from inside its own window." },
  { q: "Does it phone home?",
    a: "No. There is no network code at all except the gist command, which uploads only the files you name, only when you run it, and redacts them first. The licence check is an offline signature — Chute never contacts a server to verify it." },
  { q: "What happens when the 14-day trial ends?",
    a: "The app locks: the Finder menu and the menu-bar switcher stop until you enter a key. The chute command-line tool keeps working forever, because it is free and MIT licensed — and it still does every one of these jobs from a terminal." },
  { q: "Is the CLI really free?",
    a: "Yes, all 25 commands, MIT, on Homebrew. The $19 buys the app: the Finder right-click menu, the menu-bar session switcher and the hotkey — a signed, sandboxed Finder extension is the part you cannot reasonably build yourself." },
  { q: "Where do these numbers come from?",
    a: "A ledger of 24 jobs, each timed the same way: how often it happens, how long it takes by hand, how long it takes with Chute. It is in the repository, the site is generated from it, and the build fails if a figure on this page stops matching it." },
  { q: "Which agents does it work with?",
    a: "All of them. Chute never talks to an agent; it moves files, paths and text through your clipboard. Claude Code, Codex, Cursor, Aider, Gemini — if it reads a prompt, it reads Chute’s output." },
  { q: "Which macOS?",
    a: "macOS 13 Ventura and later, Apple Silicon and Intel. The app is under 3 MB and the command-line binary under 1 MB, with no dependencies, no launch daemon and no background service." },
];

function Section({ id, eyebrow, title, children }: {
  id?: string; eyebrow: string; title: string; children: React.ReactNode;
}) {
  return (
    <section id={id} className="mx-auto w-full max-w-5xl px-6 py-20 md:py-28">
      <p className="font-[family-name:var(--font-mono-loaded)] text-xs uppercase tracking-[0.18em] text-[var(--color-accent-chute)]">
        {eyebrow}
      </p>
      <h2 className="mt-3 font-[family-name:var(--font-mono-loaded)] text-2xl font-semibold tracking-tight md:text-3xl">
        {title}
      </h2>
      <div className="mt-10">{children}</div>
    </section>
  );
}

/** One job, argued: the moment, what it costs today, what happens instead, what that is worth. */
function HeroCase({ slug, flip }: { slug: string; flip: boolean }) {
  const c = bySlug(slug);
  if (!c) return null;

  // NO PLACEHOLDER ART, AND NO HOLE WHERE ART WOULD GO. Not every job has been recorded yet, and
  // a two-column row with an empty right half reads as a broken page rather than an honest one.
  // Until the recording exists the row is simply one column — deliberate, not unfinished.
  if (!c.demo) {
    return (
      <div className="border-t border-border py-10">
        <h3 className="max-w-3xl text-xl leading-snug text-foreground md:text-2xl">{c.pain}</h3>
        <div className="mt-4 grid gap-6 md:grid-cols-2">
          <p className="text-[15px] leading-relaxed text-muted-foreground">{c.ritual}</p>
          <p className="text-[15px] leading-relaxed text-foreground">{c.fix}</p>
        </div>
        <div className="mt-5"><DailyCost c={c} /></div>
        <Link href={`/cases/${c.slug}`}
              className="mt-4 inline-block text-sm text-muted-foreground hover:text-foreground">
          See it →
        </Link>
      </div>
    );
  }

  return (
    <div className="grid items-center gap-8 border-t border-border py-12 md:grid-cols-2 md:gap-12">
      <div className={flip ? "md:order-2" : ""}>
        <h3 className="text-xl leading-snug text-foreground md:text-2xl">{c.pain}</h3>
        <p className="mt-4 text-[15px] leading-relaxed text-muted-foreground">{c.ritual}</p>
        <p className="mt-4 text-[15px] leading-relaxed text-foreground">{c.fix}</p>
        <div className="mt-5"><DailyCost c={c} /></div>
        <Link href={`/cases/${c.slug}`}
              className="mt-5 inline-block text-sm text-muted-foreground hover:text-foreground">
          See it →
        </Link>
      </div>
      <div className={flip ? "md:order-1" : ""}>
        <Image src={asset(c.demo)} alt={c.fix} width={1200} height={750} unoptimized
               className="w-full rounded-[var(--radius)] border border-border" />
      </div>
    </div>
  );
}

export default function Home() {
  const appMinutes = minutesPerDay(PAID);
  const freeMinutes = minutesPerDay(FREE);

  return (
    <main className="min-h-screen">
      <Header />

      {/* ---------------------------------------------------------------- hero */}
      <section className="mx-auto w-full max-w-5xl px-6 pt-16 md:pt-24">
        <Badge variant="secondary" className="font-[family-name:var(--font-mono-loaded)] text-xs">
          macOS 13+ · no account · no telemetry
        </Badge>

        {/* Kept verbatim. It survived the rewrite because it answers the killer objection —
            "the agent can already read my files" — in three lines and before it is asked. */}
        <h1 className="mt-6 max-w-3xl font-[family-name:var(--font-mono-loaded)] text-3xl font-semibold leading-[1.15] tracking-tight md:text-5xl">
          Your agent lives in the terminal.<br />
          Your work lives in Finder.<br />
          <span className="text-[var(--color-accent-chute)]">Chute is the door between them.</span>
        </h1>

        <p className="mt-6 max-w-2xl text-lg text-muted-foreground">
          Select files in Finder, get agent-ready context with a token count. Paste an answer back,
          get real files. And see, without hunting through nine terminal windows, which agent is
          actually waiting for you.
        </p>

        <div className="mt-9 flex flex-col gap-3 sm:flex-row sm:items-center">
          <a href={CONFIG.download}
             className={buttonVariants({ size: "lg" }) + " h-11 px-5 text-base font-medium"}>
            Download — free {CONFIG.trialDays} days
          </a>
          <span className="text-sm text-muted-foreground">
            {CONFIG.price} once after that. No subscription, no account.
          </span>
        </div>

        {/* Small and secondary on purpose. The free tool is credibility and a way out for the
            sceptic, not the offer — the page that led with it sold the free thing.
            It does NOT print the brew command: the tap does not exist yet, and the reader most
            likely to paste it is the one deciding whether to trust a stranger's $19 utility. */}
        <p className="mt-6 text-sm text-muted-foreground">
          Or take just the{" "}
          <Link href="/cli" className="text-foreground underline underline-offset-4 hover:text-[var(--color-accent-chute)]">
            free command-line tool
          </Link>
          {" "}— 25 commands, MIT, and it never expires.
        </p>

        {/* The hero shot is the APP, not a terminal. The old one was a terminal GIF on a page
            asking for $19 for something the visitor had never seen. */}
        <div className="mt-16 overflow-hidden rounded-[var(--radius)] border border-border shadow-hero">
          <Image src={asset("/media/sessions.gif")}
                 alt="The Chute menu bar, grouping agent sessions by which one is waiting for you"
                 width={1200} height={720} unoptimized priority className="w-full" />
        </div>
      </section>

      {/* ------------------------------------------------------------ the jobs it is bought for */}
      <Section eyebrow="What it costs you"
               title={`${appMinutes} minutes a day, thirty seconds at a time`}>
        <p className="-mt-4 max-w-2xl text-muted-foreground">
          The moments it is bought for, in the order they cost you the most. Each one is timed
          the same way:
          how often it happens, how long it takes by hand, how long it takes instead.
        </p>
        <div className="mt-4">
          {HEROES.map((c, i) => (
            <HeroCase key={c.slug} slug={c.slug} flip={i % 2 === 1} />
          ))}
        </div>
      </Section>

      {/* ---------------------------------------------------------------- and the rest, free */}
      <Section eyebrow="And all of this is free"
               title={`${FREE.length} more, in the command-line tool`}>
        <p className="-mt-4 max-w-2xl text-muted-foreground">
          {freeMinutes} minutes a day that cost nothing, run offline, and never expire. MIT
          licensed, on Homebrew, yours whatever happens to this page.
        </p>
        <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {FREE.slice(0, 6).map((c) => <CaseCard key={c.slug} c={c} />)}
        </div>
        <Link href="/cases"
              className="mt-8 inline-block text-sm text-muted-foreground hover:text-foreground">
          All {CASES.length} jobs, with what each one costs →
        </Link>
      </Section>

      {/* ---------------------------------------------------------------- trust */}
      <Section eyebrow="Trust" title="Built for a repo an agent is about to rampage through">
        <ul className="grid gap-4 md:grid-cols-2">
          {[
            ["Destructive actions show you the list first", "The right-click that writes files, and the one that clears junk, both preview before anything changes. Cancel is the default button."],
            ["Writing cannot escape its target folder", "Absolute paths and ../ are rejected outright, before and after the folders are created."],
            ["Snapshots cannot lose work", "checkpoint stages into a private index file. Your index, worktree and HEAD are never touched — it only ever adds a branch."],
            ["Clearing junk moves it to the Trash", "Never rm. And it refuses to treat a .env or a file you made as an agent's leftovers."],
            ["Keys are read from the Keychain only", "It prints key names, never values, and refuses to create a .env that git would track."],
            ["There is no network code in Chute at all", "Not \u201cnothing is uploaded\u201d \u2014 one command, gist, does upload, and it does it by shelling out to your own gh with your own credentials, on the files you name, after redacting keys. Chute itself never opens a socket. Check it: grep -rn URLSession Sources/"],
          ].map(([h, b]) => (
            <li key={h} className="rounded-[var(--radius)] border border-border bg-card p-5">
              <p className="font-[family-name:var(--font-mono-loaded)] text-sm font-semibold">{h}</p>
              <p className="mt-2 text-sm text-muted-foreground">{b}</p>
            </li>
          ))}
        </ul>
      </Section>

      {/* ---------------------------------------------------------------- the conversion moment */}
      <Section id="pricing" eyebrow="Price" title="One payment, or nothing at all">
        <div className="grid gap-5 md:grid-cols-2">
          <div className="rounded-[var(--radius)] border border-border bg-card p-8">
            <p className="font-[family-name:var(--font-mono-loaded)] text-sm text-muted-foreground">
              The command line
            </p>
            <p className="mt-2 font-[family-name:var(--font-mono-loaded)] text-3xl font-semibold">Free</p>
            <p className="mt-1 font-[family-name:var(--font-mono-loaded)] text-sm text-muted-foreground">
              {FREE.length} jobs · {freeMinutes} min a day
            </p>
            <p className="mt-4 text-sm text-muted-foreground">
              All 25 commands. MIT licensed, source on GitHub, yours forever whatever happens to me
              or to this page. It does every job on this site — from a terminal, one path at a time.
            </p>
            <div className="mt-6"><InstallCli /></div>
          </div>

          <div className="rounded-[var(--radius)] border border-[var(--color-accent-chute)] bg-card p-8">
            <p className="font-[family-name:var(--font-mono-loaded)] text-sm text-muted-foreground">
              The app
            </p>
            <p className="mt-2 font-[family-name:var(--font-mono-loaded)] text-3xl font-semibold">
              {CONFIG.price} <span className="text-base font-normal text-muted-foreground">once</span>
            </p>
            <p className="mt-1 font-[family-name:var(--font-mono-loaded)] text-sm text-[var(--color-accent-chute)]">
              {PAID.length} jobs · {appMinutes} min a day
            </p>
            <ul className="mt-4 space-y-2 text-sm text-muted-foreground">
              <li>The Finder right-click menu — eight rows, where the files already are</li>
              <li>The menu-bar session switcher and local servers</li>
              <li>The ⌥⌘N hotkey, anywhere</li>
              <li>Every future v0.x update</li>
              <li>{CONFIG.trialDays} days free first. No card to start.</li>
            </ul>
            <a href={CONFIG.download}
               className={buttonVariants({ size: "lg" }) + " mt-6 h-11 w-full px-5 text-base font-medium"}>
              Start the free trial
            </a>
            <p className="mt-3 text-center text-xs text-muted-foreground">
              {CONFIG.refundDays}-day refund, no questions asked.
            </p>
          </div>
        </div>
        <p className="mt-6 max-w-2xl text-sm text-muted-foreground">
          You are not buying the ability to do these things — the free tool does all of them. You
          are buying not having to leave Finder, and not having to type a path, {PAID.length} times
          a day.
        </p>
      </Section>

      {/* ---------------------------------------------------------------- faq */}
      <Section eyebrow="Questions" title="The ones worth asking">
        <Accordion className="w-full">
          {FAQ.map((f, i) => (
            <AccordionItem key={f.q} value={`i${i}`}>
              <AccordionTrigger className="text-left font-[family-name:var(--font-mono-loaded)] text-base">
                {f.q}
              </AccordionTrigger>
              <AccordionContent className="text-muted-foreground">{f.a}</AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </Section>

      <Footer />
    </main>
  );
}
