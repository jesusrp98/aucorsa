import 'package:aucorsa/common/models/bus_stop_custom_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Result of one attempt to mirror app state into the shared container.
enum AppGroupSyncOutcome {
  /// The payload reached the App Group container.
  synced,

  /// Not an iOS build, so there is nothing to mirror to.
  unsupported,

  /// The container could not be resolved. Almost always means the App Group is
  /// not provisioned for this build, which is a setup problem rather than a
  /// transient one — the intents will keep seeing no favourites until it is
  /// fixed.
  unavailable,

  /// The channel or the write failed for some other reason.
  failed,
}

/// Signature of [AppGroupBridge.sync], so callers can inject a fake.
typedef AppGroupSyncCallback =
    Future<AppGroupSyncOutcome> Function({
      required List<int> favorites,
      required Map<int, BusStopCustomData> customData,
    });

/// Mirrors the slice of app state the iOS App Intents layer needs into the
/// shared App Group container.
///
/// Favourites and custom stop names live in `HydratedCubit`s, whose on-disk
/// format is an implementation detail of the package. Rather than have Swift
/// read that, the app pushes a small, versioned payload across a method channel
/// and the native side writes it (see `AppGroupChannel.swift`).
///
/// Failures are reported rather than thrown: mirroring is best-effort and must
/// never break the app, but the caller still needs to know, because a silent
/// failure means Siri quietly stops knowing the user's stops.
class AppGroupBridge {
  const AppGroupBridge._();

  static const _channel = MethodChannel('com.chechu.aucorsa/app_group');

  static bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Pushes the current favourites and custom stop data to the shared
  /// container. Safe to call often; the payload is a few kilobytes.
  static Future<AppGroupSyncOutcome> sync({
    required List<int> favorites,
    required Map<int, BusStopCustomData> customData,
  }) async {
    if (!_isSupported) return AppGroupSyncOutcome.unsupported;

    try {
      await _channel.invokeMethod<void>('syncUserData', {
        'favorites': favorites,
        'customNames': {
          for (final entry in customData.entries)
            entry.key.toString(): {
              'name': entry.value.name,
              'icon': entry.value.icon,
            },
        },
      });

      return AppGroupSyncOutcome.synced;
    } on PlatformException catch (error) {
      return error.code == 'unavailable'
          ? AppGroupSyncOutcome.unavailable
          : AppGroupSyncOutcome.failed;
    } on MissingPluginException {
      return AppGroupSyncOutcome.unavailable;
    }
  }
}
