import Foundation

public struct ShellResult: Sendable {
    public let out: String
    public let err: String
    public let code: Int32
    public var ok: Bool { code == 0 }
}

/// NFR-11 — every external tool is optional; a missing one is a message, never a crash.
public enum Shell {
    @discardableResult
    public static func run(_ tool: String, _ args: [String],
                           cwd: String? = nil, input: String? = nil,
                           env: [String: String] = [:]) -> ShellResult {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = [tool] + args
        if let cwd { p.currentDirectoryURL = URL(fileURLWithPath: cwd) }
        if !env.isEmpty {
            var merged = ProcessInfo.processInfo.environment
            env.forEach { merged[$0.key] = $0.value }
            p.environment = merged
        }
        let o = Pipe(), e = Pipe(), i = Pipe()
        p.standardOutput = o; p.standardError = e; p.standardInput = i
        do { try p.run() } catch {
            return ShellResult(out: "", err: "cannot run \(tool): \(error.localizedDescription)", code: 127)
        }
        if let input { i.fileHandleForWriting.write(Data(input.utf8)) }
        i.fileHandleForWriting.closeFile()
        let od = o.fileHandleForReading.readDataToEndOfFile()
        let ed = e.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return ShellResult(out: String(decoding: od, as: UTF8.self),
                           err: String(decoding: ed, as: UTF8.self),
                           code: p.terminationStatus)
    }

    public static func which(_ tool: String) -> String? {
        let r = run("which", [tool])
        let path = r.out.trimmingCharacters(in: .whitespacesAndNewlines)
        return r.ok && !path.isEmpty ? path : nil
    }

    /// Fire-and-forget GUI launch (`open -a`, `osascript`) — we do not wait on the app.
    public static func launch(_ tool: String, _ args: [String]) {
        _ = run(tool, args)
    }
}

public enum Clipboard {
    public static func read() -> String { Shell.run("pbpaste", []).out }

    public static func write(_ s: String) {
        _ = Shell.run("pbcopy", [], input: s)
    }
}
