import Foundation

/// The one place the version number lives.
///
/// It used to live in four: `Scripts/build-app.sh`, `chute --version`, `chute doctor`, and the git
/// tag. Four copies drift the moment a release script touches one of them, and a version that
/// disagrees with itself is the first thing a paying customer notices when they report a bug.
///
/// `Scripts/build-app.sh` greps the literal below to stamp both Info.plists, so keep the
/// declaration on one line and in this exact shape.
public enum ChuteVersion {
    public static let current = "0.2.0"
}
