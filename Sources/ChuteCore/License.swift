import Foundation
import CryptoKit

/// Offline licence verification. There is no network call here, and there must never be one.
///
/// "Offline, no account, zero telemetry" is the product's position, and a licence check that
/// phones home would quietly contradict it — the one claim a buyer cannot verify is the one that
/// has to be true. So the whole licence travels inside the key: an Ed25519 signature over
/// `email|issuedAt`, checked against a public key compiled into this binary. The private half
/// lives in a Cloudflare Worker secret and is never in this repo.
///
/// A key is: `CHUTE-` + base64( signature(64 bytes) || "email|issuedAtEpoch" ).
/// Base64 rather than a hand-rolled base32: keys are pasted from an email, never typed, so
/// readability buys nothing and Foundation already does base64 in one line.
///
/// This is an honesty check, not DRM. The source is MIT and the check is thirty lines, so anyone
/// determined can remove it. At $19 that is not the constraint — obscurity is.
public struct LicenseInfo: Equatable, Sendable {
    public let email: String
    public let issued: Date
    public init(email: String, issued: Date) { self.email = email; self.issued = issued }
}

public enum License {
    /// Replaced by the real one before the first release. `node worker/keygen.mjs new` prints it.
    /// The matching private key is a Worker secret; if this constant is ever wrong, every key
    /// stops verifying at once, which is why LicenseSuite pins a known-good key against it.
    public static let productionPublicKey = "REPLACE_ME_BEFORE_RELEASE"

    public static let prefix = "CHUTE-"
    private static let signatureBytes = 64

    /// Nil for anything that is not a genuine key. Never throws and never explains WHY a key
    /// failed: a verifier that reports "bad signature" versus "bad format" is a free oracle.
    public static func verify(_ raw: String, publicKey: String = productionPublicKey) -> LicenseInfo? {
        // People paste keys out of email clients, which wrap long lines and add stray spaces.
        // Refusing a key over a newline the user cannot see is a support ticket, not security.
        let cleaned = raw.filter { !$0.isWhitespace }
        guard cleaned.hasPrefix(prefix) else { return nil }
        guard let blob = Data(base64Encoded: String(cleaned.dropFirst(prefix.count))),
              blob.count > signatureBytes else { return nil }

        let signature = blob.prefix(signatureBytes)
        let payload = blob.dropFirst(signatureBytes)

        guard let keyData = Data(base64Encoded: publicKey),
              let verifier = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData),
              verifier.isValidSignature(signature, for: payload) else { return nil }

        // Only parsed AFTER the signature holds, so a forged payload is never even read.
        //
        // Split at the LAST pipe, not on every pipe. `|` is a legal RFC 5322 atext character, so
        // `a|b@example.com` is a real address, and neither the Worker nor keygen escapes it —
        // they just concatenate `email|issuedAt`. Splitting on all of them gave that customer
        // three fields and a key that was correctly signed, correctly minted, and rejected
        // forever, with no message explaining why. Only `issuedAt` is guaranteed pipe-free, so
        // only the last separator is meaningful.
        guard let sep = payload.lastIndex(of: UInt8(ascii: "|")) else { return nil }
        let emailBytes = payload[payload.startIndex..<sep]
        let epochBytes = payload[payload.index(after: sep)...]
        guard !emailBytes.isEmpty,
              let epoch = TimeInterval(String(decoding: epochBytes, as: UTF8.self))
        else { return nil }
        return LicenseInfo(email: String(decoding: emailBytes, as: UTF8.self),
                           issued: Date(timeIntervalSince1970: epoch))
    }

    /// What to show in Settings — never the whole key, which people screenshot when asking for help.
    public static func masked(_ raw: String) -> String {
        let cleaned = raw.filter { !$0.isWhitespace }
        guard cleaned.count > prefix.count + 12 else { return cleaned }
        return prefix + cleaned.dropFirst(prefix.count).prefix(6) + "…" + cleaned.suffix(6)
    }
}
