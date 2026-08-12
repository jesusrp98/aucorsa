import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

@immutable
class MapPathArrow {
  final LatLng point;
  final double angle;

  const MapPathArrow({required this.point, required this.angle});
}

class MapPathBearingUtils {
  MapPathBearingUtils._();

  static List<MapPathArrow> resolveArrows({
    required List<LatLng> path,
  }) {
    final arrows = <MapPathArrow>[];

    // Iterate through the path, skipping every 3 points to reduce density
    for (var i = 0; i < path.length - 1; i += 3) {
      // Get the start and end points of the current segment
      final start = path[i];
      final end = path[i + 1];

      // Calculate the midpoint of the segment
      final midLat = (start.latitude + end.latitude) / 2;
      final midLng = (start.longitude + end.longitude) / 2;

      // Calculate the bearing angle between the start and end points
      final angle = _bearingBetween(start, end);

      arrows.add(
        MapPathArrow(point: LatLng(midLat, midLng), angle: angle),
      );
    }

    return arrows;
  }

  static double _bearingBetween(LatLng a, LatLng b) {
    final startLatitude = a.latitude * pi / 180;
    final endLatitude = b.latitude * pi / 180;
    final longitudeDelta = (b.longitude - a.longitude) * pi / 180;
    final y = sin(longitudeDelta) * cos(endLatitude);
    final x =
        cos(startLatitude) * sin(endLatitude) -
        sin(startLatitude) * cos(endLatitude) * cos(longitudeDelta);

    return atan2(y, x);
  }
}
