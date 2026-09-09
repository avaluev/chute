class Chute < Formula
  desc "Terminal half of Chute, the macOS menu bar and Finder menu for coding agents"
  homepage "https://chutedev.com"
  # VERSION comes from Sources/ChuteCore/Version.swift — the one place it lives. Bump both
  # together: tag the release, then update this line to match.
  #
  # IN SYNC as of 2026-09-09. This file is a COPY, not the tap — publishing means running
  # packaging/homebrew/README.md's steps 4-6 against avaluev/homebrew-tap. Verified that day:
  # the live tap and this file pin the same version and the same sha256, and that sha256 is
  # what the tarball actually hashes to. An outdated note here saying otherwise is worse than
  # no note — one such note, left over from 2026-09-08, was read by an outside auditor in
  # 2026-09-09 as evidence that `brew install` was broken. If you correct this file, correct
  # this paragraph in the same commit.
  version "0.2.1"
  url "https://github.com/avaluev/chute/archive/refs/tags/v#{version}.tar.gz"
  # Recompute on every version bump — AND after any history rewrite. A force-push changes
  # every tag's generated tarball: on 2026-09-09 the rewrite that removed private files
  # silently broke `brew install avaluev/tap/chute` for every new user, and it took THREE
  # corrective commits that day to settle, because the failure only shows on a cold cache.
  #   curl -L https://github.com/avaluev/chute/archive/refs/tags/v0.2.1.tar.gz | shasum -a 256
  # CHECK IT WITH `brew fetch --force avaluev/tap/chute`, NOT `brew install` — install is happy
  # with a tarball it already cached, so it is structurally incapable of catching this bug.
  sha256 "136e265150014cf625769a6c0a64e672141563a50543919a65c4f3cae9ebe285"
  license "MIT"

  # macOS 13 is the floor declared in Package.swift. The version form ALONE — no bare
  # `depends_on :macos` beside it — is what Homebrew wants; having both is what triggered the
  # deprecation warning a first-time installer would otherwise see before anything else.
  depends_on macos: :ventura

  def install
    system "swift", "build", "-c", "release", "--product", "chute", "--disable-sandbox"
    # STRIPPED, because the site says "under 1 MB" and an unstripped SwiftPM release build is
    # 1,276,952 bytes — 1.28 MB. Scripts/build-app.sh already strips the copy that goes inside
    # Chute.app, so the claim was true of the bundled binary and false of the ONLY binary this
    # formula installs, on the very page whose only install method is Homebrew. Found 2026-09-09.
    # `strip -x` keeps the dynamic symbols the linker needs and drops the debug table: 880,488
    # bytes, and `chute --version` still answers, which the test block below proves.
    system "strip", "-x", ".build/release/chute"
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
