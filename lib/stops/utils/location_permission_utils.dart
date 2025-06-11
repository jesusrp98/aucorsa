import 'package:aucorsa/stops/widgets/location_permission_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionUtils {
  const LocationPermissionUtils._();

  static Future<bool> resolve({
    required BuildContext context,
    bool askForPremission = false,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    var permission = await Geolocator.checkPermission();

    if (askForPremission && permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever && askForPremission) {
      if (!context.mounted) return false;
      await showLocationPermissionDialog(context);
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return false;
    }

    return true;
  }
}
