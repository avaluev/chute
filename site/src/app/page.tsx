import Image from "next/image";
import { buttonVariants } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import {
  Accordion, AccordionContent, AccordionItem, AccordionTrigger,
} from "@/components/ui/accordion";
import { CopyLine } from "@/components/copy-line";
import { asset } from "@/lib/asset";
import { Header, Footer } from "@/components/chrome";

const BREW = "brew install avaluev/tap/chute";
const DOWNLOAD = "https://github.com/avaluev/chute/releases/latest";

/** Numbers are from docs/03-JTBD-LEDGER.md. Every claim on this page is a measurement or a
 *  mechanism — the voice rule in marketing/01-POSITIONING.md is numbers over adjectives. */
const TAX = [
  { times: "25–40×", a: "a day you copy file paths into a prompt",
    b: "20 seconds each, plus the escaping mistakes", fix: "chute paths" },
  { times: "15–20×", a: "a day you hand-bundle several files into one prompt",
    b: "two minutes of tab-hopping", fix: "chute bundle" },
  { times: "10–20×", a: "a day you unpack a multi-file answer back onto disk",
    b: "two minutes of copy-paste", fix: "chute unpack" },
];

const FAQ = [
  { q: "Claude Code can already read my files. Why do I need this?",
    a: "It can. It cannot see your Finder selection, your clipboard, the terminal you lost, or the port you can’t find. Chute is everything the agent can’t reach from inside its own window." },
  { q: "Does it phone home?",
    a: "No. There is no network code at all except the gist command, which uploads only the files you name, only when you run it, and redacts them first. The licence check is an offline signature — Chute never contacts a server to verify it." },
  { q: "What happens when the 14-day trial ends?",
    a: "The app locks: the Finder menu and the menu-bar switcher stop until you enter a key. The chute command-line tool keeps working forever, because it is free and MIT licensed." },
  { q: "Is the CLI really free?",
    a: "Yes, all 28 commands, MIT, on Homebrew. The $19 buys the app: the Finder right-click menu, the menu-bar session switcher and the hotkey — a signed, sandboxed Finder extension is the part you cannot reasonably build yourself." },
  { q: "Which agents does it work with?",
    a: "All of them. Chute never talks to an agent; it moves files, paths and text through your clipboard. Claude Code, Codex, Cursor, Aider, Gemini — if it reads a prompt, it reads Chute’s output." },
  { q: "Which macOS?",
    a: "macOS 13 Ventura and later, Apple Silicon and Intel. One binary, 328 KB, no dependencies, no launch daemon." },
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

function Shot({ src, alt, caption }: { src: string; alt: string; caption: string }) {
  return (
    <figure>
      <div className="overflow-hidden rounded-[var(--radius)] border border-border bg-ground-900">
        <Image src={src} alt={alt} width={1200} height={640} unoptimized
               className="w-full" />
      </div>
      <figcaption className="mt-3 text-sm text-muted-foreground">{caption}</figcaption>
    </figure>
  );
}

export default function Home() {
  return (
    <main className="min-h-screen">
      {/* ---------------------------------------------------------------- hero */}
      <Header />

      <section className="mx-auto w-full max-w-5xl px-6 pt-16 md:pt-24">
        <Badge variant="secondary" className="font-[family-name:var(--font-mono-loaded)] text-xs">
          macOS 13+ · 328 KB · no account
        </Badge>

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
          <a href={DOWNLOAD} className={buttonVariants({ size: "lg" }) + " h-11 px-5 text-base font-medium"}>
            Download for macOS — free 14-day trial
          </a>
          <span className="text-sm text-muted-foreground">
            $19 once after that. No subscription, no account.
          </span>
        </div>

        <div className="mt-6 max-w-md">
          <p className="mb-2 text-sm text-muted-foreground">Or just take the free command-line tool:</p>
          <CopyLine text={BREW} />
        </div>

        <div className="mt-16 overflow-hidden rounded-[var(--radius)] border border-border shadow-hero">
          <Image src={asset("/media/bundle.gif")} alt="chute bundle copying four files and their contents to the clipboard with a token count"
                 width={1200} height={720} unoptimized priority className="w-full" />
        </div>
      </section>

      {/* ---------------------------------------------------------------- the tax */}
      <Section eyebrow="The tax" title="Ninety minutes a day, thirty seconds at a time">
        <div className="grid gap-5 md:grid-cols-3">
          {TAX.map((t) => (
            <div key={t.fix} className="rounded-[var(--radius)] border border-border bg-card p-6">
              <p className="font-[family-name:var(--font-mono-loaded)] text-2xl font-semibold text-[var(--color-accent-chute)]">
                {t.times}
              </p>
              <p className="mt-3 text-sm text-foreground">{t.a}</p>
              <p className="mt-2 text-sm text-muted-foreground">{t.b}</p>
              <Separator className="my-4" />
              <code className="font-[family-name:var(--font-mono-loaded)] text-sm text-foreground">{t.fix}</code>
            </div>
          ))}
        </div>
      </Section>

      {/* ---------------------------------------------------------------- act 1 */}
      <Section eyebrow="Act one" title="Context in, artifacts out">
        <div className="grid gap-10 md:grid-cols-2">
          <Shot src={asset("/media/bundle.gif")} alt="chute bundle"
                caption="Eight files and everything in them, one blob, with the token count — before you paste, not after." />
          <Shot src={asset("/media/unpack.gif")} alt="chute unpack"
                caption="The other direction: a markdown answer becomes a real file tree. It previews first, and refuses to write outside the folder you aimed it at." />
        </div>
      </Section>

      {/* ---------------------------------------------------------------- act 2 */}
      <Section eyebrow="Act two" title="Which agent is waiting for you">
        <div className="grid gap-10 md:grid-cols-2">
          <div>
            <p className="text-muted-foreground">
              Nine terminal windows, five running an agent, and no way to tell which one hit a
              permission prompt four minutes ago. The menu bar carries the count, groups sessions
              by what you must do about them, and colours each one by project.
            </p>
            <p className="mt-4 text-muted-foreground">
              Click a row and that terminal comes forward. It also lists every local server, so you
              never again hunt for which window holds port 3000.
            </p>
          </div>
          <Shot src={asset("/media/sessions.gif")} alt="chute sessions"
                caption="Grouped by state: waiting for you, working, idle." />
        </div>
      </Section>

      {/* ---------------------------------------------------------------- trust */}
      <Section eyebrow="Trust" title="Built for a repo an agent is about to rampage through">
        <ul className="grid gap-4 md:grid-cols-2">
          {[
            ["unpack and clean preview by default", "Nothing is written or deleted without --force."],
            ["unpack cannot escape its target folder", "Absolute paths and ../ are rejected outright."],
            ["checkpoint cannot lose work", "It stages into a private index file. Your index, worktree and HEAD are never touched — it only ever adds a branch."],
            ["clean moves to the Trash", "Never rm."],
            ["env inject reads the Keychain only", "It prints key names, never values, and refuses to create a .env that git would track."],
            ["Nothing is uploaded, ever", "One exception: the gist command, when you explicitly run it, on the files you name, redacted first."],
          ].map(([h, b]) => (
            <li key={h} className="rounded-[var(--radius)] border border-border bg-card p-5">
              <p className="font-[family-name:var(--font-mono-loaded)] text-sm font-semibold">{h}</p>
              <p className="mt-2 text-sm text-muted-foreground">{b}</p>
            </li>
          ))}
        </ul>
      </Section>

      {/* ---------------------------------------------------------------- pricing */}
      <Section id="pricing" eyebrow="Price" title="One payment, or nothing at all">
        <div className="grid gap-5 md:grid-cols-2">
          <div className="rounded-[var(--radius)] border border-border bg-card p-8">
            <p className="font-[family-name:var(--font-mono-loaded)] text-sm text-muted-foreground">The command line</p>
            <p className="mt-2 font-[family-name:var(--font-mono-loaded)] text-3xl font-semibold">Free</p>
            <p className="mt-4 text-sm text-muted-foreground">
              All 28 commands. MIT licensed, source on GitHub, yours forever whatever happens to me
              or to this page.
            </p>
            <div className="mt-6"><CopyLine text={BREW} /></div>
          </div>

          <div className="rounded-[var(--radius)] border border-[var(--color-accent-chute)] bg-card p-8">
            <p className="font-[family-name:var(--font-mono-loaded)] text-sm text-muted-foreground">The app</p>
            <p className="mt-2 font-[family-name:var(--font-mono-loaded)] text-3xl font-semibold">
              $19 <span className="text-base font-normal text-muted-foreground">once</span>
            </p>
            <ul className="mt-4 space-y-2 text-sm text-muted-foreground">
              <li>The Finder right-click menu</li>
              <li>The menu-bar session switcher and local servers</li>
              <li>The ⌥⌘N hotkey, anywhere</li>
              <li>Every future v0.x update</li>
              <li>14 days free first. No card to start.</li>
            </ul>
            <a href={DOWNLOAD}
               className={buttonVariants({ size: "lg" }) + " mt-6 h-11 w-full px-5 text-base font-medium"}>
              Start the free trial
            </a>
            <p className="mt-3 text-center text-xs text-muted-foreground">
              30-day refund, no questions asked.
            </p>
          </div>
        </div>
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
