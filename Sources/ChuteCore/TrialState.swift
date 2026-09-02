import Foundation

/// The 14-day trial, and the licence that ends it.
///
/// The CLI is MIT and free forever; this governs Chute.app only — the Finder menu, the menu-bar
/// switcher, the hotkey. `Scripts/install.sh` symlinks ~/.local/bin/chute out of the app bundle,
/// so nothing here may ever be reachable from the `chute` executable. It is used by ChuteApp and
/// nowhere else.
///
/// The sandboxed Finder extension deliberately does NOT check this. It only writes a request to
/// ~/.chute/requests; ChuteApp executes it, so ChuteApp is the single gate. One place to get the
/// gating right, and no licence logic inside a sandbox.
public enum TrialState: Equatable, Sendable {
    case trial(daysLeft: Int)
    case expired
    case licensed(email: String)

    public var isUnlocked: Bool {
        switch self {
        case .expired: return false
        case .trial, .licensed: return true
        }
    }
}

/// What is on disk. `lastSeen` exists only to catch a clock moved backwards.
public struct TrialRecord: Codable, Equatable, Sendable {
    public var firstRun: Date
    public var lastSeen: Date
    public var licenseKey: String?

    public init(firstRun: Date, lastSeen: Date, licenseKey: String? = nil) {
        self.firstRun = firstRun; self.lastSeen = lastSeen; self.licenseKey = licenseKey
    }
}

public enum Trial {
    public static let lengthInDays = 14

    /// Application Support, not ~/.chute: ~/.chute is CLI runtime state that a user may
    /// reasonably delete, and deleting it should not silently restart a paid app's trial.
    ///
    /// Deleting THIS file does restart the trial. That is a deliberate ceiling, not an oversight
    /// — the alternative is a Keychain item, which re-prompts after every re-signing and turns a
    /// $19 utility into a support queue. Piracy is not the constraint at this price; obscurity is.
    /// Stays `public` although its only caller is in this file: it is the default-argument
    /// expression of PUBLIC functions below, and Swift resolves those at every call site — an
    /// internal symbol there does not compile. Audited 2026-09-01, do not narrow again.
    public static func recordPath(home: String = "/Users/" + NSUserName()) -> String {
        home + "/Library/Application Support/Chute/trial.json"
    }

    /// PURE, and the only part worth testing. `verify` is injected so the suite never needs the
    /// production public key.
    public static func evaluate(_ record: TrialRecord?,
                                now: Date,
                                length: Int = lengthInDays,
                                verify: (String) -> LicenseInfo? = { License.verify($0) }) -> TrialState {
        guard let record else { return .trial(daysLeft: length) }   // nothing on disk yet: day zero

        if let key = record.licenseKey, let info = verify(key) {
            return .licensed(email: info.email)
        }

        // A clock moved backwards must never hand out free days. The furthest-forward moment ever
        // observed wins, so setting the date to last month does nothing.
        let effectiveNow = max(now, record.lastSeen)
        let elapsed = effectiveNow.timeIntervalSince(record.firstRun)
        let daysUsed = Int(floor(elapsed / 86_400))
        let left = length - daysUsed
        return left > 0 ? .trial(daysLeft: left) : .expired
    }

    // MARK: - Disk

    public static func load(path: String = recordPath()) -> TrialRecord? {
        guard let data = FileManager.default.contents(atPath: path) else { return nil }
        return try? JSONDecoder().decode(TrialRecord.self, from: data)
    }

    @discardableResult
    public static func save(_ record: TrialRecord, path: String = recordPath()) -> Bool {
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(record) else { return false }
        return (try? data.write(to: URL(fileURLWithPath: path), options: .atomic)) != nil
    }

    /// Read the record, stamp `lastSeen` forward, write it back, and say where things stand.
    /// Called once when ChuteApp launches and whenever the menu opens.
    public static func touch(now: Date = Date(), path: String = recordPath()) -> TrialState {
        var record = load(path: path) ?? TrialRecord(firstRun: now, lastSeen: now)
        record.lastSeen = max(record.lastSeen, now)
        save(record, path: path)
        return evaluate(record, now: now)
    }

    /// Store a key only if it actually verifies — an unverifiable key on disk would read as
    /// licensed on the next launch if evaluate() ever stopped re-checking.
    public static func activate(_ key: String, path: String = recordPath(),
                                now: Date = Date(),
                                verify: (String) -> LicenseInfo? = { License.verify($0) }) -> LicenseInfo? {
        guard let info = verify(key) else { return nil }
        var record = load(path: path) ?? TrialRecord(firstRun: now, lastSeen: now)
        record.licenseKey = key.filter { !$0.isWhitespace }
        record.lastSeen = max(record.lastSeen, now)
        // A key that verified but did not reach the disk is not an activation: the pane said
        // "Licensed to …", and the next launch was back to expired.
        guard save(record, path: path) else { return nil }
        return info
    }

    /// How many days are left before the trial line is worth a menu row at all.
    ///
    /// The rule this file already stated — a paid app that keeps mentioning payment is nagging its
    /// own customer — does not start applying on the day someone pays. Fourteen reminders over
    /// fourteen days is fourteen chances to find the menu slightly annoying, and the first eleven
    /// of them cannot change a decision nobody is making yet. The last few can.
    ///
    /// Settings → License always shows the real state, on every day, for anyone who wants to look.
    public static let menuWarningDays = 3

    /// One line for the menu, or nil for the days it should stay quiet. Silent when licensed;
    /// silent for most of the trial; never silent once it has actually run out.
    public static func menuLabel(_ state: TrialState) -> String? {
        switch state {
        case .licensed: return nil
        case .expired: return "Buy Chute — $19 one-time"
        case .trial(let days):
            guard days <= menuWarningDays else { return nil }
            return days == 1 ? "Trial — last day" : "Trial — \(days) days left"
        }
    }
}
