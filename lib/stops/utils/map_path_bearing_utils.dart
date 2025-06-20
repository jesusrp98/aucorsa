import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_math/flutter_geo_math.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';

class MapPathBearingUtils {
  MapPathBearingUtils._();

  static List<Marker> resolveArrowMarkers({
    required BuildContext context,
    required List<LatLng> path,
    required Color color,
    double size = 16,
  }) {
    final arrowMarkers = <Marker>[];

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

      // Add a marker at the midpoint, rotated to match the bearing angle
      arrowMarkers.add(
        Marker(
          width: size,
          height: size,
          point: LatLng(midLat, midLng),
          child: Transform.rotate(
            angle: angle,
            child: CircleAvatar(
              backgroundColor: color,
              foregroundColor: Colors.white,
              radius: size / 2,
              child: Icon(Symbols.keyboard_arrow_up_rounded, size: size),
            ),
          ),
        ),
      );
    }

    return arrowMarkers;
  }

  static double _bearingBetween(LatLng a, LatLng b) =>
      FlutterMapMath.bearingBetween(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      ) *
      (pi / 180);
}
