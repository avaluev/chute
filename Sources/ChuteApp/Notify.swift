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
    /// Set when macOS last told us notifications are off. The menu reads it to offer the fix.
    /// Written ONLY via `setDenied` (a main-queue hop): the writers below run on
    /// UNUserNotificationCenter's own queue, and the reader is the main-thread menu build —
    /// without the hop this is an unsynchronised cross-thread mutation that `nonisolated(unsafe)`
    /// merely silences.
    nonisolated(unsafe) static var deniedAtLastCheck = false

    private static func setDenied(_ value: Bool) {
        DispatchQueue.main.async { deniedAtLastCheck = value }
    }

    /// Where the app leaves its notification state, so `chute doctor --report` can explain a
    /// silence that is otherwise invisible from outside the app.
    static func record(_ state: String) {
        try? state.write(toFile: (NSHomeDirectory() as NSString)
                            .appendingPathComponent(".chute/notifications.txt"),
                         atomically: true, encoding: .utf8)
    }

    /// The System Settings pane for THIS app's notifications, not the general list.
    static var settingsURL: URL {
        URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=dev.valuev.chute")!
    }

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
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                setDenied(false)
                record("on")
                deliver(title: title, subtitle: subtitle, body: body)

            case .notDetermined:
                // Never asked, or the prompt was dismissed without an answer. Ask now and post the
                // notification the moment permission arrives, rather than falling back to
                // osascript — which is what put a Script Editor pen icon on Chute's banners.
                UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound]) { granted, error in
                        if let error {
                            NSLog("ChuteApp: notification authorization failed: %@",
                                  error.localizedDescription)
                        }
                        granted ? deliver(title: title, subtitle: subtitle, body: body)
                                : fallback(title: title, body: body)
                    }

            case .denied:
                // A denial is the user's decision and osascript would route around it — which is
                // exactly how Chute's banners ended up arriving as Script Editor, with a pen icon
                // and a Show button that opened Script Editor. So: do not fake it. Record the
                // state instead, and let the menu offer to fix it.
                setDenied(true)
                record("off")
                NSLog("ChuteApp: notifications are turned off for Chute in System Settings")

            @unknown default:
                fallback(title: title, body: body)
            }
        }
    }

    /// What the notification system currently thinks, for diagnostics — a banner arriving with the
    /// wrong icon is otherwise unexplainable from the outside.
    static func statusDescription(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized:   return "allowed"
        case .provisional:  return "allowed quietly"
        case .ephemeral:    return "allowed for now"
        case .denied:       return "turned off in System Settings → Notifications → Chute"
        case .notDetermined: return "never asked"
        @unknown default:   return "unknown"
        }
    }

    private static func deliver(title: String, subtitle: String?, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle { content.subtitle = subtitle }
        content.body = body

        // Delivery is not display. Measured 2026-08-28: this app hands the request to
        // UNUserNotificationCenter in 4 ms — but a Focus mode, a Scheduled Summary or an alert
        // style of "None" can then hold the banner for minutes, which is exactly what was
        // reported. `.timeSensitive` is the one lever an app has: it breaks through Focus and is
        // never rolled into a summary.
        //
        // It needs com.apple.developer.usernotifications.time-sensitive, which needs the Developer
        // ID that does not exist yet. Setting it without the entitlement is SAFE — macOS silently
        // treats it as .active — so it is set now and starts working the day the app is signed
        // properly, rather than being a thing someone has to remember later.
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                NSLog("ChuteApp: native notification refused: %@", error.localizedDescription)
                fallback(title: title, body: body)
            } else {
                NSLog("ChuteApp: delivered natively")
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

/// Tell the user something finished — on EXACTLY ONE surface.
///
/// It used to be two, deliberately: the HUD for "did that work?" and a Notification Centre banner
/// as the durable record. In practice that is one action reported twice, seconds apart, and the
/// second arrival reads as a bug rather than as scrollback. Reported 2026-08-28: "full duplicated
/// notification: old and new one."
///
/// So the panel wins, because it is the one that cannot be delayed. Measured against the unified
/// log, handing a request to UNUserNotificationCenter takes 4 ms — but delivery is not display,
/// and a Focus mode, a Scheduled Summary or an alert style of "None" can hold the banner for
/// minutes. The HUD obeys none of those, needs no permission, and appears in the same run loop
/// turn as the result.
///
/// The notification is now the FALLBACK and nothing else: it is posted only where the HUD cannot
/// draw — no window server, no `NSApp`, `CHUTE_HEADLESS=1`. `ResultHUD.show` returning false is
/// the single condition, so there is one code path and no way for both to fire.
///
/// Called from background queues; AppKit windows are main-thread-only, so the whole decision hops
/// to the main thread rather than only the drawing.
func notify(_ title: String, _ body: String) {
    DispatchQueue.main.async {
        if ResultHUD.show(body) {
            // `chute doctor --report` reads this file. Without the write it would keep reporting
            // whatever the last pre-HUD build left there, and a stale diagnostic is worse than
            // none — it is the file someone consults when a user says "nothing tells me anything".
            Notify.record("on-screen")
            return
        }
        Notify.post(title: "Chute", subtitle: title == "Chute" ? nil : title, body: body)
    }
}
