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

    /// WHERE A HUMAN ANSWERS.
    ///
    /// Chute is free, MIT, and made by one person. There is no support tier and no ticket queue,
    /// so the honest thing to put in front of a user who is stuck is the actual places that
    /// person reads. "Report a Problem…" already files a redacted diagnostic into GitHub, which
    /// is right for a bug — this is for everything that is not a bug.
    ///
    /// A TELEGRAM HANDLE, NEVER A PHONE NUMBER. The handle can be abandoned or changed; a number
    /// cannot be un-scraped once a bot has it, and this app ships to strangers. The same rule
    /// removed the founder's home address from the website on 2026-09-08 — the reverse of that
    /// decision must not sneak back in through the About tab.
    public static let contacts: [(label: String, handle: String, url: String)] = [
        ("GitHub", "github.com/avaluev/chute", "https://github.com/avaluev/chute"),
        ("LinkedIn", "in/valuev", "https://www.linkedin.com/in/valuev/"),
        ("Telegram", "@asnkt", "https://t.me/asnkt"),
    ]

    public static let contactHeading = "Talk to the person who made it"

    public static let contactLead =
        "One person, European hours, no support tier. A bug is best filed with Report a Problem — "
        + "it attaches a redacted diagnostic and opens a prefilled issue. Anything else, these "
        + "three reach me."

    public static let privacy = """
        Chute contains no network code at all: no account, no telemetry, no licence server, no \
        launch daemon.

        One command uploads, and only when you run it. `chute gist` shells out to your own `gh`, \
        with your own GitHub credentials, on the files you name, after redacting keys and tokens. \
        Chute itself never opens a socket.
        """
}
