import Foundation
import ChuteCore

func argParseSuite() {
    T.suite("ArgParse") {
        // THE BUG. `--force` swallowed the next word, `clean` fell back to the current directory,
        // and — preview skipped — trashed files the user never named.
        let clean = ArgParse.split(["--force", "./other"])
        T.eq(clean.positional, ["./other"], "a boolean flag never consumes the path after it")
        T.ok(clean.flags["force"] != nil, "and the flag is still set")
        T.eq(ArgParse.split(["--no-copy", "a.txt"]).positional, ["a.txt"], "`paths --no-copy a.txt` names a.txt, not the folder")
        T.eq(ArgParse.split(["--each", "dirA", "dirB"]).positional, ["dirA", "dirB"], "`sandbox --each dirA dirB` keeps both")

        let value = ArgParse.split(["--dir", "/x", "name"])
        T.eq(value.flags["dir"], "/x", "a flag in the value set takes the next word")
        T.eq(value.positional, ["name"], "and only that word")
        T.eq(ArgParse.split(["--dir", "--force"]).flags["dir"], "", "a value flag followed by another flag is empty, not the flag")
        T.eq(ArgParse.split(["--dir"]).flags["dir"], "", "or at the end of the line")
        T.eq(ArgParse.split([]).positional, [], "nothing in, nothing out")

        // Every flag a command reads a value from is in the set; a new one that is not will
        // parse as a switch and its value becomes a path. Grep is the oracle for this list.
        for f in ["format", "sep", "depth", "dir", "ext", "name", "naming", "rules", "agent",
                  "with", "kill", "keys", "settings", "files-from", "watch-seconds"] {
            T.ok(ArgParse.valueFlags.contains(f), "\(f) takes a value")
        }
        T.no(ArgParse.valueFlags.contains("force"), "force is a switch")

        // `--files-from`: exactly as written. Trimming renamed any file with an edge space.
        T.eq(ArgParse.pathList("/a/b.txt\n /c/ d .txt\n\n"), ["/a/b.txt", " /c/ d .txt"],
             "one path per line, spaces kept, blank lines dropped")
    }

    T.suite("HotKeyStatus") {
        T.eq(HotKeyStatus.problem(0), nil, "noErr is no problem")
        T.ok(HotKeyStatus.problem(-9878)?.contains("another app") == true, "eventHotKeyExistsErr names the cause")
        T.ok(HotKeyStatus.problem(-50)?.contains("-50") == true, "anything else carries its code")
    }

    T.suite("LocalServers.KillOutcome") {
        T.ok(LocalServers.KillOutcome.stillListening([5375]).message(port: 5432).contains("still held by pid 5375"),
             "a kill that did not take says so — it was reported as 'killed 1 process'")
        T.ok(LocalServers.KillOutcome.stopped([1, 2]).message(port: 3000).contains("Stopped 2"), "a stop counts what it stopped")
        T.ok(LocalServers.KillOutcome.nothingListening.message(port: 3000).contains("Nothing"), "and nothing is nothing")
    }
}
