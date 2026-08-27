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
  hooks install|uninstall|status                                     --settings PATH

SHARING
  redact [files…]       Mask API keys and tokens
  gist <files…>         Secret gist → URL on clipboard
  dataurl <image>       Base64 data URL                   --markdown
  env inject [dir]      Keychain → .env                   --keys A,B

SETUP
  doctor                Check every prerequisite and say how to fix it   --fix --json

Global: --no-copy  suppress clipboard write.  Everything is offline; nothing is ever uploaded.
"""

let argv = Array(CommandLine.arguments.dropFirst())
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
case "finder-actions": cmdFinderActions(args)
case "paste-image":    cmdPasteImage(args)
case "help", "-h", "--help", "version", "--version":
    if command.contains("version") { print("chute 0.1.0") } else { print(helpText) }
default:
    Out.fail("unknown command '\(command)' — run `chute help`")
}
