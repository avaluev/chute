// SCREEN CAPTURE HARNESS — a FRAGMENT, appended into Sources/ChuteApp/main.swift inside a
// throwaway copy of the tree by Scripts/screens.sh. It is not compiled into the shipped app.
//
// ── WHY IT EXISTS ───────────────────────────────────────────────────────────────────────────
//
// On 2026-09-08 the menu was rendered to a PNG for the first time in the product's life, and the
// red square that means STOP and the green circle that means READY were not in it. `hole: 0` had
// never meant "filled"; under an evenOdd winding rule the same rect twice cancels the SHAPE. The
// code was branch-free, so the decision-point ratchet was green on it, and it lived in ChuteApp,
// so no assertion could import it. The only instrument that could ever have caught it was
// somebody looking — and until this file there was no cheap way to look.
//
// `SessionDotSuite` guards that specific bug now. This guards the class of it: everything about
// a menu that is only wrong to the eye — a column that does not line up, a truncation that eats
// the wrong end, two rows that read the same.
//
// ── WHY IT DRAWS RATHER THAN PHOTOGRAPHS ────────────────────────────────────────────────────
//
// `NSMenu.popUp` needs a real user session to track in; from a scripted launch it returns
// instantly and there is no menu window to capture. So each item is drawn here instead. Nothing
// about the CONTENT is reconstructed: every string is the `attributedTitle` that the real
// `SessionMenu.render` produced, every dot is its real `NSImage`, and the canvas is the menu's
// own `size.width`. Only AppKit's chrome — the vibrancy behind it, the highlight bar — is
// approximated, and neither carries any of the layout worth checking.
//
// The cast is mockup 2c's, so the output and the mockup can be laid side by side.
func shotNote(_ path: String, _ m: String) {
    if !FileManager.default.fileExists(atPath: path) {
        FileManager.default.createFile(atPath: path, contents: nil)
    }
    guard let h = FileHandle(forWritingAtPath: path) else { return }
    h.seekToEndOfFile(); h.write(Data((m + "\n").utf8)); h.closeFile()
}

/// THE CASTS. One per scenario worth looking at, because a screenshot of the everyday case
/// proves only that the everyday case works. Each is a claim about how the menu behaves when
/// something is unusual, and each renders through the REAL model and renderer.
///
/// Nothing here reads the founder's machine. These are fixtures — the harness must never
/// photograph real sessions, because a screenshot of a real menu carries real project names and
/// real paths into a marketing asset.
struct ShotRow {
    let tty: String, cwd: String?, agent: String?, state: SessionState
    let minutes: Double, title: String, detail: String
    /// THE TAB'S OWN TITLE — line 2 of column 1, which is what the product draws there now (see
    /// SessionTitle.swift). `title` above is only the project seed; these are the strings that
    /// tell four tabs in one directory apart, so every fixture carries its own. Empty is a real
    /// case and stays represented: Antigravity writes no usable title, and those rows have to be
    /// shown falling back to their tty rather than to a blank.
    let tab: String
    let cpu: Double, bytes: UInt64, peak: UInt64
}

func shotRows(_ name: String) -> [ShotRow] {
    // UNDER THE REAL HOME. PathAbbrev folds `$HOME` to `~`, so a fixture rooted at a made-up
    // /Users/x never exercises that rule — the first render of these cases showed
    // `/Users/x/…/37.chute/site` where the product would show `~/Documents/…/37.chute/site`,
    // and one row collapsed to `/…/site`, losing the component that identifies it. The project
    // NAMES below are still invented; only the root is real, so no actual work leaks into a
    // marketing asset.
    let H = Home.path
    switch name {
    // ── THE EVERYDAY CASE ───────────────────────────────────────────────────────────────────
    case "mixed": return [
        ShotRow(tty: "ttys001", cwd: H + "/Dev/37.sntz", agent: "claude", state: .blocked,
                minutes: 22, title: "sntz", detail: "Claude Code · Opus 5 · xhigh", tab: "✳ checkout flow rewrite",
                cpu: 177, bytes: 3_221_225_472, peak: 0),
        ShotRow(tty: "ttys002", cwd: H + "/Dev/28.tallyapp", agent: "codex", state: .blocked,
                minutes: 4, title: "tally", detail: "Codex · high", tab: "✳ ledger import fixtures",
                cpu: 12, bytes: 671_088_640, peak: 0),
        ShotRow(tty: "ttys003", cwd: H + "/Dev/37.chute", agent: "claude", state: .waiting,
                minutes: 3, title: "chute", detail: "Claude Code · Sonnet 5", tab: "◑ menu row columns",
                cpu: 4, bytes: 220_200_960, peak: 0),
        ShotRow(tty: "ttys004", cwd: H + "/Dev/studylock", agent: "claude", state: .waiting,
                minutes: 12, title: "studylock", detail: "Claude Code · Opus 5 · high", tab: "✳ pairing e2e flake",
                cpu: 1, bytes: 661_651_456, peak: 0),
        ShotRow(tty: "ttys005", cwd: H + "/Dev/37.sntz", agent: "claude", state: .working,
                minutes: 1, title: "sntz", detail: "Claude Code · Opus 5", tab: "◐ shot page fields",
                cpu: 40, bytes: 1_181_116_006, peak: 0),
        ShotRow(tty: "ttys006", cwd: H + "/Dev/37.sntz/site", agent: "claude", state: .working,
                minutes: 8, title: "sntz", detail: "Claude Code · Opus 5 · high", tab: "✳ site perf pass",
                cpu: 88, bytes: 2_576_980_378, peak: 6_549_723_444),
        ShotRow(tty: "ttys007", cwd: H + "/Dev/38.LifespanOS", agent: "agy", state: .unknown,
                minutes: 0, title: "lifespan", detail: "Antigravity", tab: "",
                cpu: 0, bytes: 230_686_720, peak: 0),
    ]

    // ── NOTHING NEEDS YOU. The state the product is trying to get you to. ───────────────────
    case "allclear": return [
        ShotRow(tty: "ttys001", cwd: H + "/Dev/37.chute", agent: "claude", state: .waiting,
                minutes: 2, title: "chute", detail: "Claude Code · Sonnet 5", tab: "✳ release notes",
                cpu: 1, bytes: 210_000_000, peak: 0),
        ShotRow(tty: "ttys002", cwd: H + "/Dev/studylock", agent: "claude", state: .waiting,
                minutes: 9, title: "studylock", detail: "Claude Code · Opus 5", tab: "◑ onboarding copy",
                cpu: 1, bytes: 380_000_000, peak: 0),
        ShotRow(tty: "ttys003", cwd: H + "/Dev/api-gateway", agent: "codex", state: .waiting,
                minutes: 31, title: "api", detail: "Codex", tab: "✳ rate limit tests",
                cpu: 0, bytes: 190_000_000, peak: 0),
    ]

    // ── THE 3AM CASE. Two cores pinned and nine gigabytes, on a machine gone slow. ──────────
    case "runaway": return [
        ShotRow(tty: "ttys001", cwd: H + "/Dev/37.sntz", agent: "claude", state: .working,
                minutes: 47, title: "sntz", detail: "Claude Code · Opus 5 · xhigh", tab: "◐ full media reencode",
                cpu: 312, bytes: 9_663_676_416, peak: 10_200_547_328),
        ShotRow(tty: "ttys002", cwd: H + "/Dev/37.chute", agent: "claude", state: .blocked,
                minutes: 63, title: "chute", detail: "Claude Code · Opus 5", tab: "✳ notarisation retry",
                cpu: 2, bytes: 410_000_000, peak: 0),
        ShotRow(tty: "ttys003", cwd: H + "/Dev/studylock", agent: nil, state: .idle,
                minutes: 0, title: "studylock", detail: "no agent running", tab: "",
                cpu: 0, bytes: 4_194_304, peak: 0),
    ]

    // ── AN UNINSTRUMENTED MACHINE. No hooks anywhere: it must read blind, never calm. ───────
    case "nohooks": return [
        ShotRow(tty: "ttys001", cwd: H + "/Dev/37.sntz", agent: "agy", state: .unknown,
                minutes: 0, title: "sntz", detail: "Antigravity", tab: "",
                cpu: 6, bytes: 166_000_000, peak: 0),
        ShotRow(tty: "ttys002", cwd: H + "/Dev/38.LifespanOS", agent: "agy", state: .unknown,
                minutes: 0, title: "lifespan", detail: "Antigravity", tab: "",
                cpu: 0, bytes: 220_000_000, peak: 0),
        ShotRow(tty: "ttys003", cwd: H + "/Dev/api-gateway", agent: "claude", state: .unknown,
                minutes: 0, title: "api", detail: "Claude Code", tab: "✳ Claude Code",
                cpu: 1, bytes: 621_000_000, peak: 0),
        ShotRow(tty: "ttys004", cwd: nil, agent: nil, state: .idle,
                minutes: 0, title: "tty s004", detail: "no agent running", tab: "",
                cpu: 0, bytes: 4_194_304, peak: 0),
    ]

    // ── THE HOSTILE NAMES. Every truncation rule, in one list. ─────────────────────────────
    case "truncation": return [
        ShotRow(tty: "ttys001", cwd: H + "/Documents/2026/Development/37.chute/site",
                agent: "claude", state: .blocked, minutes: 9,
                title: "deep", detail: "Claude Code · Opus 5", tab: "✳ a session title far longer than its column",
                cpu: 22, bytes: 900_000_000, peak: 0),
        ShotRow(tty: "ttys002", cwd: "/Volumes/Work/clients/norse/api-gateway",
                agent: "claude", state: .working, minutes: 3,
                title: "volume", detail: "Claude Code · Sonnet 5", tab: "◑ vendor api client regeneration",
                cpu: 8, bytes: 310_000_000, peak: 0),
        ShotRow(tty: "ttys003", cwd: H + "/Clients/Client Work/Norse Bank",
                agent: "codex", state: .working, minutes: 15,
                title: "spaces", detail: "Codex · high", tab: "✳ Norse Bank statement parser",
                cpu: 14, bytes: 540_000_000, peak: 0),
        ShotRow(tty: "ttys004", cwd: H + "/Dev/a-very-long-project-directory-name/site",
                agent: "claude", state: .waiting, minutes: 1,
                title: "long", detail: "Claude Code · Opus 5 · high", tab: "◐ migrate every page to the new layout",
                cpu: 3, bytes: 150_000_000, peak: 0),
        ShotRow(tty: "ttys005", cwd: nil, agent: "agy", state: .unknown,
                minutes: 0, title: "tty s005", detail: "Antigravity", tab: "",
                cpu: 0, bytes: 145_000_000, peak: 0),
    ]

    default: return []
    }
}

func shotCast(_ name: String, _ now: Date, _ gitRoots: [String: String]) -> [Session] {
    shotRows(name).map { r in
        Session(key: "Terminal:1:\(r.tty)", kind: .terminalApp, windowID: 1, tabIndex: 1,
                tty: r.tty,
                // The real derivation, with the git answer injected: these fixture paths do not
                // exist on any disk, so the live probe would answer nil and every row would fall
                // back to its folder leaf — hiding the very behaviour the shot is meant to show.
                project: ProjectName.resolve(cwd: r.cwd, windowTitle: r.title,
                                             gitRoot: { gitRoots[$0] }),
                title: r.tab, agent: r.agent, busy: r.state == .working, state: r.state,
                since: now.addingTimeInterval(-60 * r.minutes),
                sessionID: r.agent == nil ? nil : r.tty, cwd: r.cwd)
    }
}

func shotLoad(_ name: String) -> (String) -> SessionLoad {
    let rows = shotRows(name)
    return { tty in
        guard let r = rows.first(where: { $0.tty == tty }) else {
            return SessionLoad(cpuPercent: 0, residentBytes: 0, processes: 0)
        }
        return SessionLoad(cpuPercent: r.cpu, residentBytes: r.bytes,
                           processes: r.bytes > 0 ? 1 : 0, top: nil, peakBytes: r.peak)
    }
}

/// Git roots for the fixture paths, so a subdirectory names its repo the way it would in life.
/// These paths exist on no disk, so the LIVE probe would answer nil and every row would fall back
/// to its folder leaf — hiding the behaviour the shot exists to show.
func shotGitRoots(_ name: String) -> [String: String] {
    var out: [String: String] = [:]
    for r in shotRows(name) {
        guard let cwd = r.cwd else { continue }
        let parts = cwd.components(separatedBy: "/")
        if let i = parts.firstIndex(where: { $0 == "Dev" || $0 == "Development" || $0 == "clients" }),
           i + 1 < parts.count {
            out[cwd] = parts[0...(i + 1)].joined(separator: "/")
        } else {
            out[cwd] = cwd
        }
    }
    return out
}

/// Capture a real WINDOW. CGWindowListCreateImage photographs what is actually composited, so it
/// picks up the layer-backed NSTextFields that `cacheDisplay(in:to:)` renders as blank — that
/// difference cost a cycle: the first attempt produced a page with the link rows and nothing else.
func shotWindow(_ w: NSWindow?, to path: String) {
    guard let w else { exit(2) }
    w.display()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
        guard let cg = CGWindowListCreateImage(.null, .optionIncludingWindow,
                                               CGWindowID(w.windowNumber),
                                               [.boundsIgnoreFraming, .bestResolution])
        else { exit(3) }
        try? NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])?
            .write(to: URL(fileURLWithPath: path))
        exit(0)
    }
}

let shotArgv = CommandLine.arguments

// --settings-shot <path> <tabIndex>   0 = General, 1 = About
if let i = shotArgv.firstIndex(of: "--settings-shot"), i + 2 < shotArgv.count {
    let out = shotArgv[i + 1], tab = Int(shotArgv[i + 2]) ?? 0
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        SettingsWindow.show(selecting: tab)
        shotWindow(SettingsWindow.window, to: out)
    }
}

// --firstrun-shot <path> — the setup window, forced open regardless of what this machine has
// already onboarded, so the shot is the same on any machine.
if let i = shotArgv.firstIndex(of: "--firstrun-shot"), i + 1 < shotArgv.count {
    let out = shotArgv[i + 1]
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        FirstRunWindow.show()
        shotWindow(FirstRunWindow.window, to: out)
    }
}

if let i = shotArgv.firstIndex(of: "--about-shot"), i + 1 < shotArgv.count {
    let out = shotArgv[i + 1]
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        SettingsWindow.show(selecting: 1)
        guard let w = SettingsWindow.window else { exit(2) }
        w.display()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard let cg = CGWindowListCreateImage(.null, .optionIncludingWindow,
                                                   CGWindowID(w.windowNumber),
                                                   [.boundsIgnoreFraming, .bestResolution])
            else { exit(3) }
            try? NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])?
                .write(to: URL(fileURLWithPath: out))
            exit(0)
        }
    }
}

if let shotIdx = shotArgv.firstIndex(of: "--menu-shot"), shotIdx + 1 < shotArgv.count {
    let shotPath = shotArgv[shotIdx + 1]
    let log = shotPath + ".log"
    shotNote(log, "harness entered")
    let caseName = shotArgv.firstIndex(of: "--case").map { shotArgv[$0 + 1] } ?? "mixed"
    let now = Date()
    let shotMenu = NSMenu()
    shotMenu.autoenablesItems = false
    var detail: [String: String] = [:]
    for r in shotRows(caseName) { detail[r.tty] = r.detail }
    let shotModel = StatusMenu.model(sessions: shotCast(caseName, now, shotGitRoots(caseName)),
                                     now: now,
                                     loadFor: shotLoad(caseName),
                                     sessionCommands: { _ in [] },
                                     detailFor: { detail[$0.tty] ?? "" })
    SessionMenu.render(shotModel, into: shotMenu, target: delegate, selector: { _ in nil },
                       servers: { m in
                           let it = NSMenuItem(title: "Local Servers  (2)", action: nil,
                                               keyEquivalent: "")
                           it.submenu = NSMenu()
                           m.addItem(it)
                       })
    shotNote(log, "case \(caseName): \(shotMenu.numberOfItems) items, \(shotMenu.size)")

    // popUp is modal, so the capture runs off a timer in .common modes — which includes
    // NSEventTrackingRunLoopMode, the mode a menu tracks in.
    let capture = Timer(timeInterval: 1.5, repeats: false) { _ in
        shotNote(log, "capture timer fired")
        let pid = ProcessInfo.processInfo.processIdentifier
        let all = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
            as? [[String: Any]] ?? []
        let ours = all.filter { ($0[kCGWindowOwnerPID as String] as? Int32) == pid }
        shotNote(log, "windows owned by us: \(ours.count)")
        let tallest = ours.max {
            let a = ($0[kCGWindowBounds as String] as? [String: CGFloat])?["Height"] ?? 0
            let b = ($1[kCGWindowBounds as String] as? [String: CGFloat])?["Height"] ?? 0
            return a < b
        }
        guard let wid = tallest?[kCGWindowNumber as String] as? CGWindowID,
              let cg = CGWindowListCreateImage(.null, .optionIncludingWindow, wid,
                                               [.boundsIgnoreFraming, .bestResolution])
        else { shotNote(log, "no capturable window"); exit(3) }
        try? NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])?
            .write(to: URL(fileURLWithPath: shotPath))
        shotNote(log, "wrote \(shotPath)")
        exit(0)
    }
    RunLoop.main.add(capture, forMode: .common)

    // DRAW THE ITEMS OURSELVES, because popUp cannot track without a real user session — it
    // returns instantly from a scripted launch and there is no menu window to photograph. What
    // is drawn below is not a mock-up: every string is the `attributedTitle` the REAL
    // SessionMenu.render produced, every dot is its real NSImage, and the width is the menu's
    // own `size.width`. Only AppKit's chrome — the vibrancy behind it and the highlight bar —
    // is approximated, and neither carries any of the layout being judged here.
    if shotArgv.contains("--draw") {
        let w = shotMenu.size.width
        let leftPad: CGFloat = 21, imgGap: CGFloat = 5, vPad: CGFloat = 5
        var heights: [CGFloat] = []
        for it in shotMenu.items {
            guard !it.isSeparatorItem else { heights.append(11); continue }
            let t = it.attributedTitle ?? NSAttributedString(string: it.title,
                        attributes: [.font: NSFont.menuFont(ofSize: 0)])
            heights.append(ceil(t.boundingRect(with: NSSize(width: w, height: 400),
                                               options: [.usesLineFragmentOrigin]).height) + vPad * 2)
        }
        let total = heights.reduce(12, +)
        let img = NSImage(size: NSSize(width: w, height: total))
        img.lockFocus()
        NSColor(calibratedWhite: 0.16, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: w, height: total),
                     xRadius: 10, yRadius: 10).fill()
        var y = total - 6
        for (i, it) in shotMenu.items.enumerated() {
            let h = heights[i]
            y -= h
            if it.isSeparatorItem {
                NSColor(calibratedWhite: 1, alpha: 0.12).setFill()
                NSRect(x: 14, y: y + h / 2, width: w - 28, height: 1).fill()
                continue
            }
            var x = leftPad
            if let im = it.image {
                im.draw(in: NSRect(x: x, y: y + h - 20, width: im.size.width, height: im.size.height))
                x += im.size.width + imgGap
            }
            let t = it.attributedTitle ?? NSAttributedString(string: it.title,
                        attributes: [.font: NSFont.menuFont(ofSize: 0),
                                     .foregroundColor: NSColor.labelColor])
            t.draw(with: NSRect(x: x, y: y + vPad, width: w - x - 12, height: h - vPad),
                   options: [.usesLineFragmentOrigin])
        }
        img.unlockFocus()
        if let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: shotPath))
            shotNote(log, "drew \(shotMenu.items.count) items into \(shotPath) at \(w)x\(total)")
        }
        exit(0)
    }

}

