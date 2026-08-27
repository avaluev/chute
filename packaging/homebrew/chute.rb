class Chute < Formula
  desc "Drop context into your agent — paths, bundles, and tokens for LLM tools"
  homepage "https://chutedev.com"
  # VERSION comes from Sources/ChuteCore/Version.swift — the one place it lives. Bump both
  # together: tag the release, then update this line to match.
  version "0.1.0"
  url "https://github.com/avaluev/chute/archive/refs/tags/v#{version}.tar.gz"
  # PLACEHOLDER — replace before publishing. Once the v#{version} tag exists, compute the real
  # value with:
  #   curl -L https://github.com/avaluev/chute/archive/refs/tags/v#{version}.tar.gz | shasum -a 256
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "MIT"

  depends_on :macos
  depends_on macos: :ventura # macOS 13, the floor declared in Package.swift

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
