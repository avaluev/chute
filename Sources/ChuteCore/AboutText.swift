import Foundation

/// THE WORDS IN THE ABOUT TAB, where a test can read them.
///
/// They lived in `Sources/ChuteApp/SettingsWindow.swift`, which `chutetests` cannot link, and for
/// weeks they said: *"Nothing is uploaded, ever, except by the `gist` command."* The first half of
/// that sentence is a string `marketing/06-FACT-SHEET.md` has forbidden in bold since 2026-08-28 —
/// because `gist` uploads — and the site, the README and every marketing file are swept for it on
/// every deploy. Nobody had ever swept the app, which is the one place a PAYING CUSTOMER reads it.
///
/// The replacement is the fact sheet's own phrasing, word for word. It is longer than the absolute
/// version and it is more convincing, because a reader can check every clause of it against the
/// source in one grep.
public enum AboutText {
    public static func about(version: String, build: String?) -> (heading: String, body: [String]) {
        var body: [String] = []
        // The build stamp is what a bug report needs and what nobody remembers to ask for.
        if let build { body.append("build \(build)") }
        body.append(privacy)
        return ("Chute \(version)", body)
    }

    public static let privacy = """
        Chute contains no network code at all: no account, no telemetry, no licence server, no \
        launch daemon.

        One command uploads, and only when you run it. `chute gist` shells out to your own `gh`, \
        with your own GitHub credentials, on the files you name, after redacting keys and tokens. \
        Chute itself never opens a socket.
        """
}
