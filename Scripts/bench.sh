#!/usr/bin/env bash
# THE HOT-PATH BENCHMARK — builds release and runs Scripts/bench.swift against the REAL machine:
# this machine's own process table, this machine's own ~/.claude transcripts, Terminal.app
# actually running. See docs/specs/PERFORMANCE.md for what the numbers mean and what changed
# because of them.
#
#   Scripts/bench.sh
#
# `bench` is a SwiftPM executable target (Package.swift) whose one source file is
# Scripts/bench.swift — not `swift Scripts/bench.swift` directly, because the benchmark needs to
# `import ChuteCore`, and a single free-standing script has no way to link a local package's
# library target. This is the same reason `chutetests` is a package target rather than a script.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

swift build -c release --product bench || { echo "bench: build failed" >&2; exit 1; }
.build/release/bench
