import Foundation
import ChuteCore

/// A TEST keypair. It was generated in a chat transcript, so it is public by construction and
/// must never be the production pair. The production public key lives in License.swift and its
/// private half never leaves a Cloudflare Worker secret.
private let testPublicKey = "DbB2zuunvYsr3xK4HKS2J8Duijd+aqhAaEN/IR9v/aM="

/// Minted with `node worker/keygen.mjs mint <test-private> buyer@example.com` at a fixed
/// issue time, so this string is stable and the suite never needs node to run.
private let validKey =
  "CHUTE-DwJikdIodhy2hAcsaLaEeP+ckcmwImsTV3YRb0uk9ynTmbEwOpkvDIgY4Z/k3c0JJAVuz0fIo4qFODqbzEkyCGJ1eWVyQGV4YW1wbGUuY29tfDE3NjcyMjU2MDA="

private func verifyTest(_ k: String) -> LicenseInfo? { License.verify(k, publicKey: testPublicKey) }

func licenseSuite() {
    T.suite("License") {
        // The happy path, pinned. If this breaks, every key ever issued has stopped working.
        let info = verifyTest(validKey)
        T.eq(info?.email, "buyer@example.com", "a genuine key yields the buyer's email")
        T.eq(info?.issued, Date(timeIntervalSince1970: 1_767_225_600), "and the date it was issued")

        // PERTURBATION 1 — a tampered payload. Done on the DECODED bytes, not by guessing at a
        // substring of the base64: the payload starts at byte 64, which is not a multiple of 3,
        // so the email is not base64-aligned and a textual search for it finds nothing.
        var bytes = [UInt8](Data(base64Encoded: String(validKey.dropFirst(License.prefix.count)))!)
        bytes[70] ^= 0x01                                  // one bit, inside the email
        let forged = License.prefix + Data(bytes).base64EncodedString()
        T.ok(verifyTest(forged) == nil, "one flipped bit in the payload invalidates the key")

        // And the same bit flipped inside the SIGNATURE rather than the payload.
        var resigned = [UInt8](Data(base64Encoded: String(validKey.dropFirst(License.prefix.count)))!)
        resigned[10] ^= 0x01
        T.ok(verifyTest(License.prefix + Data(resigned).base64EncodedString()) == nil,
             "one flipped bit in the signature invalidates the key")

        // PERTURBATION 2 — the right key against the wrong public key. This is what a leaked
        // key from someone else's product would look like.
        T.ok(License.verify(validKey, publicKey: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=") == nil,
             "a key does not verify against a different public key")

        // Shapes that must never crash and never pass.
        for junk in ["", "CHUTE-", "CHUTE-!!!!", "nonsense", "CHUTE-QUJD",
                     String(validKey.dropLast(20)), validKey.replacingOccurrences(of: "CHUTE-", with: "")] {
            T.ok(verifyTest(junk) == nil, "rejected: '\(junk.prefix(18))'")
        }

        // Email clients wrap long lines. Refusing a key over a newline the user cannot see is a
        // support ticket, not security.
        T.ok(verifyTest("CHUTE-\n" + validKey.dropFirst(6)) != nil, "a wrapped key still verifies")
        T.ok(verifyTest("  " + validKey + "  ") != nil, "surrounding whitespace is ignored")

        T.ok(License.masked(validKey).hasPrefix("CHUTE-"), "the masked form keeps the prefix")
        T.ok(!License.masked(validKey).contains("JJAVuz0"), "and hides the middle of the key")
    }

    T.suite("Trial") {
        let start = Date(timeIntervalSince1970: 1_767_225_600)
        let day = 86_400.0
        let fresh = TrialRecord(firstRun: start, lastSeen: start)

        T.eq(Trial.evaluate(nil, now: start, verify: verifyTest), .trial(daysLeft: 14),
             "no record at all is day zero, not an expired trial")
        T.eq(Trial.evaluate(fresh, now: start, verify: verifyTest), .trial(daysLeft: 14),
             "the first launch has the full fourteen days")
        T.eq(Trial.evaluate(fresh, now: start + day, verify: verifyTest), .trial(daysLeft: 13),
             "a day spent is a day gone")
        T.eq(Trial.evaluate(fresh, now: start + 13 * day, verify: verifyTest), .trial(daysLeft: 1),
             "day thirteen is the last day")

        // PERTURBATION 3 — the boundary. Fourteen days and one second must lock, and the day
        // before it must not. An off-by-one here either robs a buyer or gives the app away.
        T.eq(Trial.evaluate(fresh, now: start + 14 * day - 1, verify: verifyTest), .trial(daysLeft: 1),
             "one second before the end is still a trial")
        T.eq(Trial.evaluate(fresh, now: start + 14 * day, verify: verifyTest), .expired,
             "fourteen days exactly is expired")
        T.eq(Trial.evaluate(fresh, now: start + 400 * day, verify: verifyTest), .expired,
             "and it stays expired")

        // PERTURBATION 4 — the clock rolled back. The oldest trick there is.
        let used = TrialRecord(firstRun: start, lastSeen: start + 20 * day)
        T.eq(Trial.evaluate(used, now: start + day, verify: verifyTest), .expired,
             "moving the clock back to day one does NOT hand back the trial")
        T.eq(Trial.evaluate(TrialRecord(firstRun: start, lastSeen: start + 5 * day),
                            now: start + 2 * day, verify: verifyTest), .trial(daysLeft: 9),
             "a small rollback still counts the furthest day ever seen")

        // A licence outranks the clock, in both directions.
        let licensed = TrialRecord(firstRun: start, lastSeen: start, licenseKey: validKey)
        T.eq(Trial.evaluate(licensed, now: start + 900 * day, verify: verifyTest),
             .licensed(email: "buyer@example.com"), "a licence never expires")
        let bogus = TrialRecord(firstRun: start, lastSeen: start, licenseKey: "CHUTE-nonsense")
        T.eq(Trial.evaluate(bogus, now: start + 400 * day, verify: verifyTest), .expired,
             "an unverifiable key on disk does not unlock anything")

        T.ok(TrialState.trial(daysLeft: 3).isUnlocked, "a live trial is unlocked")
        T.no(TrialState.expired.isUnlocked, "an expired trial is not")
        T.ok(TrialState.licensed(email: "a@b.c").isUnlocked, "a licence is")

        // The menu line. Silent when licensed — a paid app that keeps mentioning payment is
        // nagging its own customer.
        T.eq(Trial.menuLabel(.licensed(email: "a@b.c")), nil, "a customer is never shown a price")
        T.eq(Trial.menuLabel(.trial(daysLeft: 9)), "Trial — 9 days left", "the count reads plainly")
        T.eq(Trial.menuLabel(.trial(daysLeft: 1)), "Trial — last day", "and the last day says so")
        T.eq(Trial.menuLabel(.expired), "Buy Chute — $19 one-time", "expiry states the price")

        // Round-trip through disk, in a temp directory — the suite shares a process, so it must
        // never touch the real ~/Library/Application Support/Chute.
        let tmp = NSTemporaryDirectory() + "chute-trial-\(UUID().uuidString)/trial.json"
        defer { try? FileManager.default.removeItem(atPath: (tmp as NSString).deletingLastPathComponent) }
        T.ok(Trial.load(path: tmp) == nil, "an absent record reads as nil, not a crash")
        T.ok(Trial.save(fresh, path: tmp), "the record writes")
        T.eq(Trial.load(path: tmp), fresh, "and reads back identical")
        T.ok(Trial.activate("CHUTE-rubbish", path: tmp, verify: verifyTest) == nil,
             "activating a bad key fails")
        T.ok(Trial.load(path: tmp)?.licenseKey == nil, "and stores nothing")
        T.eq(Trial.activate(validKey, path: tmp, verify: verifyTest)?.email, "buyer@example.com",
             "activating a good key succeeds")
        T.eq(Trial.evaluate(Trial.load(path: tmp), now: start + 900 * day, verify: verifyTest),
             .licensed(email: "buyer@example.com"), "and survives a reload")
    }
}
