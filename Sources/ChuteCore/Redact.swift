import Foundation

/// FR-19 — never let a key reach a screenshot, an issue tracker, or a teammate's DM.
public enum Redact {
    static let patterns = [
        #"sk-ant-[A-Za-z0-9_\-]{16,}"#,
        #"sk-[A-Za-z0-9_\-]{20,}"#,
        #"gh[pousr]_[A-Za-z0-9]{16,}"#,
        // GitHub's FINE-GRAINED tokens. A different prefix from the classic five above, so the
        // `gh[pousr]_` pattern never saw them — and they are the default GitHub now issues.
        #"github_pat_[A-Za-z0-9_]{20,}"#,
        // ASIA = a temporary STS credential. Just as live as AKIA for as long as it lasts.
        #"(?:AKIA|ASIA)[0-9A-Z]{16}"#,
        // Stripe. `sk_` is the secret key and `rk_` a restricted one; both spend money.
        // `pk_` is publishable by design and is deliberately NOT matched.
        #"(?:sk|rk)_(?:live|test)_[A-Za-z0-9]{16,}"#,
        #"(?i)bearer\s+[A-Za-z0-9._\-]{12,}"#,
        #"eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{5,}"#,
        #"xox[baprs]-[A-Za-z0-9\-]{10,}"#,
        #"AIza[A-Za-z0-9_\-]{30,}"#,
        // A private key pasted into an issue is the worst single leak this tool could allow.
        #"(?s)-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----"#,
    ]

    /// Credentials inside a URL — postgres://user:hunter2@db/app — which no key-shaped pattern
    /// catches because the secret is just a word between a colon and an @.
    ///
    /// The username may be EMPTY: `redis://:hunter2@cache:6379` is the ordinary shape for Redis,
    /// and requiring at least one username character walked straight past it.
    static let urlCredentials = #"://[^\s:/@]*:[^\s/@]+@"#

    /// A `.env` line. Case-insensitive on the key: `(?m)^[A-Z0-9_]*` matched `API_KEY=` but not
    /// `api_key=`, and dotenv does not care which you write.
    static let envAssignment =
        #"(?im)^([A-Za-z0-9_]*(?:KEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL)[A-Za-z0-9_]*)\s*=\s*\S+"#

    /// The same secret NOT at the start of a line — the semicolon-delimited connection string
    /// (`Server=db;Uid=root;Pwd=hunter2;`) that `envAssignment`'s `^` anchor could never reach,
    /// and any inline `password=` in prose or a command line. Deliberately broad: this tool
    /// exists to be pasted into an issue, where over-redacting costs a follow-up question and
    /// under-redacting costs a rotated credential.
    ///
    /// The value class stops at whitespace, `;` and `&` — and NOT at a quote. It used to exclude
    /// `"` and `'` too, so `export TOKEN="ghs_…"` and `-e MYSQL_ROOT_PASSWORD="hunter2"` walked
    /// straight past: the `+` failed on the opening quote and nothing was masked, then `chute
    /// gist` uploaded it. Quoting a value is the ordinary way to write one. And the key may carry
    /// a prefix: `-e MYSQL_ROOT_PASSWORD=hunter2` has no word boundary before PASSWORD.
    static let inlineAssignment =
        #"(?i)\b([a-z0-9_]*(?:pwd|password|passwd|secret|token|api[_-]?key))\s*=\s*[^\s;&]+"#

    public static func apply(_ text: String) -> String {
        var out = text
        for p in patterns {
            out = out.replacingOccurrences(of: p, with: "[REDACTED]", options: .regularExpression)
        }
        out = out.replacingOccurrences(of: urlCredentials, with: "://[REDACTED]@",
                                       options: .regularExpression)
        out = out.replacingOccurrences(of: envAssignment, with: "$1=[REDACTED]",
                                       options: .regularExpression)
        return out.replacingOccurrences(of: inlineAssignment, with: "$1=[REDACTED]",
                                        options: .regularExpression)
    }
}
