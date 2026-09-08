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

func shotCast(_ now: Date) -> [Session] {
    func s(_ tty: String, _ cwd: String?, _ agent: String?, _ state: SessionState,
           _ minutes: Double, _ title: String) -> Session {
        Session(key: "Terminal:1:\(tty)", kind: .terminalApp, windowID: 1, tabIndex: 1,
                // The fixture paths do not exist on this disk, so the REAL git probe would
                // answer nil and every row would fall back to its folder leaf. Injecting the
                // answer a real repo would give is what `resolve`'s probe parameter is for —
                // and it is the whole point of the shot: both 37.sntz sessions, one of them in
                // a subdirectory, must print the SAME project name.
                tty: tty, project: ProjectName.resolve(cwd: cwd, windowTitle: title,
                                                       gitRoot: { c in
                    ["/Users/sxope/Dev/37.sntz": "/Users/sxope/Dev/37.sntz",
                     "/Users/sxope/Dev/37.sntz/site": "/Users/sxope/Dev/37.sntz",
                     "/Users/sxope/Dev/28.tallyapp": "/Users/sxope/Dev/28.tallyapp",
                     "/Users/sxope/Dev/37.chute": "/Users/sxope/Dev/37.chute",
                     "/Users/sxope/Dev/studylock": "/Users/sxope/Dev/studylock",
                     "/Users/sxope/Dev/38.LifespanOS": "/Users/sxope/Dev/38.LifespanOS"][c]
                }),
                title: title, agent: agent, busy: state == .working, state: state,
                since: now.addingTimeInterval(-60 * minutes),
                sessionID: agent == nil ? nil : tty, cwd: cwd)
    }
    return [
        s("ttys001", "/Users/sxope/Dev/37.sntz",       "claude", .blocked, 22, "sntz_mockups"),
        s("ttys002", "/Users/sxope/Dev/28.tallyapp",   "codex",  .blocked,  4, "28.tallyapp"),
        s("ttys003", "/Users/sxope/Dev/37.chute",      "claude", .waiting,  3, "37.chute"),
        s("ttys004", "/Users/sxope/Dev/studylock",     "claude", .waiting, 12, "studylock"),
        s("ttys005", "/Users/sxope/Dev/37.sntz",       "claude", .working,  1, "sntz_mockups"),
        s("ttys006", "/Users/sxope/Dev/37.sntz/site",  "claude", .working,  8, "sntz_mockups"),
        s("ttys007", "/Users/sxope/Dev/38.LifespanOS", "agy",    .unknown,  0, "38.LifespanOS"),
        s("ttys008", nil,                              "agy",    .unknown,  0, "tty s004"),
    ]
}

func shotLoad(_ tty: String) -> SessionLoad {
    let t: [String: (Double, UInt64, UInt64)] = [
        "ttys001": (177, 3_221_225_472, 0),
        "ttys002": (12,    671_088_640, 0),
        "ttys003": (4,     220_200_960, 0),
        "ttys004": (1,     661_651_456, 0),
        "ttys005": (40,  1_181_116_006, 0),
        "ttys006": (88,  2_576_980_378, 6_549_723_444),
        "ttys007": (0,     230_686_720, 0),
        "ttys008": (0,     152_043_520, 0),
    ]
    let v = t[tty] ?? (0, 0, 0)
    return SessionLoad(cpuPercent: v.0, residentBytes: v.1, processes: v.1 > 0 ? 1 : 0,
                       top: nil, peakBytes: v.2)
}

/// Capture a real WINDOW — CGWindowListCreateImage photographs what is actually composited, so
/// it picks up the layer-backed NSTextFields that `cacheDisplay(in:to:)` renders as blank. That
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
    let now = Date()
    let shotMenu = NSMenu()
    shotMenu.autoenablesItems = false
    let detail: [String: String] = [
        "ttys001": "Claude Code · Opus 5 · xhigh", "ttys002": "Codex · high",
        "ttys003": "Claude Code · Sonnet 5",       "ttys004": "Claude Code · Opus 5 · high",
        "ttys005": "Claude Code · Opus 5",         "ttys006": "Claude Code · Opus 5 · high",
        "ttys007": "Antigravity",                  "ttys008": "Antigravity",
    ]
    let shotModel = StatusMenu.model(sessions: shotCast(now), now: now,
                                     loadFor: shotLoad,
                                     sessionCommands: { _ in [] },
                                     detailFor: { detail[$0.tty] ?? "" })
    SessionMenu.render(shotModel, into: shotMenu, target: delegate, selector: { _ in nil },
                       servers: { m in
                           let it = NSMenuItem(title: "Local Servers  (2)", action: nil,
                                               keyEquivalent: "")
                           it.submenu = NSMenu()
                           m.addItem(it)
                       })
    shotNote(log, "rendered \(shotMenu.numberOfItems) items; menu size \(shotMenu.size)")

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

