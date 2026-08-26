import Foundation

/// Minimal assert harness. No framework, no fixtures — exits non-zero if anything fails.
enum T {
    nonisolated(unsafe) static var passed = 0
    nonisolated(unsafe) static var failures: [String] = []
    nonisolated(unsafe) static var current = ""

    static func suite(_ name: String, _ body: () -> Void) { current = name; body() }

    static func check(_ ok: Bool, _ label: String, _ detail: @autoclosure () -> String = "",
                      _ line: Int = #line) {
        if ok { passed += 1 }
        else { failures.append("\(current) › \(label) (line \(line)) \(detail())") }
    }

    static func eq<V: Equatable>(_ a: V, _ b: V, _ label: String, _ line: Int = #line) {
        check(a == b, label, "\n      got:      \(a)\n      expected: \(b)", line)
    }

    static func ok(_ v: Bool, _ label: String, _ line: Int = #line) { check(v, label, "", line) }
    static func no(_ v: Bool, _ label: String, _ line: Int = #line) { check(!v, label, "", line) }

    static func throwsError(_ label: String, _ line: Int = #line, _ body: () throws -> Void) {
        do { try body(); check(false, label, "expected a thrown error, got none", line) }
        catch { check(true, label, "", line) }
    }

    static func noThrow(_ label: String, _ line: Int = #line, _ body: () throws -> Void) {
        do { try body(); check(true, label, "", line) }
        catch { check(false, label, "unexpected error: \(error)", line) }
    }

    static func report() -> Never {
        if failures.isEmpty {
            print("✅ \(passed) assertions passed")
            exit(0)
        }
        print("❌ \(failures.count) failed, \(passed) passed\n")
        failures.forEach { print("  • \($0)") }
        exit(1)
    }
}
