import Foundation
import ChuteCore

let helpText = """
chute — drop context into your agent.

CONTEXT IN
  paths <files…>        Absolute paths, agent-ready       --format posix|quoted|relative|at  --sep line|space
  bundle <files…>       Files + contents in one blob      --format xml|md
  tokens <files…>       Estimated token cost per file
  tree [dir]            Directory skeleton, junk excluded --depth N
  buf add|list|flush|clear                                Context buffer across many copies

FILES
  new                   Clipboard → new file              --name N --dir D --ext E --reveal
  unpack                Markdown code blocks → files      --dir D --force   (dry run by default)
  seed [dir]            CLAUDE.md / .cursorrules / …      --rules claude,cursor,agents,scratchpad,gitignore
  note "text"           Append to SCRATCHPAD.md           --dir D
  latest [dir]          Reveal newest artifact            --quicklook
  clean [dir]           List agent scratch files          --force  (Trash; lists by default)

AGENTS
  sandbox [name]        New folder + git + rules + agent  --agent claude|codex|gemini --yolo --dir D --each <dirs…>
  open [dir]            Terminal or editor here           --with terminal|editor
  ports                 What is listening                 --kill PORT
  prompt decompose|ponytail                               Prompt templates → clipboard

GIT SAFETY
  checkpoint [dir]      Snapshot before an agent runs     (never touches your worktree)
  diff [dir]            What the agent changed            --copy

AGENT SESSIONS
  sessions              Every terminal session, grouped by state     --json
  focus <key|project|N> Bring that session to the front
  resume [key|N]        The command to pick that conversation up again  --tmux
  hooks snippet|uninstall|status  Never edits your settings itself   --settings PATH

SHARING
  redact [files…]       Mask API keys and tokens
  gist <files…>         Secret gist → URL on clipboard
  dataurl <image>       Base64 data URL                   --markdown
  env inject [dir]      Keychain → .env                   --keys A,B

SETUP
  doctor                Check every prerequisite and say how to fix it   --fix --json
  onboard               What Chute is, and the first thing to try

Global: --no-copy  suppress clipboard write.
Everything is offline and nothing is uploaded, with one explicit exception: `gist` sends the
files you name (redacted first) to GitHub.

This CLI is free and MIT, forever. The Finder right-click menu and the menu-bar session
switcher are the paid app — 14 days free, then $19 once: chutedev.com
"""

let argv = Array(CommandLine.arguments.dropFirst())
// `--version` and `--help` are the forms every other CLI answers to, so answer to them here:
// anything starting with `--` is swallowed by Args as a flag and never reaches the switch below,
// which left the `case "--version"` there looking handled while printing the help instead.
if argv.first == "--version" || argv.first == "-V" {
    print("chute \(ChuteVersion.current)")
    exit(0)
}
guard let command = argv.first, !command.hasPrefix("--") else {
    print(helpText)
    exit(argv.isEmpty ? 1 : 0)
}
let args = Args(Array(argv.dropFirst()))

switch command {
case "paths":      cmdPaths(args)
case "bundle":     cmdBundle(args)
case "tokens":     cmdTokens(args)
case "tree":       cmdTree(args)
case "buf":        cmdBuf(args)
case "new":        cmdNew(args)
case "unpack":     cmdUnpack(args)
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
    if command.contains("version") { print("chute \(ChuteVersion.current)") } else { print(helpText) }
default:
    Out.fail("unknown command '\(command)' — run `chute help`")
}
