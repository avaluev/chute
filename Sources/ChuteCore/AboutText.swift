import Foundation

/// THE WORDS IN THE ABOUT TAB, where a test can read them.
///
/// They lived in `Sources/ChuteApp/SettingsWindow.swift`, which `chutetests` cannot link, and for
/// weeks they said: *"Nothing is uploaded, ever, except by the `gist` command."* The first half of
/// that sentence is a string `docs/FACT-SHEET.md` has forbidden in bold since 2026-08-28 —
/// because `gist` uploads — and the site, the README and every marketing file are swept for it on
/// every deploy. Nobody had ever swept the app, which is the one place a PAYING CUSTOMER reads it.
///
/// The replacement is the fact sheet's own phrasing, word for word. It is longer than the absolute
/// version and it is more convincing, because a reader can check every clause of it against the
/// source in one grep.
public enum AboutText {
    /// A SECTION IS A HEADING AND ITS PROSE, and the heading is optional because the build stamp
    /// has none. Rendered flat, the tab was five grey paragraphs between two bold lines — the
    /// reader had no way to find the one they wanted without reading all of it, and the ask at the
    /// bottom read as a sixth paragraph rather than as the one thing the tab wants from them.
    public typealias Section = (heading: String?, text: String)

    public static func about(version: String, build: String?) -> (heading: String, body: [Section]) {
        var body: [Section] = []
        // The build stamp is what a bug report needs and what nobody remembers to ask for. No
        // heading: it belongs to the version line above it, not to a section of its own.
        if let build { body.append((nil, "build \(build)")) }
        // ORDER MATTERS: why, then privacy, then the ask — a reader meets the person before the
        // spec sheet, and meets the spec sheet before being asked for anything.
        body.append((whyHeading, why))
        body.append((privacyHeading, privacy))
        body.append((starHeading, starReason))
        return ("Chute \(version)", body)
    }

    public static let whyHeading = "Why this exists"
    public static let privacyHeading = "What it does with your data"
    /// NOT "Support the project". The heading is the condition, not the request — the sentence
    /// under it argues that the click is earned, and a heading that assumed the answer would
    /// undercut it before it was read.
    public static let starHeading = "If it earned it"

    /// THE OPENING. Everything below this line used to be the whole tab — accurate and written by
    /// nobody in particular. This is written by the one person who built it, in first person,
    /// because a spec sheet answers "what does it do" and never "why does this exist".
    public static let why = """
        I run five to thirteen coding agents at once. Every terminal tab looks identical, and the \
        one that stopped twenty minutes ago to ask a yes-or-no question looks exactly like the one \
        that is still working. I was losing hours to tabs that had been finished for a while and \
        had no way to say so.

        Chute answers one question, asked forty times a day: which one needs me. It does not \
        summarise your code, rank your agents, or have an opinion about your work. It reads what \
        your agents already write down, and puts it where you can see it without switching windows.
        """

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

    /// THE ONE ASK THE APP MAKES.
    ///
    /// The strongest true reason to ask was already sitting in `privacy`, above: Chute has no
    /// analytics, no account and no telemetry, so a star is the only signal the author ever gets
    /// that this was worth building. `starReason` restates that same fact as the argument for the
    /// click — a reader can check it against the paragraph they just read, so this is a reason,
    /// not an invented marketing line.
    ///
    /// A REAL BUTTON, not a fourth `linkField` row: the three contact rows above are for reaching
    /// a person, this is a call to action, and it should not read as a fourth way to talk to one.
    /// `starURL` is a `URL`, not a `String`, so `SettingsWindow`'s click handler needs no `guard`
    /// and no force-unwrap — that file is held to a hard cap on decision points.
    public static let starReason =
        "Chute has no analytics, no account and no telemetry — which means a star is the only "
        + "signal I ever get that this was worth building. It costs you a click."

    public static let starTitle = "★ Star Chute on GitHub"
    public static let starURL = URL(string: "https://github.com/avaluev/chute")!
}
