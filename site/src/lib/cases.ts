/**
 * The 25 jobs Chute does, as data.
 *
 * ONE source. The landing sections, /cases, every /cases/<slug> page and the paid-vs-free
 * columns are all generated from this array, so a case cannot appear on the index without
 * having a page, and a number cannot appear on the page without being in the ledger.
 *
 * Every `savedMinutes` here is checked against docs/03-JTBD-LEDGER.md by
 * `site/scripts/check-cases.mjs`, which runs before the site deploys. Do not edit a number
 * here to make a page read better — edit the ledger, or leave it alone.
 *
 * TWO INDEPENDENT AXES, easily confused:
 *   · `paid`  — which column it lands in. True = you need Chute.app. This split IS the sales
 *               argument, so it is visible on the page rather than implied.
 *   · `tier`  — how much production the demo gets. "hero" = a real Finder/menu-bar recording,
 *               10–15 s. "short" = a ≤6 s terminal capture. A free job can still be a hero and
 *               a paid one can still be a short; conflating the two is how a page ends up
 *               arguing that the expensive video is the expensive feature.
 */
export interface Case {
  slug: string
  /** Row in docs/03-JTBD-LEDGER.md. 0 = not in the ledger (see `savedMinutes: null`). */
  jtbd: number
  surface: "finder" | "menubar" | "cli"
  tier: "hero" | "short"
  /** True = Chute.app. False = the free MIT CLI, which never expires. */
  paid: boolean
  /** The moment, in the reader's words. Never a command name, never a feature. */
  pain: string
  /** What they do about it today. */
  ritual: string
  /** What happens instead. */
  fix: string
  /** Seconds per occurrence, from the ledger. */
  seconds: { manual: number; chute: number }
  /** Times a day, from the ledger. */
  perDay: number
  /**
   * Minutes a day, from the ledger. NULL where the honest answer is not a number — a page with
   * one admitted gap is more credible than one where all 25 figures look alike.
   */
  savedMinutes: number | null
  /** Under site/public. Undefined until it has been recorded and verified — see demo/verify.sh. */
  demo?: string
  poster?: string
  /** The free CLI equivalent. Every paid case has one; that is the point of the free CLI. */
  command: string
}

export const CASES: Case[] = [
  // ─── The app ────────────────────────────────────────────────────────────────────────────
  {
    slug: "paste-a-whole-folder-into-your-agent",
    jtbd: 2, surface: "finder", tier: "hero", paid: true,
    pain: "I need to give it this whole folder and I'm feeding it one file at a time.",
    ritual: "Open each file, select all, copy, switch to the agent, paste, type the filename above it, go back for the next one.",
    fix: "Select the folders in Finder, right-click once, and every file inside them is on the clipboard as one blob with a token count.",
    seconds: { manual: 150, chute: 5 }, perDay: 17, savedMinutes: 41.1,
    demo: "/media/paste-a-whole-folder-into-your-agent.mp4",
    poster: "/media/paste-a-whole-folder-into-your-agent.jpg",
    command: "chute bundle src/ --format xml",
  },
  {
    slug: "which-agent-is-waiting-for-you",
    jtbd: 0, surface: "menubar", tier: "hero", paid: true,
    pain: "Nine terminals. One of them stopped four minutes ago and I don't know which.",
    ritual: "Cycle every window looking for a prompt that is waiting on a keystroke you never saw.",
    fix: "The menu bar carries the count, groups sessions by what you have to do about them, and colours each one by project. Click a row and that terminal comes forward.",
    seconds: { manual: 0, chute: 0 }, perDay: 0,
    // Deliberately no figure. This one buys back attention, not seconds, and inventing a number
    // for it would make the other twenty-four less believable, not this one more so.
    savedMinutes: null,
    demo: "/media/which-agent-is-waiting-for-you.mp4",
    poster: "/media/which-agent-is-waiting-for-you.jpg",
    command: "chute sessions",
  },
  {
    slug: "clipboard-straight-into-a-file",
    jtbd: 3, surface: "finder", tier: "hero", paid: true,
    pain: "Command-N, Command-V, Command-S, find the folder, type a name. Twenty-five times a day.",
    ritual: "A new editor tab, a paste, a save dialog, and a filename you invent on the spot.",
    fix: "Right-click where it belongs. The file is named from its own first heading and its extension comes from the code inside it.",
    seconds: { manual: 35, chute: 4 }, perDay: 25, savedMinutes: 12.9,
    demo: "/media/clipboard-straight-into-a-file.mp4",
    poster: "/media/clipboard-straight-into-a-file.jpg",
    command: "chute new",
  },
  {
    slug: "stop-typing-file-paths",
    jtbd: 1, surface: "finder", tier: "hero", paid: true,
    pain: "Option-right-click, Copy as Pathname, fix the quoting, repeat. Thirty-two times a day.",
    ritual: "One path at a time, and the one with a space in it breaks the command you paste it into.",
    fix: "Select any number of files, right-click once, and every path is on the clipboard, escaped correctly.",
    seconds: { manual: 20, chute: 3 }, perDay: 32, savedMinutes: 9.1,
    demo: "/media/stop-typing-file-paths.mp4",
    poster: "/media/stop-typing-file-paths.jpg",
    command: "chute paths src/*.ts",
  },
  {
    slug: "whats-on-port-3000",
    jtbd: 15, surface: "menubar", tier: "hero", paid: true,
    pain: "Something is on 3000 and I cannot find which window it is in.",
    ritual: "lsof, read the PID, guess which project it belongs to, kill it, hope it was the right one.",
    fix: "The menu bar lists every local server with the process and the project it belongs to. One click stops it.",
    seconds: { manual: 30, chute: 3 }, perDay: 11, savedMinutes: 4.9,
    demo: "/media/whats-on-port-3000.mp4",
    poster: "/media/whats-on-port-3000.jpg",
    command: "chute ports --kill 3000",
  },
  {
    slug: "the-shape-of-a-folder",
    jtbd: 5, surface: "finder", tier: "short", paid: true,
    pain: "It keeps asking where things are because it cannot see the project.",
    ritual: "Type out the structure by hand, or paste a tree with node_modules in it and burn the context on nothing.",
    fix: "Right-click, pick a depth, and the skeleton is on the clipboard with the build and dependency folders left out.",
    seconds: { manual: 30, chute: 3 }, perDay: 10, savedMinutes: 4.5,
    demo: "/media/tree.gif",
    command: "chute tree . --depth 4",
  },

  // ─── And all of this is free ────────────────────────────────────────────────────────────
  {
    slug: "break-a-big-task-into-steps",
    jtbd: 17, surface: "cli", tier: "short", paid: false,
    pain: "I hand it the whole feature and get back something that does four things badly.",
    ritual: "Write the decomposition prompt again from memory, slightly differently every time.",
    fix: "One command puts the decomposition prompt on your clipboard, the same way every time.",
    seconds: { manual: 120, chute: 3 }, perDay: 8, savedMinutes: 15.6,
    demo: "/media/break-a-big-task-into-steps.gif",
    command: "chute prompt decompose",
  },
  {
    slug: "keys-into-a-dotenv-without-pasting-them",
    jtbd: 14, surface: "cli", tier: "short", paid: false,
    pain: "The key is in my Keychain and it is about to be in my shell history.",
    ritual: "Open Keychain Access, reveal, copy, paste into .env, hope .env is gitignored.",
    fix: "It reads the Keychain and writes the .env — and refuses outright if that .env is not already ignored by git.",
    seconds: { manual: 120, chute: 5 }, perDay: 7, savedMinutes: 13.4,
    command: "chute env inject --keys OPENAI_API_KEY",
  },
  {
    slug: "stop-it-writing-a-framework",
    jtbd: 18, surface: "cli", tier: "short", paid: false,
    pain: "I asked for a function and got a factory, an interface and a config file.",
    ritual: "Explain again, in your own words, that you wanted the small version.",
    fix: "The anti-bloat prompt, on the clipboard, worded the same way every time.",
    seconds: { manual: 60, chute: 3 }, perDay: 10, savedMinutes: 9.5,
    demo: "/media/stop-it-writing-a-framework.gif",
    command: "chute prompt ponytail",
  },
  {
    slug: "where-you-left-off",
    jtbd: 16, surface: "cli", tier: "short", paid: false,
    pain: "I come back after lunch and reconstruct what I was in the middle of.",
    ritual: "Read your own diff and guess.",
    fix: "One line, timestamped, appended to a SCRATCHPAD.md the agent can read too.",
    seconds: { manual: 40, chute: 5 }, perDay: 15, savedMinutes: 8.8,
    demo: "/media/where-you-left-off.gif",
    command: 'chute note "waiting on the migration"',
  },
  {
    // MOVED cli → finder 2026-08-31. It was a CLI-only job until `Add to Context Basket` became a
    // Finder row that day; the primary way to do it is now a right-click, and the Finder menu is
    // the paid surface. Left as `cli`/free it would have been counted in the free tier while the
    // row it describes sat in the paid one — the value split is what the pricing page is built on.
    slug: "collect-files-over-several-copies",
    jtbd: 22, surface: "finder", tier: "short", paid: true,
    pain: "The files I need are in four different folders and the clipboard holds one thing.",
    ritual: "Paste each one into a scratch document as you go, then copy the whole document.",
    fix: "Right-click each one as you find it. The menu bar holds them, and hands them over as @mentions your agent reads itself — or as the files themselves, with a token count.",
    seconds: { manual: 45, chute: 4 }, perDay: 12, savedMinutes: 8.2,
    command: "chute basket add",
  },
  {
    slug: "what-did-the-agent-actually-change",
    jtbd: 11, surface: "cli", tier: "short", paid: false,
    pain: "It says it is done. I have no idea what it touched.",
    ritual: "git diff, scroll, lose your place, scroll back.",
    fix: "The whole diff on the clipboard, ready to paste back and ask about.",
    seconds: { manual: 25, chute: 4 }, perDay: 14, savedMinutes: 4.9,
    demo: "/media/diff.gif",
    command: "chute diff --copy",
  },
  {
    slug: "five-agents-one-command",
    jtbd: 21, surface: "cli", tier: "short", paid: false,
    pain: "The same change has to go into six repos and I am opening six terminals.",
    ritual: "cd, start the agent, paste the prompt. Six times, and by the fourth you have changed the wording.",
    fix: "Name the folders once and every one of them gets its own terminal with the agent already running.",
    seconds: { manual: 60, chute: 5 }, perDay: 6, savedMinutes: 5.5,
    command: "chute sandbox --each repo-a repo-b repo-c",
  },
  {
    slug: "paste-without-pasting-your-keys",
    jtbd: 19, surface: "cli", tier: "short", paid: false,
    pain: "I want to share this log but I have not read every line of it.",
    ritual: "Skim for anything that looks like a token, and find out later that you missed one.",
    fix: "Keys and tokens are masked before the text ever reaches your clipboard.",
    seconds: { manual: 90, chute: 3 }, perDay: 4, savedMinutes: 5.8,
    demo: "/media/redact.gif",
    command: "chute redact server.log",
  },
  {
    slug: "find-the-file-it-just-wrote",
    jtbd: 10, surface: "cli", tier: "short", paid: false,
    pain: "It says it wrote the file. Where.",
    ritual: "Sort by date modified and hope you are in the right folder.",
    fix: "The newest thing in the folder, revealed — or previewed without opening anything.",
    seconds: { manual: 15, chute: 2 }, perDay: 20, savedMinutes: 4.3,
    demo: "/media/find-the-file-it-just-wrote.gif",
    command: "chute latest",
  },
  {
    slug: "an-image-as-one-line-of-text",
    jtbd: 23, surface: "cli", tier: "short", paid: false,
    pain: "The agent cannot see the screenshot I am describing to it.",
    ritual: "Upload it somewhere, wait, copy the link, hope the link outlives the conversation.",
    fix: "The image as a data URL on the clipboard, ready to paste into the message.",
    seconds: { manual: 25, chute: 2 }, perDay: 7, savedMinutes: 2.7,
    command: "chute dataurl shot.png --markdown",
  },
  {
    slug: "share-a-file-without-a-repo",
    jtbd: 20, surface: "cli", tier: "short", paid: false,
    pain: "Someone needs to see this one file and it does not belong in a commit.",
    ritual: "Open the browser, new gist, paste, set it secret, copy the URL.",
    fix: "A secret gist and its URL on your clipboard — with the keys masked before anything leaves the machine.",
    seconds: { manual: 60, chute: 4 }, perDay: 3, savedMinutes: 2.8,
    command: "chute gist server.log",
  },
  {
    slug: "the-extension-you-didnt-type",
    jtbd: 4, surface: "cli", tier: "short", paid: false,
    pain: "I saved it as .txt again.",
    ritual: "Rename it once you notice the syntax highlighting is missing.",
    fix: "The extension comes from the code in the file, not from what you remembered to type.",
    seconds: { manual: 10, chute: 0 }, perDay: 12, savedMinutes: 2.0,
    demo: "/media/new.gif",
    command: "chute new",
  },
  {
    slug: "how-big-is-this-before-you-send-it",
    jtbd: 24, surface: "cli", tier: "short", paid: false,
    pain: "I paste the context, wait, and find out it was too long.",
    ritual: "Send it and see. If it overflows, cut something at random and send it again.",
    fix: "The token cost per file, before you attach anything.",
    seconds: { manual: 0, chute: 2 }, perDay: 15,
    // No time saved directly — it prevents a full retry rather than shaving seconds. Saying so
    // is worth more than a fabricated figure.
    savedMinutes: null,
    demo: "/media/tokens.gif",
    command: "chute tokens src/*.ts",
  },
]

/** What the $19 buys, in the order the landing page argues them. */
export const PAID = CASES.filter((c) => c.paid)
/** What stays free and MIT, forever. */
export const FREE = CASES.filter((c) => !c.paid)
export const HEROES = CASES.filter((c) => c.tier === "hero")

/** Minutes a day a set of cases accounts for. Cases with no honest figure contribute nothing. */
export const minutesPerDay = (cases: Case[]): number =>
  Math.round(cases.reduce((sum, c) => sum + (c.savedMinutes ?? 0), 0) * 10) / 10

export const bySlug = (slug: string): Case | undefined =>
  CASES.find((c) => c.slug === slug)
