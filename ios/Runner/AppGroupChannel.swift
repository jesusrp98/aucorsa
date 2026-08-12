import AppIntents
import AucorsaKit
import Flutter
import Foundation
import os

/// Receives favourites and custom stop names from Flutter and writes them into
/// the shared App Group container, where the App Intents layer reads them.
///
/// The Dart counterpart is `lib/common/utils/app_group_bridge.dart`.
enum AppGroupChannel {
    static let name = "com.chechu.aucorsa/app_group"

    private static let logger = Logger(
        subsystem: "com.chechu.aucorsa", category: "AppGroupChannel"
    )

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)

        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "syncUserData":
                result(handleSync(arguments: call.arguments))
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    /// Returns nil on success, or a `FlutterError` describing why the mirror
    /// could not be written. The Dart side treats every failure as non-fatal.
    private static func handleSync(arguments: Any?) -> Any? {
        guard let arguments = arguments as? [String: Any] else {
            return FlutterError(
                code: "bad_arguments",
                message: "syncUserData expects a map",
                details: nil
            )
        }

        let favorites = (arguments["favorites"] as? [NSNumber])?.map(\.intValue) ?? []

        var customNames: [String: CustomStopData] = [:]
        if let raw = arguments["customNames"] as? [String: [String: Any]] {
            for (stopID, value) in raw {
                // NSNull arrives for Dart nulls across the channel.
                customNames[stopID] = CustomStopData(
                    name: value["name"] as? String,
                    icon: (value["icon"] as? NSNumber)?.intValue
                )
            }
        }

        let userData = UserData(
            version: UserData.currentVersion,
            favorites: favorites,
            customNames: customNames
        )

        do {
            try UserDataStore.shared.save(userData)
        } catch UserDataStore.StoreError.containerUnavailable {
            logger.error("App Group container unavailable; is the group provisioned?")
            return FlutterError(
                code: "unavailable",
                message: "The App Group container is not available",
                details: AppGroup.identifier
            )
        } catch {
            logger.error("Failed to write user_data.json: \(error)")
            return FlutterError(
                code: "write_failed",
                message: "Could not write to the App Group container",
                details: String(describing: error)
            )
        }

        // Favourites drive `suggestedEntities`, so Siri's cached parameter
        // values are stale until it is told to re-read them.
        AucorsaShortcuts.updateAppShortcutParameters()

        // Custom stop names are part of what gets indexed, so a rename should
        // reach Spotlight too. No-ops when nothing relevant changed.
        SpotlightIndexer.indexIfNeeded()

        return nil
    }
}
