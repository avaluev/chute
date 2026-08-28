import Foundation
import ChuteCore

func agentTranscriptSuite() {
    T.suite("AgentTranscript") {
        // The fixture is found relative to this source file. The test target declares no SwiftPM
        // resources and does not need to: `chutetests` is an executable run from the repo.
        let fixture = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().appendingPathComponent("fixtures/transcript.jsonl").path
        let text = (try? String(contentsOfFile: fixture, encoding: .utf8)) ?? ""
        T.no(text.isEmpty, "the fixture is readable at \(fixture)")

        let t = AgentTranscript.parse(text)
        T.eq(t?.sessionID, "14e46ac7-12b2-4980-b920-4bfe991be17b", "the session id is read")

        // THE NEWEST ANSWER WINS. A long session can change model and effort partway through —
        // this fixture starts on opus-4-7 at high and ends on opus-5 at low. Reporting the first
        // one it happened to see would describe a session that ended hours ago.
        T.eq(t?.model, "claude-opus-5", "the model is the most recent one, not the first")
        T.eq(t?.effort, "low", "and so is the effort")
        T.eq(t?.branch, "feature/x", "and the branch, which moves during a session")
        T.eq(t?.version, "2.1.250", "the CLI version comes through")
        T.eq(t?.cwd, "/Users/x/proj", "and the working directory")

        // Totals are over the WHOLE file: cost is cumulative, unlike model and branch.
        T.eq(t?.outputTokens, 350, "output tokens are summed across the session")
        T.eq(t?.cacheReadTokens, 10_000, "cache reads too")
        T.eq(t?.cacheWriteTokens, 75, "and cache writes")

        // EVERY FIELD OPTIONAL. This reads another product's private file format. When it
        // changes, a row must lose a detail — never throw, never block, never show a wrong value.
        let noModel = AgentTranscript.parse(#"{"sessionId":"abc","type":"user","message":{"role":"user"}}"#)
        T.eq(noModel?.sessionID, "abc", "a file with no assistant turn still yields its id")
        T.eq(noModel?.model, nil, "and reports no model rather than inventing one")
        T.eq(noModel?.outputTokens, 0, "with zero cost, not a crash")

        T.eq(AgentTranscript.parse(""), nil, "an empty file is nil")
        T.eq(AgentTranscript.parse("not json at all\n{{{"), nil, "so is a file of garbage")

        // A truncated last line is the NORMAL case for a session being written right now, and for
        // the tail read below, which starts mid-file. It must be skipped, not fatal.
        let truncated = text + "\n{\"sessionId\":\"x\",\"type\":\"assist"
        T.eq(AgentTranscript.parse(truncated)?.model, "claude-opus-5",
             "a half-written final line is ignored, and the record before it still counts")

        // THE WHOLE FILE, and the totals are why. A windowed read was tried and measured out:
        // the biggest transcript on this machine is 12.4 MB and parses in 37 ms, while a tail
        // read reported "17k out" for a session that had produced 353k — cumulative counts do
        // not survive being windowed, and the wrongness is invisible to the reader.
        T.eq(AgentTranscript.readFile(fixture)?.outputTokens, 350,
             "reading the file gives the SESSION total, not the last few turns")
        T.eq(AgentTranscript.readFile(fixture)?.model, "claude-opus-5", "and the current model")

        T.eq(AgentTranscript.readFile("/no/such/transcript.jsonl"), nil,
             "a missing file is nil, not a throw")

        // The uuid is the whole filename, so anything that is not one is refused rather than
        // allowed to compose a path out of a value that came from a file on disk.
        T.eq(AgentTranscript.find(sessionID: "../../../etc/passwd"), nil, "a path is not a session id")
        T.eq(AgentTranscript.find(sessionID: ""), nil, "nor is an empty string")

        // Display names. An id we do not recognise is shown as it is: inventing a pretty name for
        // a model nobody has heard of is how a menu starts lying about what is running.
        T.eq(AgentTranscript.displayModel("claude-opus-5"), "Opus 5", "known ids read as people say them")
        T.eq(AgentTranscript.displayModel("claude-sonnet-4-5-20250929"), "Sonnet 4.5", "dated ids too")
        T.eq(AgentTranscript.displayModel("some-future-model"), "some-future-model",
             "and an unknown id is passed through untouched")
        T.eq(AgentTranscript.displayModel(nil), nil, "nil stays nil")

        // Cost, phrased for a human. Never in dollars — see the note in AgentTranscript.
        T.eq(AgentTranscript.costLabel(output: 352_928, cacheRead: 88_247_948),
             "353k out · 88.2M cached", "big numbers are readable at a glance")
        T.eq(AgentTranscript.costLabel(output: 0, cacheRead: 0), nil, "a session that cost nothing says nothing")
    }
}
