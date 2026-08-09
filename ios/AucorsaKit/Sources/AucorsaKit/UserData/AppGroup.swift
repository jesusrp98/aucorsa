import Foundation

/// The shared container the Flutter app and the intents both reach into.
///
/// Requires the App Group capability on every target that touches it; see
/// `ios/Runner/Runner.entitlements`.
public enum AppGroup {
    public static let identifier = "group.com.chechu.aucorsa"

    /// Nil when the entitlement is missing or the group is not provisioned.
    /// Callers degrade rather than trap: a missing container means "no
    /// favourites yet", not a crash inside Siri.
    public static var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        )
    }

    public static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    /// Written by Flutter (`AppGroupBridge`), read by Swift (`UserDataStore`).
    public static var userDataURL: URL? {
        containerURL?.appendingPathComponent("user_data.json")
    }
}
