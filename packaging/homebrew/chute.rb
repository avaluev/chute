class Chute < Formula
  desc "Drop context into your agent — paths, bundles, and tokens for LLM tools"
  homepage "https://chutedev.com"
  # VERSION comes from Sources/ChuteCore/Version.swift — the one place it lives. Bump both
  # together: tag the release, then update this line to match.
  version "0.2.0"
  url "https://github.com/avaluev/chute/archive/refs/tags/v#{version}.tar.gz"
  # Recompute on every version bump:
  #   curl -L https://github.com/avaluev/chute/archive/refs/tags/v0.2.0.tar.gz | shasum -a 256
  sha256 "e7c3ea3aec0357b8864c0389a14c99fa07126495a789b0179e1dd180fb280208"
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
