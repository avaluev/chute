import Foundation

/// The home directory, honouring `$HOME`.
///
/// `NSHomeDirectory()` reads the password database and IGNORES the environment. Verified on
/// 2026-09-03: with `HOME` set to a fresh temp directory it still returned `/Users/<user>`.
///
/// That is not a curiosity, it is a hole in the test suite. `Scripts/smoke.sh` isolates three
/// cases with `HOME="$T"` so they cannot see the developer's real agent sessions — and every one
/// of those isolations was doing nothing. "resume with no live session fails gracefully" passed
/// for years for the wrong reason: the machine simply had no hook records. The hour Chute's hooks
/// were finally wired on that machine, it failed, because `chute resume` went and read the real
/// `~/.chute/sessions` straight through the redirect.
///
/// A test that cannot isolate is a test that passes until the day it matters. So the `.chute`
/// state directories resolve through here, where `$HOME` wins — which is also what every other
/// command-line tool on the machine does, and what anyone setting `HOME=` plainly intends.
///
/// NOT used by `ActionRequest`: inside the Finder extension the home directory is the sandbox
/// container, and that file already documents why it must not ask for it this way.
public enum Home {
    public static var path: String {
        ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
    }

    /// `~/.chute/<name>`, honouring `$HOME`.
    public static func chute(_ name: String) -> String {
        (path as NSString).appendingPathComponent(".chute/\(name)")
    }
}
