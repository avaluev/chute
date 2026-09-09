import Image from "next/image";
import Link from "next/link";
import { buttonVariants } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Accordion, AccordionContent, AccordionItem, AccordionTrigger,
} from "@/components/ui/accordion";
import { CopyLine } from "@/components/copy-line";
import { InstallCli } from "@/components/install-cli";
import { Header, Footer } from "@/components/chrome";
import { MenuLoop } from "@/components/menu-loop";
import { PAID, FAMILIES, inFamily, minutesPerDay } from "@/lib/cases";
import { CONFIG } from "@/lib/config";
import { asset } from "@/lib/asset";

/** JSON for a <script> body. A `</script>` inside any string would end the element early;
 *  escaping `<` is the standard belt for a sink that has no sanitiser. */
const jsonLd = (o: object) => JSON.stringify(o).replace(/</g, "\\u003c");

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
    a: "It can. It cannot see your Finder selection, your clipboard, the terminal you lost, or the port you can\u2019t find \u2014 and it certainly cannot tell you which of your six sessions stopped. Chute is everything the agent cannot reach from inside its own window, including you." },
  { q: "What does it cost?",
    a: "Nothing. The app, the Finder extension and the terminal tool underneath it are all MIT licensed. It was a paid app for eleven days in 2026; the trial clock, the licence check and the store account are deleted, not disabled." },
  { q: "Does it phone home?",
    a: "No. There is no network code at all except the gist command, which uploads only the files you name, only when you run it, and redacts them first. Nothing else in Chute opens a socket. Check it yourself: grep -rn URLSession Sources/" },
  { q: "macOS says it cannot verify the app. Is something wrong?",
    a: "No \u2014 it is unsigned, which is a different thing from unsafe. There is no Apple Developer Program membership behind this project, so a downloaded build meets Gatekeeper. The one-line source install avoids that entirely, because a binary your own compiler produced was never downloaded and never gets a quarantine flag. (Homebrew avoids it too, but that formula installs only the terminal tool \u2014 it gives you neither the menu bar nor the Finder menu.) If you want the .dmg anyway, the release page lists the four clicks." },
  { q: "Which agents does it work with?",
    a: "For moving context: all of them. Chute never talks to an agent; it moves files, paths and text through your clipboard, so Claude Code, Codex, Antigravity, Cursor, Aider or Gemini \u2014 if it reads a prompt, it reads Chute\u2019s output. Watching state is narrower. Chute finds any of those sessions in the process list and shows you that one is running and what it is costing you, but the precise states \u2014 blocked, ready, working \u2014 come from hooks, and the hooks exist for Claude Code today. Another agent\u2019s row says so in words: \u201cno hook \u2014 Chute cannot see this\u201d." },
  { q: "Does it write to my agent\u2019s config?",
    a: (
      <>
        Never. Chute will compute the hook snippet for you and print it, and it will show you the
        merged file it would produce &mdash; but you paste it. Nothing in Chute edits
        ~/.claude/settings.json or anyone else&rsquo;s settings behind your back.
        {/* THE GENERAL TAB IS THE PROOF, not another sentence claiming the same thing. This is
            the one FAQ answer with an image because it is the one claim a screenshot settles
            outright: the tab literally says "Chute never edits ~/.claude/settings.json." */}
        <Image
          src={asset("/media/screens/settings.webp")}
          alt="The Chute General settings tab, showing the hooks explanation and chute doctor"
          width={960} height={640} unoptimized
          className="mt-4 w-full rounded-[var(--radius)] border border-border"
        />
      </>
    ) },
  { q: "Where do these numbers come from?",
    a: "Honestly: they are estimates, not a study. Each is frequency \u00d7 (seconds by hand \u2212 seconds with Chute). The frequency and the by-hand seconds come from one developer\u2019s own workflow as he recalls it. The Chute seconds are a design target the build has to meet \u2014 except for the three jobs that have a screen recording behind them, where a stopwatch read the tape and the recording wins over the estimate. Two more jobs carry no number at all, because inventing one would make the rest less believable. The ledger and its method are in the repository, the site is generated from it, and the build fails if a figure here stops matching it." },
  { q: "Which macOS?",
    a: "macOS 13 Ventura and later, Apple Silicon. The app is under 3.2 MB and the command-line binary under 1 MB, with no dependencies, no launch daemon and no background service. CI tests macOS 15 and 26 on every push." },
];

function Section({ id, eyebrow, title, children }: {
  id?: string; eyebrow: string; title: string; children: React.ReactNode;
}) {
  return (
    <section id={id} className="mx-auto w-full max-w-5xl px-5 py-16 sm:px-6 md:py-24 lg:py-28">
      <p className="font-[family-name:var(--font-mono-loaded)] text-xs font-medium uppercase tracking-[0.14em] text-[var(--color-accent-chute)]">
        {eyebrow}
      </p>
      <h2 className="mt-3 text-xl font-semibold leading-[1.2] tracking-[-0.02em] md:text-3xl">
        {title}
      </h2>
      <div className="mt-10">{children}</div>
    </section>
  );
}

export default function Home() {
  const appMinutes = minutesPerDay(PAID);

  return (
    <main className="min-h-screen">
      {/* SoftwareApplication, and nothing else.
          Thirty minutes of work, not a strategy, and the file this comment defends is the reason:
          Google's FAQ rich results were deprecated 2026-05-07 and HowTo in 2023, Google documents
          that no special schema is needed for its AI features, and the best controlled test found
          the lift was algorithmic rather than schema-driven. Every "schema = 2.5x more citations"
          figure in circulation traces to a vendor blog with no study behind it.
          What this DOES buy is a machine-readable price, platform and rating-free offer for the
          directories that parse it — AlternativeTo, Slant and the like. That is worth half an
          hour. Believing it moves AI citations is not. Price and OS come from CONFIG and the
          version from the changelog's own data, so there is no second place for them to rot. */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: jsonLd({
          "@context": "https://schema.org",
          "@type": "SoftwareApplication",
          name: "Chute",
          applicationCategory: "DeveloperApplication",
          operatingSystem: "macOS 13.0 or later",
          url: `https://${CONFIG.domain}`,
          downloadUrl: CONFIG.download,
          softwareHelp: `https://${CONFIG.domain}/docs/`,
          author: { "@type": "Person", name: "Alexandr Valuev" },
          license: "https://opensource.org/licenses/MIT",
          isAccessibleForFree: true,
          offers: {
            "@type": "Offer",
            price: "0",
            priceCurrency: "USD",
            category: "free",
            url: CONFIG.download,
          },
        }) }}
      />
      <Header />

      {/* ---------------------------------------------------------------- hero */}
      <section className="mx-auto w-full max-w-5xl px-5 pt-16 sm:px-6 md:pt-24">
        {/* FOUR CHIPS, NOT ONE PILL. This was a single Badge holding
            "macOS 13+ · free and MIT · no account · no telemetry" — and shadcn's Badge is
            `whitespace-nowrap shrink-0` by design, because a badge is a one-word label. A
            50-character sentence in it cannot wrap, so on a 390px phone it hung 22px past the
            right edge and was the last thing still forcing a horizontal scrollbar. Four separate
            chips in a wrapping flex row say the same thing, reflow at any width, and read as a
            spec strip rather than one over-long pill. */}
        <div className="flex flex-wrap items-center gap-2">
          {["macOS 13+", "free and MIT", "no account", "no telemetry"].map((t) => (
            <Badge key={t} variant="secondary"
                   className="font-[family-name:var(--font-mono-loaded)] text-xs">
              {t}
            </Badge>
          ))}
        </div>

        {/* THE HERO NOW LEADS WITH SUPERVISION, NOT FINDER, and that is a positioning change
            made on evidence rather than taste.
            The old h1 — "Your agent lives in the terminal / your work lives in Finder / Chute is
            the door between them" — is a better SENTENCE than this one. It sold the file-plumbing
            story, which is where 24 of the 24 costed jobs live. But the ICP was settled on Claude
            Code operators (2026-08-31), and the job that ICP is loudest about is not typing paths:
            it is not knowing which of nine sessions stopped. That job has no entry in the JTBD
            ledger and no minutes attached to it, because it does not buy back seconds — it buys
            back attention, and an agent blocked for twenty minutes is twenty minutes of nothing
            happening at all.
            The evidence it is the sharper pain: in September 2026 a post about screwing a physical
            USB traffic light to a monitor ran away on LinkedIn, and the replies were people asking
            where to buy fifteen of them. Nobody has ever asked that about a path. */}
        <h1 className="mt-6 max-w-3xl text-3xl font-semibold leading-[1.05] tracking-[-0.035em] md:text-5xl">
          Nine terminal tabs.<br />
          Six agents running.<br />
          <span className="text-[var(--color-accent-chute)]">Which one is waiting for you?</span>
        </h1>

        <p className="mt-6 max-w-2xl text-xl text-muted-foreground">
          You stopped being the person writing the code and became the person supervising four of
          them. Chute is the part nobody built for that job: every session in your menu bar with
          what it is doing right now, and the fastest path from a Finder selection to an agent
          that cannot see it.
        </p>

        {/* ONE COMMAND, AND IT HAS TO BE THE ONE THAT INSTALLS THE PRODUCT.
            This block used to lead with `brew install avaluev/tap/chute`. That formula builds
            `--product chute` and installs `bin/chute` — the CLI, and ONLY the CLI. No app
            bundle, no menu bar, no Finder extension. So the page described two surfaces and then
            handed the reader neither of them. Found 2026-09-09 by reading the formula next to the
            hero, and it is a truth problem before it is a conversion one.
            The curl line runs Scripts/get.sh: clone, build, install the app AND register the
            extension. It keeps the property brew was chosen for — the binary is compiled on the
            reader's machine, so it is never downloaded, never quarantined, and Gatekeeper never
            runs. Brew stays on the page, below, described as what it actually is. */}
        <div className="mt-9 max-w-xl">
          <CopyLine text={`curl -fsSL https://${CONFIG.domain}/install.sh | sh`} />
          <p className="mt-3 text-sm text-muted-foreground">
            Both surfaces — the menu bar and the Finder menu. Free and MIT: no account, no licence
            key, no trial. It compiles on your machine, so nothing is downloaded, macOS never
            quarantines it, and Gatekeeper never asks.
          </p>
        </div>

        <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center">
          <a href={CONFIG.download}
             className={buttonVariants({ size: "lg" }) + " h-11 px-5 text-base font-medium"}>
            Or download the app
          </a>
          <span className="text-sm text-muted-foreground">
            Unsigned — macOS will ask. The release page says exactly what to click.
          </span>
        </div>

        {/* Small and secondary on purpose. The free tool is credibility and a way out for the
            sceptic, not the offer — the page that led with it sold the free thing.
            It does NOT print the brew command: the tap does not exist yet, and the reader most
            likely to paste it is the one deciding whether to trust a stranger's $19 utility. */}
        <p className="mt-6 text-sm text-muted-foreground">
          Driving an agent already? Paste this at it:{" "}
          <code className="rounded bg-card px-1.5 py-0.5 text-foreground">
            Set up Chute for me — {CONFIG.repo}
          </code>
        </p>

        {/* The hero shot is the APP, not a terminal. The old one was a terminal GIF on a page
            asking for $19 for something the visitor had never seen.
            THIS IS THE ONE ILLUSTRATED IMAGE ON THE SITE — every other screenshot and recording
            is real captured output (see case-bits.tsx). A live cycle through three states in one
            still screenshot is not possible, so this is a stylised, programmatic replay of the
            real dot language instead: same shapes, same colours, same strings, built in CSS with
            no video and no GIF. It says so itself, for a screen reader, in menu-loop.tsx. The
            static screenshot this replaced still lives at /media/screens/menu.png and still backs
            the /cases/which-agent-is-waiting-for-you page, so nothing here can drift from what
            the app actually draws without that case's own build-time check catching it. */}
        <div className="mt-16">
          <MenuLoop />
        </div>

        {/* THE TWO FACTS THE ANIMATION CANNOT SAY FOR ITSELF, added the day the redesign it
            shows shipped (2026-09-08). Watching the loop proves the shapes and the states; it
            cannot prove where the project name came from or that the dot is deliberate rather
            than decorative — so the caption says both, next to the thing it describes rather than
            buried in a Trust section about file safety, which this is not. */}
        <p className="mt-4 max-w-2xl text-sm text-muted-foreground">
          A solid square wants something from you: red is blocked, green is ready. A hollow square
          is motion &mdash; orange working, grey where Chute cannot see the session at all. A small
          square is a shell with no agent in it. Size means that one thing and nothing else; fill
          does the work colour cannot, because unknown and idle are both grey. And the row spells
          the state out in words beside the dot, because roughly one man in twelve cannot tell
          that red from that green &mdash; &ldquo;blocked 3 min&rdquo; reads the same to everyone.
        </p>
        <p className="mt-2 max-w-2xl text-sm text-muted-foreground">
          The project name comes from the session&rsquo;s own git root — asked of the kernel, not
          read off a terminal window title you can rename by accident. Where the kernel cannot
          resolve the directory at all, the title is the last resort rather than the first guess.
          Either way the path it was derived from prints underneath it, so a wrong guess is
          visible instead of silent.
        </p>

        {/* THE SECOND SURFACE, WHICH HAD NO IMAGE ANYWHERE — not on this site, not in the
            README, not in the repo — until 2026-09-09. Half the product, never once shown.
            macOS will not let anything screenshot another application's OPEN context menu, so
            this is DRAWN: Scripts/finder-shot.swift renders it from
            Sources/ChuteCore/FinderActions.swift — the same table the extension builds the real
            menu from, so the picture cannot drift from the menu without the render changing too.
            `chute finder-actions --menu` prints the same list for anyone who wants to diff it.
            The alt text says it is a rendering, because it is. */}
        <div className="mt-16 flex flex-col gap-8 md:flex-row md:items-center">
          <Image
            src={asset("/media/screens/finder-menu.webp")}
            alt="A rendering of Chute's rows inside the Finder right-click menu: Copy Full Paths, Copy Files as Context, Copy Folder Tree, Add to Context Basket, and New File"
            width={430} height={284} unoptimized
            className="shrink-0 rounded-[var(--radius)] border border-border"
          />
          <div className="space-y-3 text-sm text-muted-foreground">
            <p className="text-base font-medium text-foreground">The other half is in Finder.</p>
            <p>
              Right-click a selection and the rows sit inline in the menu you already opened —
              no <span className="whitespace-nowrap">Chute ▸</span> submenu to go through first.
              Select a folder, pick <em>Copy Files as Context</em>, and every file inside it is on
              your clipboard as one blob with a token count, ready to paste.
            </p>
            <p>
              Drawn from the same table the extension builds the real menu from, so it cannot
              show you a row the app does not have.
            </p>
          </div>
        </div>
      </section>

      {/* ---------------------------------------------------------------- the critical event */}
      {/* WHY NOW, and it is not a feature. The reader already lives this; naming it is what makes
          the rest of the page feel like it was written by someone who does too. */}
      <Section eyebrow="Why this exists now" title="Agents got autonomous. Supervising them did not.">
        <div className="grid grid-cols-1 gap-10 md:grid-cols-2">
          <div className="space-y-4 text-muted-foreground">
            <p>
              Software used to need you in the chair. Now you give it a job and walk off — and the
              only thing standing between you and a finished task is whether you happened to look
              at the right tab.
            </p>
            <p>
              In September 2026 a developer bolted a physical USB traffic light to their monitor so
              they could see, from across the room, whether Claude Code was waiting on them. The
              replies were not jokes. They were people asking where to buy fifteen.
            </p>
            <p className="text-foreground">
              The bottleneck stopped being how fast the model works. It is how fast you notice it
              stopped.
            </p>
          </div>
          <div className="rounded-[var(--radius)] border border-border bg-card p-8">
            <p className="font-[family-name:var(--font-mono-loaded)] text-xs font-medium uppercase tracking-[0.14em] text-[var(--color-accent-chute)]">
              What it costs
            </p>
            <p className="mt-4 font-[family-name:var(--font-mono-loaded)] text-3xl font-semibold tracking-[-0.02em]">
              {appMinutes} min
            </p>
            <p className="mt-1 text-sm text-muted-foreground">
              a day, thirty seconds at a time, across the Finder menu and the menu bar
            </p>
            <div className="mt-6 border-t border-border pt-6">
              <p className="text-sm text-muted-foreground">
                And that is only the part anyone put a number on. An agent blocked on a permission
                prompt for twenty minutes costs twenty minutes in which nothing happened at all —
                no figure on this page counts that, because we cannot measure it honestly.
              </p>
            </div>
          </div>
        </div>
      </Section>

      {/* ---------------------------------------------------------------- the loop */}
      {/* THE JOBS, GROUPED BY THE LOOP RATHER THAN BY A DEAD PRICE. This section replaced two:
          "what it costs you" (the six app jobs) and "and all of this is free" (the thirteen CLI
          ones). That split was the pricing boundary, not a product boundary, and it survived the
          price by three weeks. Nobody supervising six agents cares which half of a withdrawn
          business model a job used to belong to. */}
      <Section eyebrow="What it does" title="The loop you are already running">
        <p className="-mt-4 max-w-2xl text-muted-foreground">
          Brief it, steer it, watch it, land what it made — that is the loop, and everything
          below sits in one part of it.
        </p>

        <div className="mt-12 space-y-14">
          {FAMILIES.map((f) => {
            const jobs = inFamily(f.key);
            return (
              <div key={f.key}>
                <div className="border-b border-border pb-4">
                  <h3 className="text-xl font-medium tracking-[-0.01em]">
                    {f.title}
                  </h3>
                </div>
                <p className="mt-4 max-w-2xl text-muted-foreground">{f.blurb}</p>
                <ul className="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-2">
                  {jobs.map((c) => (
                    <li key={c.slug}>
                      <Link href={`/cases/${c.slug}`}
                            className="group flex h-full flex-col justify-between gap-3 rounded-[var(--radius)] border border-border bg-card p-5 transition-colors hover:border-[var(--color-accent-chute)]">
                        <p className="text-base leading-snug text-foreground">{c.pain}</p>
                        <p className="font-[family-name:var(--font-mono-loaded)] text-xs text-muted-foreground">
                          {c.savedMinutes ? `${c.savedMinutes} min a day` : "attention, not seconds"}
                          <span className="text-[var(--color-accent-chute)] opacity-0 transition-opacity group-hover:opacity-100"> →</span>
                        </p>
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            );
          })}
        </div>
      </Section>

      {/* ---------------------------------------------------------------- trust */}
      <Section eyebrow="Trust" title="Built for a repo an agent is about to rampage through">
        <ul className="grid grid-cols-1 gap-4 md:grid-cols-2">
          {[
            ["The Finder menu cannot destroy anything", "Every row it offers reads, copies or adds. Nothing in it writes over your files, moves them or deletes them — the two commands that once could were removed in August rather than made safer."],
            ["Snapshots cannot lose work", "checkpoint stages into a private index file. Your index, worktree and HEAD are never touched — it only ever adds a branch."],
            ["Keys are read from the Keychain only", "It prints key names, never values, and refuses to create a .env that git would track."],
            ["There is no network code in Chute at all", "Not \u201cnothing is uploaded\u201d \u2014 one command, gist, does upload, and it does it by shelling out to your own gh with your own credentials, on the files you name, after redacting keys. Chute itself never opens a socket. Check it: grep -rn URLSession Sources/"],
          ].map(([h, b]) => (
            <li key={h} className="rounded-[var(--radius)] border border-border bg-card p-5">
              <p className="text-sm font-semibold">{h}</p>
              <p className="mt-2 text-sm text-muted-foreground">{b}</p>
            </li>
          ))}
        </ul>
      </Section>

      {/* ---------------------------------------------------------------- install */}
      {/* THIS USED TO BE A PRICING TABLE: Free CLI on the left, $19 app on the right, a 14-day
          trial and a 30-day refund. All of it is gone. Chute is MIT, every part of it, and the
          only question left on this page is which install suits the reader — which is a much
          easier question to answer honestly than "why is this worth nineteen dollars". */}
      <Section id="install" eyebrow="Install" title="Free, MIT, and four ways in">
        <p className="-mt-4 max-w-2xl text-muted-foreground">
          There is no licence key, no trial clock and no account. There is also no Apple
          Developer ID behind this project — so the install that compiles on your own machine is
          not the awkward option here, it is the good one.
        </p>

        <div className="mt-10 grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div className="rounded-[var(--radius)] border border-[var(--color-accent-chute)] bg-card p-6">
            <p className="text-sm font-medium text-[var(--color-accent-chute)]">
              One line — the whole app
            </p>
            <div className="mt-4">
              <CopyLine text={`curl -fsSL https://${CONFIG.domain}/install.sh | sh`} />
            </div>
            <p className="mt-4 text-sm text-muted-foreground">
              Clones, builds and installs the app, then registers the Finder extension. Nothing is
              downloaded, so nothing is quarantined and Gatekeeper never runs. It is forty lines
              and{" "}
              <a className="text-foreground underline underline-offset-4"
                 href={`https://${CONFIG.domain}/install.sh`}>you can read it first</a>{" "}
              — piping a stranger&rsquo;s script into a shell deserves that much.
            </p>
          </div>

          <div className="rounded-[var(--radius)] border border-border bg-card p-6">
            <p className="text-sm font-medium text-muted-foreground">
              Let your agent do it
            </p>
            <div className="mt-4">
              <CopyLine text={`Set up Chute for me — ${CONFIG.repo}`} />
            </div>
            <p className="mt-4 text-sm text-muted-foreground">
              Paste that at Claude Code, Codex or whatever you already have open. The repository
              carries the instructions an agent needs to install it and wire the hooks up, and it
              will ask you before it touches anything of yours.
            </p>
          </div>

          <div className="rounded-[var(--radius)] border border-border bg-card p-6">
            <p className="text-sm font-medium text-muted-foreground">
              The disk image
            </p>
            <a href={CONFIG.download}
               className={buttonVariants({ variant: "outline" }) + " mt-4 w-full"}>
              Download .dmg
            </a>
            <p className="mt-4 text-sm text-muted-foreground">
              Unsigned and unnotarized. macOS will say it cannot verify the app, and will offer
              you <em>Done</em> and <em>Move to Trash</em> — neither of which opens it. The
              release page walks the four steps that do. Ships with a SHA-256 to check.
            </p>
          </div>

          {/* LAST, AND LABELLED. The formula installs bin/chute and nothing else — this card used
              to be first and said "recommended", which sent the reader who wanted the menu bar to
              the one install that does not contain it. */}
          <div className="rounded-[var(--radius)] border border-border bg-card p-6">
            <p className="text-sm font-medium text-muted-foreground">
              Homebrew — the terminal tool only
            </p>
            <div className="mt-4"><InstallCli /></div>
            <p className="mt-4 text-sm text-muted-foreground">
              This installs the free command-line tool and <strong>not</strong> the app: no menu
              bar, no Finder menu. Take it if the terminal is where you want to live, or to read
              the engine before you install anything with a window.
            </p>
          </div>
        </div>

        <p className="mt-8 max-w-2xl text-sm text-muted-foreground">
          Why so blunt about Gatekeeper? Because the alternative is a reader who downloads it,
          hits a dialog nobody warned them about, and concludes the thing is broken. It is not
          broken. It is unsigned, which is a different sentence, and the two installs above walk
          straight past it.
        </p>
      </Section>

      {/* ---------------------------------------------------------------- connect */}
      {/* A FREE PROJECT'S CURRENCY IS THE PERSON BEHIND IT. There is no company here and no
          support tier, so the honest thing to publish is where a human actually answers.
          A Telegram HANDLE, never a phone number: a handle can be abandoned, a number cannot be
          un-scraped once a bot has it. */}
      <Section eyebrow="Open source" title="It is all on GitHub, and so am I">
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          <div>
            <p className="max-w-xl text-muted-foreground">
              Chute is MIT licensed, every line of it — the app, the Finder extension and the CLI.
              Read it, fork it, take the bits you want. Issues and pull requests are welcome, and
              there is no contributor agreement to sign.
            </p>
            <div className="mt-6 flex flex-wrap gap-3">
              <a href={CONFIG.repo}
                 className={buttonVariants({ size: "lg" }) + " h-11 px-5 text-base font-medium"}>
                View the source
              </a>
              <a href={`${CONFIG.repo}/issues`}
                 className={buttonVariants({ variant: "outline", size: "lg" }) + " h-11 px-5 text-base"}>
                Report a problem
              </a>
            </div>
          </div>

          <ul className="grid gap-3 self-start">
            {[
              ["GitHub", "@avaluev", CONFIG.social.github],
              ["LinkedIn", "in/valuev", CONFIG.social.linkedin],
              ["Telegram", "@asnkt", CONFIG.social.telegram],
              ["Email", CONFIG.contact, `mailto:${CONFIG.contact}`],
            ].map(([label, handle, href]) => (
              <li key={label}>
                <a href={href}
                   className="flex items-center justify-between gap-4 rounded-[var(--radius)] border border-border bg-card px-5 py-4 transition-colors hover:border-[var(--color-accent-chute)]">
                  <span className="text-sm font-semibold">
                    {label}
                  </span>
                  <span className="truncate font-[family-name:var(--font-mono-loaded)] text-sm text-muted-foreground">
                    {handle}
                  </span>
                </a>
              </li>
            ))}
          </ul>
        </div>

        {/* THE SAME FOUR ROWS, IN THE APP ITSELF. Not decoration — the About tab added
            2026-09-08 carries this section's exact content: why Chute exists in the founder's
            own words, then these same three links, then one honest ask for a star. A screenshot
            of it is the section's own claim, checkable from Settings → About. */}
        <div className="mt-8">
          <Image
            src={asset("/media/screens/about.webp")}
            alt="The Chute About tab: why it exists, GitHub, LinkedIn, Telegram, and a star button"
            width={960} height={640} unoptimized
            className="w-full rounded-[var(--radius)] border border-border"
          />
          <p className="mt-3 text-sm text-muted-foreground">
            The same tab is in the app — Chute menu bar → Settings → About.
          </p>
        </div>
      </Section>

      {/* ---------------------------------------------------------------- faq */}
      <Section eyebrow="Questions" title="The ones worth asking">
        <Accordion className="w-full">
          {FAQ.map((f, i) => (
            <AccordionItem key={f.q} value={`i${i}`}>
              <AccordionTrigger className="text-left text-base">
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
