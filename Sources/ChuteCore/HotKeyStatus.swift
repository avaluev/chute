import Foundation

/// The one sentence a failed ⌥⌘N registration gets. `RegisterEventHotKey` returns an `OSStatus`
/// the app used to discard, so a shortcut owned by another app was dead with no way to find out.
public enum HotKeyStatus {
    static let hotKeyExists: Int32 = -9878   // eventHotKeyExistsErr

    public static func problem(_ status: Int32) -> String? {
        switch status {
        case 0:            return nil
        case hotKeyExists: return "⌥⌘N is already taken by another app — Chute's session switcher will not open from the keyboard"
        default:           return "⌥⌘N could not be registered (OSStatus \(status)) — the session switcher will not open from the keyboard"
        }
    }
}
