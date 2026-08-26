# Design — Finder context menu via FinderSync

**Date:** 2026-08-26 · **Status:** approved for implementation · **Subsystem:** 1 of 2

## Problem

Chute's founding requirement is "right-click and see the actions". Three attempts failed:

| Attempt | Registered? | Appeared in Finder? | Why it failed |
|---|---|---|---|
| App-declared `NSServices` | yes (`pbs -dump_pboard`) | no | Lands in the *Services* submenu, which Finder buries |
| Automator `.workflow` in `~/Library/Services` | yes | no | Not present in `pbs FinderActive`, the allow-list that populates *Quick Actions* |
| …plus `NSRequiredContext` | yes | no, and vanished from System Settings too | Undocumented format, synthesised by hand |

Evidence at the time of writing: the *Quick Actions ▸* submenu on a folder contains only
"Customize…", and `defaults read pbs FinderActive` lists only `APPEXTENSION-*` and
`is.workflow.actions.*` entries — **zero** Automator workflows.

**Root cause:** the `document.wflow` format was reverse-engineered from system bundles. Three
subsystems disagree about the result — `automator` executes it, `pbs` registers it, Finder
ignores it. Guessing at an undocumented format is not a strategy.

**Disqualifying reason, independent of the bug:** even a working Automator Quick Action is nested
two levels deep and needs eight checkboxes ticked by hand. The stated product requirement is
"install and get the actions in the context menu".

## Decision

Build a **`FIFinderSync` app extension** embedded in `Chute.app`.

Precedent on this machine: `pluginkit -m -p com.apple.FinderSync` lists
`com.google.drivefs.finderhelper.findersync` — Google Drive puts items in this Mac's context menu
by exactly this mechanism. Every commercial competitor (MagicMenu, iRightMouse, SuperRClick) does
the same.

**Feasibility verified, no Xcode needed:**
- `FinderSync.framework` is present in the Command Line Tools SDK at
  `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/FinderSync.framework`
- A Swift file importing `FinderSync` compiled and linked with `swiftc` (binary produced, 52 KB)
- `NSExtensionMain` is exported from `Foundation.tbd`

## Architecture

```
Chute.app/Contents/
  MacOS/ChuteApp                     menu bar + hotkey            unchanged
  MacOS/chute                        the engine                   unchanged
  PlugIns/ChuteFinder.appex/         NEW
    Contents/Info.plist              NSExtensionPointIdentifier = com.apple.FinderSync
    Contents/MacOS/ChuteFinder       FIFinderSync subclass, ~120 lines
```

The engine is untouched. All 55 unit and 39 end-to-end checks remain valid. The extension is a
menu that shells out to `chute`, exactly like every other surface.

### Extension contract

```swift
class ChuteFinderSync: FIFinderSync {
    override init() {
        super.init()
        // CRITICAL: an extension observing nothing shows no menu, silently.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        // .contextualMenuForItems  → files/folders selected
        // .contextualMenuForContainer → right-click on empty window background
        // .toolbarItemMenu → toolbar button
    }
}
```

`directoryURLs = ["/"]` is the single most common FinderSync mistake and the reason extensions
"install but do nothing". Observing the root volume is what Google Drive and MagicMenu do.

### Menu shape

One top-level `Chute` item with a submenu — not eight top-level items, which is what makes
competing products feel like spam.

```
Chute  ▸  Copy Paths for Prompt
          Bundle Context (XML)
          New File from Clipboard
          Unpack Markdown Here
          Checkpoint Before Agent
          Sandbox + Agent (yolo)
          Open Terminal Here
          Copy Redacted
```

Selection-dependent: with items selected, `FIFinderSyncController.default().selectedItemURLs()`
supplies the paths. On empty background, `targetedURL()` supplies the folder and the
selection-only entries are omitted.

Each item runs `Process` on `Contents/MacOS/chute` — resolved relative to the appex bundle
(`Bundle.main.bundleURL` → up two levels → `Contents/MacOS/chute`), never from `PATH`, which an
extension does not reliably inherit.

## Build and install

`Scripts/build-app.sh` gains an appex stage:

1. `swift build -c release` produces `ChuteFinder` (a `main.swift` calling `NSExtensionMain()`)
2. Assemble `ChuteFinder.appex/Contents/{Info.plist,MacOS/ChuteFinder}`
3. **Sign inner-to-outer** — `codesign -s - ChuteFinder.appex` *then* `codesign -s - Chute.app`.
   Signing the outer bundle first invalidates it when the inner one changes.
4. `pluginkit -a "$APP/Contents/PlugIns/ChuteFinder.appex"` to register

Info.plist keys for the appex:

| Key | Value |
|---|---|
| `CFBundleIdentifier` | `dev.valuev.chute.finder` |
| `CFBundlePackageType` | `XPC!` |
| `NSExtension.NSExtensionPointIdentifier` | `com.apple.FinderSync` |
| `NSExtension.NSExtensionPrincipalClass` | `ChuteFinderSync` (`@objc` exposed) |
| `LSMinimumSystemVersion` | `13.0` |

User action required: **one** tick in System Settings → Privacy & Security → Extensions → Finder
→ ☑ Chute. Survives updates. `Scripts/install.sh` prints the deep link
`x-apple.systempreferences:com.apple.ExtensionsPreferences`.

## What is deleted

`Scripts/install-quickactions.sh` and the eight installed `.workflow` bundles — roughly 180 lines
of something that provably does not work. `Scripts/uninstall.sh` keeps removing stale workflows
for one release so existing installs clean up.

## Verification

| Check | Command | Pass condition |
|---|---|---|
| Extension registered | `pluginkit -m -p com.apple.FinderSync` | lists `dev.valuev.chute.finder` |
| Signature valid | `codesign -vvv --deep Chute.app` | "satisfies its Designated Requirement" |
| Engine intact | `swift run chutetests && ./Scripts/smoke.sh` | 55 assertions, 39 checks |
| Menu appears | human right-clicks a folder | `Chute ▸` at top level |

**Hard stop:** if `pluginkit` refuses to register an ad-hoc-signed appex, stop and install Xcode.
Do not spend a second hour guessing at Apple's packaging rules — that failure mode is what
produced this document.

## Deferred

Developer ID signing, notarization, and a DMG. Required before anyone else can install this;
blocked on a $99/yr Apple Developer Program membership, which the founder has chosen not to buy
yet. Until then the target is a working local install on this Mac. Tracked in `docs/06-BACKLOG.md`.
