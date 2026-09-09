# Contributing

Chute is MIT, all of it — the app, the Finder extension, the CLI, the site. Issues and pull
requests are welcome, and there is no contributor agreement to sign.

## Build

No Xcode. This repo builds with the Command Line Tools only, deliberately —
[`Package.swift`](Package.swift) has zero external dependencies so `swift build` stays offline and
instant, and `XCTest` (which ships with Xcode, not the CLT) is unavailable here on purpose, which
is why the test suite is a plain executable with an assert harness instead of a `.testTarget`.

```bash
swift build -c release
```

## Run the suite

```bash
swift run -c release chutetests       # the unit suite — prints its own pass count, don't retype it
CHUTE_HEADLESS=1 ./Scripts/smoke.sh    # the CLI end to end, no GUI needed
./Scripts/smoke.sh                     # + the Finder/Terminal sections, needs a logged-in desktop
```

## The gates that must pass before a change is done

All of them are described in full — what each measures, what a red run means, and what it cannot
catch — in [`docs/SCRIPTS.md`](docs/SCRIPTS.md). At minimum, before opening a PR:

```bash
swift build -c release
swift run -c release chutetests
CHUTE_HEADLESS=1 ./Scripts/smoke.sh
./Scripts/check-untested-logic.sh
```

If your change touches `README.md`, `site/src/app/**`, or any published copy, also run
`./Scripts/check-focus.sh` and, from `site/`, `npm run check:claims` against a built site. If it
touches `Sources/ChuteFinder/` or the Finder actions, run `./Scripts/acceptance.sh`. If it changes
anything a window shows, run `./Scripts/screens.sh` and look at the PNGs — a passing suite proves
nothing about what a screen actually looks like; see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
for the bug that taught that lesson.

## Where a new decision belongs

`chutetests` links [`ChuteCore`](Sources/ChuteCore) only — `ChuteApp` and `ChuteFinder` have zero
test coverage by construction, not by neglect. If what you're adding has a right and a wrong
answer — a sort order, a truncation rule, whether a row should appear at all — it belongs in
`ChuteCore` as a pure function with a test, not inline in the AppKit or FinderSync code that
consumes it. [`Scripts/check-untested-logic.sh`](Scripts/check-untested-logic.sh) enforces this: it
counts decision points in the two untestable targets against a committed baseline, and a PR that
grows that number will fail the gate. Read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the
two bugs (a menu dot that drew nothing; a project name that could silently disagree with itself)
that this rule exists because of — both lived in code no test could reach, and both shipped past a
fully green suite.

## House style

**Comments explain WHY, and name the incident that motivated the code**, not what the code does —
the code already says what. Nearly every non-trivial function in `Sources/ChuteCore/` and every
gate in `Scripts/` follows this: a header comment states the bug it exists to prevent, often with
a date and what the wrong number or wrong pixel was, so the next person doesn't have to guess
whether a check is load-bearing or decorative. Read
[`Scripts/check-untested-logic.sh`](Scripts/check-untested-logic.sh) or
[`Sources/ChuteCore/StateResolver.swift`](Sources/ChuteCore/StateResolver.swift) for the pattern
before writing a new one.

Other conventions actually enforced in this codebase, not aspirational:

- **Destructive operations preview by default.** `clean` lists, it doesn't delete, until `--force`.
  `checkpoint` never touches the real index, worktree, or `HEAD`. A new command that can destroy
  something follows the same shape.
- **A confident-looking guess is worse than an honest blank.** `Session.project` is `String?`;
  `nil` prints as `"no project derived"`, never a sentinel that could collide with a real value.
  `StateResolver` returns `.unknown` rather than inferring a state from a stale proxy — see
  `docs/ARCHITECTURE.md` for the incident that taught this one specifically.
- **No number a human typed where a command could derive it.** Counts, sizes, and pass tallies in
  README.md and the site are re-derived by a script (`check-claims.mjs`,
  `site/scripts/check-cases.mjs`) rather than hand-copied — three false numbers reached the live
  site by hand-typing before this rule existed; see
  [`marketing/06-FACT-SHEET.md`](marketing/06-FACT-SHEET.md).

## No Intel claims

The build is arm64-only — `Scripts/build-app.sh` runs a plain `swift build -c release` with no
`--arch` flags, so it only ever produces the host machine's architecture, and there is no
universal-binary step anywhere in this repo. Don't add a claim of Intel support without adding the
build step that makes it true first.

## Specs

Product and engineering specs live in [`docs/`](docs/) — business requirements, FR/NFR, the JTBD
ledger, the customer journey map, the definition of done, and design briefs under
[`docs/specs/`](docs/specs/).
