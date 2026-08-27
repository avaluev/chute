import AppKit
import ChuteCore
import UserNotifications

/// Native notifications, posted by this app under its own name and icon.
///
/// The previous implementation shelled out to `osascript`, so every banner arrived attributed to
/// **Script Editor** — wrong name, wrong icon, and a "Show" button that opened Script Editor.
/// `UNUserNotificationCenter` posts as Chute. If the user has denied notifications, or the API is
/// unavailable, it falls back to the old path rather than going silent.
enum Notify {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error { NSLog("ChuteApp: notification authorization failed: %@", error.localizedDescription) }
        }
    }

    /// Authorization is read fresh every time, never cached: the user may grant it in System
    /// Settings long after launch, and a cached "denied" would pin every banner to the ugly
    /// osascript fallback for the rest of the session.
    static func post(title: String, subtitle: String?, body: String) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else {
                return fallback(title: title, body: body)
            }
            deliver(title: title, subtitle: subtitle, body: body)
        }
    }

    private static func deliver(title: String, subtitle: String?, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle { content.subtitle = subtitle }
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                NSLog("ChuteApp: native notification refused: %@", error.localizedDescription)
                fallback(title: title, body: body)
            }
        }
    }

    /// The body is whatever the command said, and a command's output can contain a file name the
    /// user did not choose. Backslash FIRST: escaping quotes alone leaves a trailing backslash to
    /// escape the closing quote, and everything after it is then read as AppleScript, not text.
    private static func fallback(title: String, body: String) {
        func escape(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "'")
        }
        Shell.launch("osascript", ["-e",
            "display notification \"\(escape(body))\" with title \"\(escape(title))\""])
    }
}

func notify(_ title: String, _ body: String) {
    Notify.post(title: "Chute", subtitle: title == "Chute" ? nil : title, body: body)
}
