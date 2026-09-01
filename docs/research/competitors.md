# Chute — Competitive Field Research

Researched 2026-09-01 by web research agent. Every figure below carries its source URL.
Anything marked **[UNVERIFIED]** could not be confirmed from a primary source.

Product under study: **Chute** — $19 one-time macOS utility. Finder right-click + menu bar.
Wedge: select folders in Finder → right-click → every file inside lands on the clipboard as
one blob with a token count.

---

## 0. The headline finding (read this first)

**Repo Prompt — the closest paid analogue to Chute — stopped charging money on 2026-05-27
and open-sourced on 2026-06-13.**

The founder, Eric Provencher, wrote in <https://repoprompt.com/blog/repo-prompt-next-chapter>
(2026-05-27):

> "it's increasingly challenging to convince someone that they should pay me $15 a month to
> obtain those gains when they can just prompt their agent to solve problems for them, and it
> 'just works.'"

> "the need to commercialize that product to keep going has weighed on me since the beginning.
> Being a bootstrapped founder is relentless, as every subscription you earn might disappear
> the very next month."

Facts confirmed from that post and <https://repoprompt.com/blog/repo-prompt-community-edition>
(2026-06-13):

- All licensing restrictions removed as of Repo Prompt v2.1.32.
- All active subscriptions cancelled.
- Annual and lifetime licence holders "received compensation" (amount not stated).
- The trigger was the founder joining **OpenAI's developer-experience team** (recruited by
  Romain Huet). So this is *not* purely a market verdict — it is a founder-exit event with a
  market-pressure justification attached. Weigh it accordingly.

Two readings, both defensible:

1. **Bear case for Chute.** The best-funded, best-known, most-loved macOS "code → LLM context"
   app could not sustain $15/mo and gave the product away. The category's willingness-to-pay is
   collapsing because agents fetch their own context now.
2. **Bull case for Chute.** Provencher's product was a *$15/month subscription* competing with
   free agents on the same job (writing the code). Chute is a *$19 once* utility competing with
   nothing — it does a mechanical clipboard job an agent cannot do for you because the agent is
   not the thing holding the mouse. The failure mode he describes ("just prompt your agent")
   does not apply to "get these 40 files onto my clipboard right now".

The distinction that matters: **Repo Prompt sold judgement (which files matter). Chute sells
motion (getting bytes to the clipboard).** Judgement is what agents ate. Motion is not.

---

## 1. DIRECT competitors — codebase/selection → LLM context

GitHub star counts pulled live from the GitHub API on 2026-09-01.

| Tool | What it is | Platform | Price | Distribution | Stars | Last push |
|---|---|---|---|---|---|---|
| **repomix** (`yamadashy/repomix`) | Packs a whole repo into one AI-friendly file (XML/MD/JSON/plain). Git-aware, token counting, MCP server, remote-repo mode, web UI at repomix.com | Node CLI, cross-platform | Free (MIT) | npm / npx / brew / web | **28,148** | 2026-08-31 |
| **gitingest** (`coderamp-labs/gitingest`) | Swap `hub`→`ingest` in any GitHub URL for a prompt-friendly text extract. Also a CLI + Python pkg + browser extension | Web + Python CLI | Free (MIT) | Website, PyPI, browser ext | **15,367** | active |
| **code2prompt** (`mufeedvh/code2prompt`) | Rust CLI: codebase → single prompt with source tree, Handlebars templating, token counting | Rust CLI, cross-platform | Free (MIT) | cargo / brew / releases | **7,620** | 2026-06-29 |
| **files-to-prompt** (`simonw/files-to-prompt`) | Concatenate a directory of files into one prompt. `--cxml` flag emits Anthropic-style Claude XML | Python CLI | Free (Apache-2.0) | PyPI / uvx | **2,778** | 2025-02-19 (stale) |
| **yek** (`mohsen1/yek`) | Fast Rust serializer for text files in a repo, for LLM consumption. *(Note: repo moved from `bodo-run/yek` → `mohsen1/yek`; the old URL 301s)* | Rust CLI | Free | cargo / releases | **2,474** | active |
| **Repo Prompt CE** (`repoprompt/repoprompt-ce`) | Native macOS context-engineering app + MCP CLI. Context Builder, CodeMaps (tree-sitter signatures), agent orchestration | macOS app (Swift) | **Free** (Apache-2.0, since 2026-06) | GitHub releases | **892** | 2026-09-01 |
| **ai-digest** (`khromov/ai-digest`) | CLI aggregating a codebase into one Markdown file for Claude Projects / custom GPTs | Node CLI | Free (MIT) | npm | **680** | 2026-05-22 |
| **Prompt Tower** (`backnotprop/prompt-tower`) | VS Code extension: build context from repo/files/folders/GitHub issues, structured AI-XML, real-time token counting | VS Code extension | Free (AGPL-3.0) | VS Code Marketplace | **384** | 2025-12-23 |
| **16x Prompt** | Desktop app: pick context, compose prompt, send to API, apply diffs with backups | macOS + Windows + Linux | **One-time $48 individual / $68 team** (free tier = 10 prompts/day) | Direct download | closed source | active |
| **PasteMax** (`kleneway/pastemax`) | Desktop GUI: "select files from a repository to copy/paste into an LLM". This is the closest free thing to Chute's *job* | Electron, cross-platform | Free (MIT) | GitHub releases | **1,173** | 2026-02-09 |
| **Repomix-Desktop** (`KevanMacGee/Repomix-Desktop`) | Open-source desktop GUI wrapping the repomix CLI. Posted to HN 2026-05-10 | Python desktop | Free (MIT) | GitHub | **7** | 2026-05-13 |
| **prompt_builder** (`sangddn/prompt_builder`) | macOS/Flutter tool for long-context prompt building | macOS (Dart) | Free (MIT) | GitHub | **49** | 2025-06-18 (stale) |
| **cxml** | Not a standalone tool. It is an *output format* — Anthropic-style `<documents>` XML — exposed as `files-to-prompt --cxml` and copied by several of the above. | n/a | n/a | n/a | n/a | n/a |

Sources: <https://github.com/yamadashy/repomix>, <https://github.com/coderamp-labs/gitingest>,
<https://github.com/mufeedvh/code2prompt>, <https://github.com/simonw/files-to-prompt>,
<https://github.com/mohsen1/yek>, <https://github.com/repoprompt/repoprompt-ce>,
<https://github.com/khromov/ai-digest>, <https://github.com/backnotprop/prompt-tower>,
<https://prompt.16x.engineer/pricing>, <https://github.com/sangddn/prompt_builder>

### What each does BETTER than a Finder right-click

Be honest about this — it is the list Chute has to survive.

- **repomix / code2prompt / yek / ai-digest**: respect `.gitignore` and `.repomixignore`;
  sort files by git change frequency; strip comments; compress via tree-sitter to signatures
  only; emit structured XML with a header explaining the format to the model; run in CI; run as
  an MCP server so the *agent itself* invokes them. A Finder right-click does none of this.
- **gitingest**: works on a repo you have not cloned. Chute cannot touch a URL.
- **Repo Prompt CE**: visual file tree with token budget, CodeMaps, multi-agent orchestration,
  applies diffs back. Vastly larger surface than a clipboard utility.
- **16x Prompt**: cross-platform, sends the prompt to the API itself and applies the diff.
- **Prompt Tower**: lives inside the editor where the files already are.

### What a Finder right-click does better than all of them

- Zero terminal. Zero `cd`. Zero remembering a flag set. Zero config file.
- Works on **an arbitrary multi-selection across unrelated folders** — a repo-oriented CLI is
  awkward here; `repomix --include` globbing across three sibling projects is a chore.
- Works on **non-repo material**: a Downloads folder of PDFs, a client's spec dump, a
  screenshots folder. Every CLI above is repo-shaped.
- Works from **anywhere in the OS**, including while your terminal is busy running the agent —
  which, for a Claude Code user, it always is.
- The token count is delivered *before* you paste, at the moment of decision.

**Strategic read:** Chute's defensible ground is not "packs a codebase better". It is
"the selection is already in my hand, in Finder, and I am not going to open a terminal to
serialise it." Positioning that leans on packing quality loses to repomix. Positioning that
leans on *the gesture* does not, because none of the free tools have a gesture.

---

## 2. macOS context-menu / right-click / automation utilities

| Tool | Model | Price | Positioning | Install-base signal |
|---|---|---|---|---|
| **iBoysoft MagicMenu** | Freemium, sub **and** lifetime | Free tier; **$19.99/yr**; **$59.99 lifetime**; $9.99 first-year trial price | "Expand your Mac's right-click menu" — New File, Move To, Copy To, Quick Access, uninstall, dupe finder | MAS since 2022-01-16, v4.4 (2026-05-16). Also bundled in Setapp. Chinese vendor (Chengdu Aibo Tech) |
| **iRightMouse** | Free (MAS) | $0 | Free right-click enhancer | MAS since 2020-02-06, v2.4.7 (2026-02-02) |
| **iRightMouse Pro** | **One-time** | **$9.99** | Paid tier of the same | MAS since 2021-01-24, v2.4.7 (2026-02-02) |
| **Snippety** | Free app, paid unlock **[UNVERIFIED price]** | Free download on MAS | Snippet manager, macOS-native | MAS, **71 ratings**, updated 2026-08-01 (dev: Wojciech Kulik) |
| **Raycast** | Freemium subscription | Free; **Pro $8/mo annual, $10/mo monthly**; Team **$15/user/mo** (annual) / $20 monthly **[team monthly UNVERIFIED]**; Advanced AI add-on **+$8/mo** | Launcher + extension store. The extension store is where a free "copy folder as prompt" clone would appear | Very large; extension store is the real threat surface |
| **Keyboard Maestro** | **One-time, paid major upgrades** | **US$36** new, **US$25** upgrade | Macro automation. Explicitly anti-subscription: "No subscription, you can purchase it now for US$36 … and use version 11 indefinitely" | v11, long-running (since 2002) |
| **Hazel** | **One-time, paid major upgrades** | **$42** (Hazel 6), **$65** family 5-pack, **$20** upgrade | Folder-watching automation rules | Noodlesoft, long-running |
| **Alfred Powerpack** | **One-time per major version** | **£34** single licence; **£59** "Mega Supporter" = free lifetime upgrades | Launcher + workflows | v5, very large install base |
| **Automator / Shortcuts Quick Actions** | Built into macOS | **$0** | Apple's own path to a Finder right-click item. A Shortcuts Quick Action can already read a selection and write to the clipboard | Preinstalled on every Mac |

Sources: <https://apps.apple.com/us/app/iboysoft-magicmenu/id1599191594>,
<https://iboysoft.com/magic-menu/>, <https://setapp.com/apps/iboysoft-magicmenu>,
<https://apps.apple.com/us/app/irightmouse-pro/id1550403011>,
<https://apps.apple.com/us/app/snippety-snippets-manager/id1530751461>,
<https://www.raycast.com/pricing>, <https://keyboardmaestro.com/main/>,
<https://store.noodlesoft.com/>, <https://www.alfredapp.com/shop/>

### The two real threats in this section

1. **Shortcuts / Automator Quick Action, $0.** A competent macOS user can build "concatenate
   selection to clipboard" as a Quick Action in an afternoon. What they cannot easily build:
   correct token counting, binary/lockfile exclusion, gitignore awareness, large-selection
   performance, and a menu-bar surface. Chute's answer to "why not a Shortcut" must be a
   concrete list of the things the Shortcut gets wrong, not a claim of impossibility.
2. **A free Raycast extension.** Raycast's store is exactly where someone ships
   "Copy Folder as Prompt" for free, and Raycast is already installed on the target user's Mac.
   This is the most likely source of a zero-price clone. **[UNVERIFIED: whether such an
   extension already exists — not checked in this pass.]**

Note the pricing pattern in this table: the durable, respected macOS utilities in this space
(**Keyboard Maestro $36, Hazel $42, Alfred £34, iRightMouse Pro $9.99**) are **one-time**, and
Keyboard Maestro markets that fact as a feature. Chute at $19 sits comfortably inside this band
— below Hazel and Keyboard Maestro, above iRightMouse Pro.

---

## 3. Repo Prompt — deep dive

**Status as of 2026-09-01: free and open source. There is no longer a paid Repo Prompt.**

- Author: **Eric Provencher**, Quebec, Canada. Now at **OpenAI** (developer experience team).
- Positioning today (<https://repoprompt.com>): *"Curate the right context, run deep analysis,
  and orchestrate coding agents from one native macOS app."* — the tagline is "The Context IDE
  for AI Agents". It has moved decisively **away** from "copy a prompt" and **toward**
  "orchestrate agents".
- Editions:
  - **Community Edition** — free, Apache-2.0, `repoprompt/repoprompt-ce`, **892 stars, 116
    forks**, Swift, first commit 2026-05-12, actively pushed 2026-09-01. Active development.
  - **Classic** — the original manual prompt-building workflow. Marked **"Legacy / No longer
    supported"**, DMG still downloadable, source archived at `repoprompt/repoprompt-classic`.
- Historic pricing (from the founder's own post + third-party reviews):
  - Free tier capped at **32k tokens**
  - **Pro $14.99/month** with a 1-month free trial
  - Annual ~**$149/yr** and lifetime **$349–$399** — **[UNVERIFIED: these annual/lifetime
    figures come from a third-party review (<https://vibecoding.app/blog/repo-prompt-review>),
    not from Repo Prompt's own pages, which are now down. Treat as approximate.]**
  - The founder's own post says "$15 a month", consistent with the $14.99 figure.
- Distribution: direct download from repoprompt.com + GitHub releases. Not on the Mac App
  Store (it needs broad filesystem access and MCP/CLI integration, which sandboxing fights).
  Community via **Discord**; marketing via **YouTube** — the founder's channel has **2,340
  subscribers**, with videos going back ~1 year ("Getting started with Repo Prompt",
  "How I use Repo Prompt to build Repo Prompt").
- Size signals: 2.34K YouTube subscribers; 892 GitHub stars in ~4 months; an active Discord;
  a testimonial wall sourced entirely from X/Twitter. **No revenue or user-count figure was
  ever published. [UNVERIFIED — do not guess one.]**
- What users complained about: **[UNVERIFIED — I could not find a substantial corpus of user
  complaints in this pass.]** The one complaint documented from a primary source is the
  founder's own framing of the objection he kept hearing: that agents "just work" and users did
  not want to pay a monthly fee to hand-curate context. Third-party reviews exist
  (<https://vibecoding.app/blog/repo-prompt-review>, <https://www.everydev.ai/tools/repoprompt>,
  <https://rywalker.com/research/repo-prompt>) but read as affiliate/SEO content rather than
  user complaint.

### What this means for Chute — the uncomfortable version

The nearest analogue's founder concluded the *subscription* version of this job was unsellable
in 2026. Chute must not be a smaller Repo Prompt. The lesson to take is narrow and specific:

- Do **not** sell "better context curation" — that is the job Provencher lost.
- Do **not** sell a subscription for a mechanical action.
- **Do** sell the thing his product never had: a gesture available everywhere in the OS,
  at a price low enough that nobody convenes a meeting about it.

Also note the upside: the paid competitor in the macOS niche **just left the market**. There is
now no paid, marketed, macOS-native product occupying "code → clipboard for an LLM". That is a
genuine opening, and it is also a warning about why the space is empty.

---

## 4. Pricing evidence — one-time-purchase indie macOS dev utilities, 2025-2026

| App | Price | Model | Notes |
|---|---|---|---|
| **iRightMouse Pro** | **$9.99** | One-time (MAS) | Direct genre neighbour |
| **Rectangle Pro** | **$9.99** | One-time, 1 licence / 3 Macs | Free Rectangle exists alongside it — a *paid tier over a free tool* precedent |
| **Paletro** | **$6.99** | One-time (14-day trial) | Also available inside Setapp at $9.99/mo |
| **Bartender 6** | **$20** | One-time | Bartender 5 buyers in 2025 got 6 free. **Bartender Pro $15/yr** subscription now exists alongside — a one-time app *adding* a sub tier |
| **CleanShot X** | **$35** | One-time + **optional $19/yr** renewal for continued updates | Cloud tier is separate: **$10/user/mo annual, $12 monthly**. Textbook "one-time core, subscription for the server-side part" |
| **Keyboard Maestro 11** | **US$36** | One-time, **$25** paid major upgrade | Markets "No subscription" as a selling point |
| **Alfred 5 Powerpack** | **£34** single / **£59** lifetime-upgrades | One-time per major version | |
| **Hazel 6** | **$42** / $65 family / **$20** upgrade | One-time, paid major upgrades | |
| **16x Prompt** | **$48** individual / **$68** team | One-time lifetime licence | *Direct competitor charging one-time and surviving* |
| **TablePlus** | **$99** basic (1 device) / **$129** standard (2 devices) / **$79** per seat team (min 3) | **Perpetual, buy once use forever**; optional **$59/device** renewal for more updates | |
| **Proxyman** | **$89** for 1 seat / **$99** for 2 seats / **$79 per seat/yr** team | Perpetual with 1 year of updates; **optional $49 ($79 team) renewal**. Also offers **$12/seat/mo** subscription | Runs both models side by side |
| **Ice** | **$0** | Free, open source | The free Bartender clone. Proof that a beloved paid macOS utility category gets a free OSS competitor fast |
| **Shottr** | **Pay what you want, $0 allowed** | Donationware | Undercuts CleanShot X at $0 |
| **Dash** | **€1.25/month billed yearly** (~€15/yr) | **MOVED one-time → subscription** with Dash 7 on **2023-08-17**. Existing perpetual licences honoured for 2 years | The clearest documented direction-of-travel case |

Sources: <https://www.mactools.pro/blog/rectangle-pro-is-it-worth-it>,
<https://appmakes.io/paletro>, <https://www.macbartender.com/purchase/>,
<https://cleanshot.com/pricing>, <https://keyboardmaestro.com/main/>,
<https://www.alfredapp.com/shop/>, <https://store.noodlesoft.com/>,
<https://prompt.16x.engineer/pricing>, <https://tableplus.com/pricing>,
<https://proxyman.com/pricing>, <https://shottr.cc>, <https://blog.kapeli.com/dash-7>

### Movement between models — the actual pattern

- **Dash**: one-time → **subscription** (2023-08-17), explicitly because "the paid upgrade
  pricing model is no longer a good fit". Moved *up*.
- **Repo Prompt**: subscription → **free/open source** (2026-05/06). Moved *down to zero*.
- **Bartender**: one-time → **one-time + optional sub tier** (Bartender Pro $15/yr).
- **CleanShot X, TablePlus, Proxyman**: all converged on the same hybrid —
  **perpetual licence + optional paid renewal for continued updates**, and in Proxyman's case a
  parallel subscription for teams. This is the dominant 2025-2026 shape for a serious indie Mac
  dev tool.
- **Bartender → Ice** and **CleanShot X → Shottr**: every successful paid macOS utility category
  acquires a free/OSS or pay-what-you-want competitor within a couple of years. Assume Chute
  will too. Price and positioning should assume the free clone exists.

### Where $19 sits

$19 is **below** every serious one-time dev utility in the table except Paletro ($6.99),
Rectangle Pro ($9.99) and iRightMouse Pro ($9.99) — and those three are all much narrower
single-gesture tools, which is exactly what Chute is. $19 is comfortably under Bartender ($20),
Keyboard Maestro ($36), Alfred (£34), Hazel ($42), 16x Prompt ($48).

$19 is a defensible "no-approval-needed" price for a single-gesture utility. The risk at $19 is
not that it is too high — it is that it is too low to fund support for an app touching arbitrary
user filesystems. **[Judgement, not evidence.]**

---

## 5. "Why pay $19 when repomix is free?" — the honest answer

### 5a. The best single piece of evidence: Downie

**Downie** is a $19.99 one-time macOS app that is, functionally, a GUI over `yt-dlp` — a free,
world-class, actively maintained open-source CLI. It has been commercially successful for years
and is sold both direct and via Setapp. Same price point as Chute. Same relationship to a free
CLI. Same audience (technical Mac users who *know* the free tool exists).

John Gruber, Daring Fireball, 2025-02-26 (<https://daringfireball.net/linked/2025/02/26/downie-4>):

> "Downie is a $20 one-time purchase (and is also included with a Setapp subscription)."

> "I enjoy using Downie far more than invoking yt-dlp, but … I use Downie more often than I used
> yt-dlp, because it's so much easier and more reliable."

> "It's like using Transmit instead of the command-line tools for secure FTP connections."

> "Macs support Unix terminals and free utilities, [but] the point of using a Mac is to use
> great Mac apps. And Downie is a great Mac app."

The load-bearing sentence is the second one: **"I use Downie more often than I used yt-dlp."**
That is the entire argument for Chute in one line. The paid wrapper does not compete on
capability with the free CLI. It competes on *frequency of use*. A friction reduction that
changes how often you do a thing is worth money even when the thing was already possible.

### 5b. The same pattern, priced

| Free CLI / OSS | Paid GUI over it | Price | Model |
|---|---|---|---|
| yt-dlp / youtube-dl | **Downie** | **$19.99** | One-time |
| ffmpeg / HandBrake | **Permute** | ~$19.99 **[UNVERIFIED — price not confirmed from primary source]** | One-time |
| sftp / rsync / curl | **Transmit 5** (Panic) | **$45** | One-time |
| whisper.cpp / OpenAI Whisper | **superwhisper** | **$8.49/mo** Pro (annual), lifetime tier offered | Subscription + lifetime |
| git CLI | Tower / Sublime Merge / Fork | $ varies | Sub / one-time |
| mysql / psql CLI, free Sequel Ace | **TablePlus** | **$99** | Perpetual |
| mitmproxy (free) | **Proxyman** | **$89** | Perpetual |

Every row is the same trade and every row has a real business behind it. The category
"paid GUI over free CLI, sold to developers who could use the CLI" is not speculative — it is
one of the most reliable indie-Mac business shapes there is.

### 5c. Real forum evidence, including the hostile view

Pro:

- HN, 2025-01-04, <https://news.ycombinator.com/item?id=42594347> —
  > "Making a good user interface is definitely not easy. Yet it's orders of magnitude easier
  > than writing ffmpeg. That said, **there is nothing wrong with a paid wrapper around a large
  > and complex open source library.** Distributing their work more widely is not a disservice."
- HN, 2024-06-30, <https://news.ycombinator.com/item?id=40840431> — a user encountering Permute
  for the first time:
  > "Seems like a paid app. **I don't mind paying for software if it's really better than other
  > existing free options.**"
  Note the condition attached: *really better*, not merely wrapped.
- HN, 2025-09-24, <https://news.ycombinator.com/item?id=45354808> — an unprompted paying customer
  of the (then-paid) Repo Prompt:
  > "I created an account to say this: RepoPrompt's 'Context Builder' feature helps a ton with
  > scoping context before you touch any code. It's kind of like if you could chat with Repomix
  > or Gitingest … **I'm a paying RepoPrompt user** but not associated in any other way."
  Direct proof that people did pay for this exact job — before the founder stopped charging.

Against — take this seriously, it is the objection Chute will meet:

- HN, 2025-10-23, <https://news.ycombinator.com/item?id=45686214> —
  > "I had to buy Superwhisper (which is a nice product) — **It's literally a paid wrapper
  > around a completely free program** you would also be using for free if Apple wasn't actively
  > hostile to Open Source software distribution."
- HN, 2026-01-19, <https://news.ycombinator.com/item?id=46678781> —
  > "I would bet that this tool is just a paid version of the same, or worse, **just a paid
  > wrapper**"
- The strongest version of the objection is not from a forum at all. It is Repo Prompt's founder
  concluding that a $15/mo context tool could not be justified against agents that "just work"
  (<https://repoprompt.com/blog/repo-prompt-next-chapter>, 2026-05-27).

### 5d. What the evidence actually says — the honest answer

**Chute is not sold to people who would otherwise run repomix. It is sold to people who would
otherwise do nothing, or do it by hand.**

The evidence supports four specific claims and does not support a fifth:

1. **Supported — frequency, not capability, is the product.** Gruber's admission that he uses
   Downie *more often* than he used yt-dlp is the mechanism. Chute's honest pitch: you will
   feed the agent context you currently do not bother to feed it, because right-click is cheaper
   than opening a terminal.
2. **Supported — $19.99 one-time is the proven price for exactly this trade.** Downie sits at
   that number and has for years. So do Rectangle Pro, Paletro, Bartender at $9.99–$20 for
   single-gesture utilities.
3. **Supported — the objection has a known answer, and it is "really better", not "wrapped".**
   The HN commenter's condition is the spec: Chute must be *better at its gesture* than a
   `repomix` invocation, not merely a face on one. Concretely: works on an arbitrary Finder
   multi-selection, works on non-repos, shows the token count before you paste, needs no `cd`,
   needs no config, and works while your terminal is occupied by the agent.
4. **Supported — the paid competitor just exited.** No paid, marketed, macOS-native product now
   occupies this slot. 16x Prompt at $48 one-time is the only paid survivor and it is a
   cross-platform prompt IDE, not a Finder gesture.
5. **NOT supported — that people will pay for "packing quality".** repomix at 28k stars, free,
   with gitignore awareness, tree-sitter compression, git-churn ordering and an MCP server, wins
   that argument outright. Any marketing copy that competes on output quality loses. Also note
   **PasteMax (1,173 stars, MIT, free)** already does "GUI file picker → clipboard for an LLM"
   at $0 — it is just not a Finder right-click, and it is not macOS-native.

### 5e. The one-sentence answer to give a skeptic

> "repomix is free and better at packing a repo. Chute is $19 and better at the thirty seconds
> before that — when the files you want are already selected in Finder, your terminal is busy
> running the agent, and the alternative is not repomix, it's giving up and pasting two files
> by hand."

---

## 6. Risks this research surfaced

1. **The nearest paid analogue went to $0 four months ago.** Anyone evaluating Chute who knows
   the space will ask about it. Have the answer ready (section 3).
2. **A free Raycast extension is the most likely clone vector.** Raycast is already installed on
   the target user's Mac and its store is frictionless. I found no such extension in this pass —
   but absence of evidence here is weak evidence, I did not exhaustively enumerate the store.
   **[UNVERIFIED]**
3. **Shortcuts / Automator Quick Actions are free and built in.** The rebuttal must be a concrete
   list of what a hand-rolled Quick Action gets wrong, not a claim it cannot be done.
4. **PasteMax already exists, free, 1,173 stars.** Different surface (Electron app, not Finder),
   same job. Someone will port the gesture.
5. **Every paid Mac utility category grows a free clone.** Bartender→Ice, CleanShot X→Shottr,
   repomix→already free. Plan for it in positioning, not in a moat.
6. **The direction of travel in this niche is toward MCP.** repomix ships an MCP server; Repo
   Prompt CE is now MCP-first. If agents fetch their own context via MCP, the human-clipboard
   gesture shrinks. Chute's counter is that a human still curates the *selection* — but that is
   the exact bet Provencher lost on the subscription side.

---

---

## Appendix — verification status

- GitHub star counts: pulled live from `api.github.com` on 2026-09-01. Exact.
- Mac App Store data: pulled from `itunes.apple.com/lookup` on 2026-09-01. Prices exact;
  US rating counts returned as 0 by the API for several apps and are therefore omitted rather
  than reported as zero.
- Repo Prompt historic annual/lifetime prices: third-party review only. **Unverified.**
- Repo Prompt user/revenue size: **no primary figure exists. Do not invent one.**
