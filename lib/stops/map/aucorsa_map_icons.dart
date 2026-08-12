import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/common/utils/bus_stop_custom_icons.dart';
import 'package:aucorsa/stops/map/aucorsa_map_config.dart';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart' as ml;
import 'package:material_symbols_icons/material_symbols_icons.dart';

abstract final class AucorsaMapIcons {
  static const routeArrowId = 'aucorsa-route-arrow';
  static const stopIcons = [
    Symbols.directions_bus_rounded,
    ...BusStopCustomIcons.values,
  ];

  static String stopIconId(IconData icon) =>
      'aucorsa-stop-${icon.codePoint.toRadixString(16)}';

  static IconData resolveStopIcon(
    int stopId,
    BusStopCustomNameState customDataState,
  ) =>
      BusStopCustomIcons.resolve(customDataState[stopId]?.icon) ??
      Symbols.directions_bus_rounded;

  static Future<void> install(
    ml.StyleController style, {
    required Color stopIconColor,
    required double devicePixelRatio,
  }) async {
    try {
      await Future.wait([
        for (final icon in stopIcons)
          style.addImageFromWidget(
            id: stopIconId(icon),
            logicalSize: const Size.square(AucorsaMapConfig.stopIconSize),
            imageSize: Size.square(
              AucorsaMapConfig.stopIconSize * devicePixelRatio,
            ),
            widget: Icon(
              icon,
              size: AucorsaMapConfig.stopIconSize,
              fill: 1,
              color: stopIconColor,
            ),
          ),
        style.addImageFromWidget(
          id: routeArrowId,
          logicalSize: const Size.square(AucorsaMapConfig.arrowMarkerSize),
          imageSize: Size.square(
            AucorsaMapConfig.arrowMarkerSize * devicePixelRatio,
          ),
          widget: const Icon(
            Symbols.keyboard_arrow_up_rounded,
            size: AucorsaMapConfig.arrowMarkerSize,
            color: Colors.white,
          ),
        ),
      ]);
    } on Exception {
      // The circles remain usable if a native marker image cannot be created.
    }
  }
}
