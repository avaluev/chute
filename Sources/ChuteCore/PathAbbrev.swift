import Foundation

/// Two truncation rules for two different kinds of string, because they answer different
/// questions. A NAME is a word: truncate its tail, because a reader recognises a word by its
/// start. A PATH has two ends a human actually uses to recognise it — the root that says WHERE
/// (home, a repo volume, a git checkout) and the leaf that says WHAT — so a path truncates in the
/// MIDDLE, sacrificing the components in between, one at a time.
///
/// Budget is CHARACTERS, not points. `NSMenu` sizes itself to its content, so there is no
/// container width to fit against — the budget here is editorial, not a layout constraint, and a
/// points budget would imply a constraint that doesn't exist. `NSFont.menuFont` also varies by
/// macOS version and accessibility text-size setting, so an expected string computed from it would
/// differ between machines — and this repo's whole test story is exact string equality in a
/// headless harness. `chute sessions` also prints these paths straight into a terminal, where
/// columns genuinely ARE characters. The cost: `WWWW` is visually wider than `iiii`, so a rendered
/// row is occasionally a little wide — invisible in a menu that sizes itself to its content. If a
/// fixed-width container ever needs this, wrap it with a `fit(_:in:font:)` in ChuteApp that
/// binary-searches the budget; do not rewrite this module to chase points.
///
/// Counting unit is `String.count` — extended grapheme clusters — so `prefix`/`suffix` can never
/// split an emoji or a base letter away from its combining mark.
public enum PathAbbrev {
    /// Where the six reference outputs in mockup 4b land — see the ruling comment on `ladder`.
    public static let defaultBudget = 28
    public static let defaultNameBudget = 24

    /// Middle-truncates a PATH, preferring to keep both ends recognisable.
    ///
    /// `home` is injectable so the suite can isolate `~`-folding without touching real `$HOME`
    /// (see Home.swift for why `NSHomeDirectory()` alone can't be trusted for that isolation).
    /// Home is folded BEFORE the `/Volumes/<name>` check, so a home directory that happens to live
    /// on an external disk still folds to `~` rather than reading as a bare volume path.
    public static func path(_ full: String, budget: Int = defaultBudget, home: String = Home.path) -> String {
        let (root, leadingSlash, components) = parse(fold(full, home: home))
        return ladder(root: root, leadingSlash: leadingSlash, components: components, budget: budget)
    }

    /// Tail-truncates a NAME, trimming trailing whitespace off the kept head before adding the
    /// ellipsis — without that trim, a name that happens to break right after a space leaves a
    /// dangling gap before the `…`, which reads as a typo rather than a truncation.
    public static func name(_ s: String, budget: Int = defaultNameBudget) -> String {
        guard s.count > budget else { return s }
        guard budget > 0 else { return "…" }
        var head = String(s.prefix(budget - 1))
        while head.hasSuffix(" ") { head.removeLast() }
        return head + "…"
    }

    /// Exposed for its own assertions — the middle-truncation primitive every rung of `path`'s
    /// ladder below falls back to once dropping whole components isn't (or is no longer) enough.
    ///
    /// `head = (n-1)/2`, `tail = n-1-head` rounds the shorter half DOWN, so an odd budget gives the
    /// extra character to the tail — the end a reader also uses to confirm a file's extension.
    /// That is what yields exactly `a-very-lo…-directory` for `middle("a-very-long-directory", to:
    /// 20)`: head 9, tail 10.
    public static func middle(_ s: String, to n: Int) -> String {
        guard s.count > n else { return s }
        guard n >= 3 else { return "…" }   // no room for a character on either side of the ellipsis
        let headCount = (n - 1) / 2
        let tailCount = n - 1 - headCount
        return String(s.prefix(headCount)) + "…" + String(s.suffix(tailCount))
    }

    // MARK: - path's ladder

    /// **The conflict, and the founder's ruling.** Mockup 4b's rule 2 said "always keep the root
    /// token and the last two components" — but its own volume example drops one:
    /// `/Volumes/Work/a/b/api-gateway` → `/Volumes/Work/…/api-gateway`, keeping only
    /// `api-gateway`. Taken literally, rule 2 would instead produce
    /// `/Volumes/Work/…/b/api-gateway` — 29 characters against a 28-character budget.
    /// **Ruled 2026-09-08: the examples win.** The prose rule was the approximation; the six
    /// reference outputs are the ground truth, and they are all 27-29 characters — which is where
    /// `defaultBudget = 28` comes from.
    ///
    /// That ruling also settles the one place the prose left ambiguous on its own terms: whether
    /// to shave a character off a kept component, or drop the whole component, once both are on
    /// the table. The volume example is decisive. Dropping `b` gets to 27 characters. Shaving
    /// `api-gateway` down to fit alongside a kept `b` only reaches 28 — and it gets there by
    /// mangling a real word into `api-…teway` to save the ONE character `b` was costing. A whole
    /// component honestly missing behind `…` reads as an omission; a word cut mid-letter reads as
    /// corruption. So this ladder tries dropping a component BEFORE it ever tries mid-word
    /// truncation on one — truncation is reserved for the rung where dropping already happened and
    /// still wasn't enough.
    ///
    /// Order of sacrifice, first fit wins:
    ///   1. the full path, unchanged.
    ///   2. root + `…` + the last two components, re-adding components from the LEFT — the end
    ///      that says which machine or repo this is — while each addition still fits.
    ///   3. root + `…` + only the last component (the second-to-last is dropped whole).
    ///   4. the same, with the last component itself middle-truncated to whatever room remains.
    ///   5. drop the root token too. A NAMED root (`~`, `/Volumes/Work`) only goes here, last; a
    ///      bare `/` was never fought for in the first place — see `parse` below — so it leaves no
    ///      later than this rung either.
    ///   6. last resort: `middle(lastComponent, to: budget)` spends the WHOLE budget on the leaf
    ///      alone, no root, no `…/` prefix — or a bare `"…"` once that budget can't hold a
    ///      character on each side of the ellipsis either.
    private static func ladder(root: String?, leadingSlash: Bool, components: [String],
                               budget: Int) -> String {
        let full = render(root: root, leadingSlash: leadingSlash, parts: components)
        if full.count <= budget { return full }

        // `~` alone, or a bare `/` alone: nothing above the root to sacrifice, and the fit check
        // above already failed, so there is nothing left this ladder can do for it.
        guard let last = components.last else { return full }

        guard components.count > 1 else {
            // One component and nothing above it — straight to the leaf's own rung, root and all.
            return middle(last, to: budget)
        }

        let lastTwo = Array(components.suffix(2))
        let head = Array(components.dropLast(2))

        // Rung 2 — reflow HEAD components back in from the left, one at a time, stopping at the
        // first one that would bust the budget. `kept` never loses a component it already added:
        // shrinking would mean a later, shorter row reading as if it named LESS of the path than
        // an earlier, longer one — the opposite of what re-adding from a fixed end is for.
        var kept: [String] = []
        for component in head {
            let trial = kept + [component]
            let rendered = render(root: root, leadingSlash: leadingSlash, parts: trial + ["…"] + lastTwo)
            guard rendered.count <= budget else { break }
            kept = trial
        }
        let twoTail = render(root: root, leadingSlash: leadingSlash, parts: kept + ["…"] + lastTwo)
        if twoTail.count <= budget { return twoTail }

        // Rung 3 — drop the second-to-last component whole.
        let oneTail = render(root: root, leadingSlash: leadingSlash, parts: ["…", last])
        if oneTail.count <= budget { return oneTail }

        // Rung 4 — that alone doesn't fit either: keep root + `…/`, middle-truncate the leaf to
        // whatever room is left, so SOME location context survives even when the leaf is long.
        let rootedPrefix = render(root: root, leadingSlash: leadingSlash, parts: ["…"])
        let roomWithRoot = budget - rootedPrefix.count - 1   // "/" that rejoins the truncated leaf
        if roomWithRoot >= 3 {
            let candidate = rootedPrefix + "/" + middle(last, to: roomWithRoot)
            if candidate.count <= budget { return candidate }
        }

        // Rung 5 — drop the root token too.
        let bareTail = "…/" + last
        if bareTail.count <= budget { return bareTail }
        let roomBare = budget - 2   // "…/" itself is two characters
        if roomBare >= 3 { return "…/" + middle(last, to: roomBare) }

        // Rung 6 — the whole budget spent on the leaf alone.
        return middle(last, to: budget)
    }

    // MARK: - parsing

    /// `$HOME` fold, guarded by `home != "/" && !home.isEmpty` — `$HOME` is settable, and
    /// `HOME=/` must not fold the entire disk to a tilde.
    private static func fold(_ full: String, home: String) -> String {
        guard home != "/", !home.isEmpty else { return full }
        if full == home { return "~" }
        if full.hasPrefix(home + "/") { return "~" + full.dropFirst(home.count) }
        return full
    }

    /// A "root token" is a component the ladder keeps or drops as ONE unit, never mid-word
    /// truncated: `~` (checked first, so home wins over the volume check below it) or
    /// `/Volumes/<name>` — the volume name is what makes it recognisable, so splitting it defeats
    /// the point. Anything else absolute has no such token, just a leading `/` that costs one
    /// character and was never worth defending on its own — the "a bare `/` does not [outrank the
    /// second-to-last component]" rule on `ladder` above.
    private static func parse(_ folded: String) -> (root: String?, leadingSlash: Bool, components: [String]) {
        if folded == "~" { return (root: "~", leadingSlash: true, components: []) }
        if folded.hasPrefix("~/") {
            let comps = folded.dropFirst(2).split(separator: "/", omittingEmptySubsequences: true).map(String.init)
            return (root: "~", leadingSlash: true, components: comps)
        }
        if folded.hasPrefix("/") {
            let comps = folded.dropFirst().split(separator: "/", omittingEmptySubsequences: true).map(String.init)
            if comps.count >= 2, comps[0] == "Volumes" {
                return (root: "/Volumes/\(comps[1])", leadingSlash: true, components: Array(comps.dropFirst(2)))
            }
            return (root: nil, leadingSlash: true, components: comps)
        }
        // Relative input: `leadingSlash` stays false all the way to `render`, so a relative path
        // handed in can never grow a leading "/" it didn't already have.
        let comps = folded.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        return (root: nil, leadingSlash: false, components: comps)
    }

    /// The one place a root, a leading slash and a list of components become a string. `parts`
    /// may carry the literal `"…"` placeholder as an ordinary segment — joining it like any other
    /// component is what keeps every rung above a one-line call instead of a branch apiece.
    private static func render(root: String?, leadingSlash: Bool, parts: [String]) -> String {
        let body = parts.joined(separator: "/")
        if let root { return body.isEmpty ? root : root + "/" + body }
        return leadingSlash ? "/" + body : body
    }
}
