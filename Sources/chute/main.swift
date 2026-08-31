import Foundation
import ChuteCore

let helpText = """
chute — drop context into your agent.

CONTEXT IN
  paths <files…>        Absolute paths, agent-ready       --format posix|quoted|relative|at  --sep line|space
  bundle <files…>       Files + contents in one blob      --format xml|md
  tokens <files…>       Estimated token cost per file
  tree [dir]            Directory skeleton, junk excluded --depth N
  basket add|list|copy|clear                              Collect files across folders, hand over once
                        copy --format mentions|context      @mentions for an agent, or the files themselves

FILES
  new                   Clipboard → new file              --name N --dir D --ext E --reveal
  seed [dir]            CLAUDE.md / .cursorrules / …      --rules claude,cursor,agents,scratchpad,gitignore
  note "text"           Append to SCRATCHPAD.md           --dir D
  latest [dir]          Reveal newest artifact            --quicklook
  clean [dir]           List agent scratch files          --force  (Trash; lists by default)

AGENTS
  sandbox [name]        New folder + git + rules + agent  --agent claude|codex|gemini --yolo --dir D --each <dirs…>
  open [dir]            Terminal or editor here           --with terminal|editor
  ports                 What is listening                 --kill PORT --force  (kill previews by default)
  prompt decompose|ponytail                               Prompt templates → clipboard

GIT SAFETY
  checkpoint [dir]      Snapshot before an agent runs     (never touches your worktree)
  diff [dir]            What the agent changed            --copy

AGENT SESSIONS
  sessions              Every terminal session, grouped by state     --json
  focus <key|project|N> Bring that session to the front
  resume [key|N]        The command to pick that conversation up again  --tmux
  hooks snippet|uninstall|status  Never edits your settings itself   --settings PATH --force
                                   (uninstall previews by default)

SHARING
  redact [files…]       Mask API keys and tokens
  gist <files…>         Secret gist → URL on clipboard    --force  (dry run by default)
  dataurl <image>       Base64 data URL                   --markdown
  env inject [dir]      Keychain → .env                   --keys A,B --force  (dry run by default)

SETUP
  doctor                Check every prerequisite and say how to fix it   --fix --force --json
                                   (--fix previews by default)
  onboard               What Chute is, and the first thing to try

Global: --no-copy  suppress clipboard write.
Everything is offline and nothing is uploaded, with one explicit exception: `gist` sends the
files you name (redacted first) to GitHub.

This CLI is free and MIT, forever. The Finder right-click menu and the menu-bar session
switcher are the paid app — 14 days free, then $19 once: chutedev.com
"""

let argv = Array(CommandLine.arguments.dropFirst())
// The stamp `Scripts/build-app.sh` writes into both Info.plists and `chute doctor` already
// prints — reused here, worded the same way, so the two surfaces never disagree about what
// "current" means. Absent (a binary from a plain `swift build`, never through build-app.sh) must
// read as absent, not as current — DiagnosticsSuite already asserts installedBuild() itself does
// that; this is the same "not stamped" wording DoctorCommand's non-json line uses.
let versionLine = "chute \(ChuteVersion.current) · app build "
    + (Diagnostics.installedBuild() ?? "not stamped — rebuild with ./Scripts/build-app.sh")
// `--version` and `--help` are the forms every other CLI answers to, so answer to them here:
// anything starting with `--` is swallowed by Args as a flag and never reaches the switch below,
// which left the `case "--version"` there looking handled while printing the help instead.
if argv.first == "--version" || argv.first == "-V" {
    print(versionLine)
    exit(0)
}
guard let command = argv.first, !command.hasPrefix("--") else {
    print(helpText)
    exit(0) // no-args is the product's front door: help on stdout, exit 0 — not a failure to pipe.
}
let args = Args(Array(argv.dropFirst()))

switch command {
case "paths":      cmdPaths(args)
case "bundle":     cmdBundle(args)
case "tokens":     cmdTokens(args)
case "tree":       cmdTree(args)
case "basket":     cmdBasket(args)
// `buf` was the name until 2026-08-31. Undocumented alias: it is in muscle memory and in scripts,
// and breaking a name costs more than the name was ever worth.
case "buf":        cmdBuf(args)
case "new":        cmdNew(args)
case "seed":       cmdSeed(args)
case "note":       cmdNote(args)
case "latest":     cmdLatest(args)
case "clean":      cmdClean(args)
case "sandbox":    cmdSandbox(args)
case "open":       cmdOpen(args)
case "ports":      cmdPorts(args)
case "prompt":     cmdPrompt(args)
case "checkpoint": cmdCheckpoint(args)
case "diff":       cmdDiff(args)
case "redact":     cmdRedact(args)
case "gist":       cmdGist(args)
case "dataurl":    cmdDataURL(args)
case "env":        cmdEnv(args)
case "sessions":   cmdSessions(args)
case "focus":      cmdFocus(args)
case "hooks":      cmdHooks(args)
case "doctor":     cmdDoctor(args)
case "resume":     cmdResume(args)
case "onboard":    cmdOnboard(args)
case "finder-actions": cmdFinderActions(args)
case "paste-image":    cmdPasteImage(args)
case "help", "-h", "--help", "version", "--version":
    if command.contains("version") { print(versionLine) } else { print(helpText) }
default:
    Out.fail("unknown command '\(command)' — run `chute help`")
}
