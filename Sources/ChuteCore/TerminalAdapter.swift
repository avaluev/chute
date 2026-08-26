import Foundation

public enum TerminalError: Error, CustomStringConvertible {
    case notRunning(String)
    case scriptFailed(String)
    case timedOut

    public var description: String {
        switch self {
        case .notRunning(let app): return "\(app) is not running"
        case .scriptFailed(let m):  return "AppleScript failed: \(m)"
        case .timedOut:             return "the terminal did not respond in time"
        }
    }
}

public protocol TerminalAdapter {
    var kind: TerminalKind { get }
    func discover(hooks: [String: HookRecord], now: Date) throws -> [Session]
    func focus(_ session: Session) throws
}
