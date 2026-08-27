import Foundation

/// FR-19 — never let a key reach a screenshot, an issue tracker, or a teammate's DM.
public enum Redact {
    static let patterns = [
        #"sk-ant-[A-Za-z0-9_\-]{16,}"#,
        #"sk-[A-Za-z0-9_\-]{20,}"#,
        #"gh[pousr]_[A-Za-z0-9]{16,}"#,
        #"AKIA[0-9A-Z]{16}"#,
        #"(?i)bearer\s+[A-Za-z0-9._\-]{12,}"#,
        #"eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{5,}"#,
        #"xox[baprs]-[A-Za-z0-9\-]{10,}"#,
        #"AIza[A-Za-z0-9_\-]{30,}"#,
        // A private key pasted into an issue is the worst single leak this tool could allow.
        #"(?s)-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----"#,
    ]

    /// Credentials inside a URL — postgres://user:hunter2@db/app — which no key-shaped pattern
    /// catches because the secret is just a word between a colon and an @.
    static let urlCredentials = #"://[^\s:/@]+:[^\s/@]+@"#

    static let envAssignment =
        #"(?m)^([A-Z0-9_]*(?:KEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL)[A-Z0-9_]*)\s*=\s*\S+"#

    public static func apply(_ text: String) -> String {
        var out = text
        for p in patterns {
            out = out.replacingOccurrences(of: p, with: "[REDACTED]", options: .regularExpression)
        }
        out = out.replacingOccurrences(of: urlCredentials, with: "://[REDACTED]@",
                                       options: .regularExpression)
        return out.replacingOccurrences(of: envAssignment, with: "$1=[REDACTED]",
                                        options: .regularExpression)
    }
}
