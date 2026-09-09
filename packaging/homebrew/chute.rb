class Chute < Formula
  desc "Terminal half of Chute, the macOS menu bar and Finder menu for coding agents"
  homepage "https://chutedev.com"
  # VERSION comes from Sources/ChuteCore/Version.swift — the one place it lives. Bump both
  # together: tag the release, then update this line to match.
  #
  # STALE UNTIL SOMEONE PUBLISHES IT. Found 2026-09-08 during install-path verification: the
  # LIVE tap (avaluev/homebrew-tap, `brew info avaluev/tap/chute`) was still serving 0.2.0 while
  # this file — and the actual v0.2.1 GitHub release — had moved on. `brew install
  # avaluev/tap/chute` still works (that flag on the site is not a lie), it just hands out an
  # old CLI until packaging/homebrew/README.md's steps 4-6 are run against the tap repo, which
  # this file cannot do by itself — it is a copy, not the tap.
  version "0.2.1"
  url "https://github.com/avaluev/chute/archive/refs/tags/v#{version}.tar.gz"
  # Recompute on every version bump — AND after any history rewrite. A force-push changes
  # every tag's generated tarball: on 2026-09-09 the rewrite that removed private files
  # silently broke `brew install avaluev/tap/chute` for every new user, and the failure
  # only shows on a cold cache, so a machine that already had the download kept working.
  # Recompute on every version bump:
  #   curl -L https://github.com/avaluev/chute/archive/refs/tags/v0.2.1.tar.gz | shasum -a 256
  sha256 "d7a88744de7468140c35dcceb0ded32323a64b6f2a5411c84cf080fda76b5f65"
  license "MIT"

  # macOS 13 is the floor declared in Package.swift. The version form ALONE — no bare
  # `depends_on :macos` beside it — is what Homebrew wants; having both is what triggered the
  # deprecation warning a first-time installer would otherwise see before anything else.
  depends_on macos: :ventura

  def install
    system "swift", "build", "-c", "release", "--product", "chute", "--disable-sandbox"
    bin.install ".build/release/chute"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/chute --version")

    file = testpath/"sample.txt"
    file.write("hello")
    output = shell_output("#{bin}/chute paths #{file} --no-copy").strip
    assert_equal file.to_s, output
  end
end
