import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart' as ml;

abstract final class AucorsaMapConfig {
  static const defaultCenter = ml.Geographic(
    lon: -4.7871324,
    lat: 37.8916417,
  );

  static const stopDetailZoom = 15.5;
  static const defaultCenterZoom = 13.0;
  static const userLocationZoom = 18.0;
  static const maximumZoom = 20.0;

  static const arrowMarkerSize = 16.0;
  static const arrowMarkerRadius = 8;
  static const dotMarkerRadius = 4;
  static const stopMarkerRadius = 16;
  static const stopIconSize = 24.0;

  static const routeArrowBearingProperty = 'aucorsa_route_arrow_bearing';
  static const routeColorProperty = 'aucorsa_route_color';
  static const stopIdProperty = 'aucorsa_stop_id';

  static const baseMapColor = {
    Brightness.light: Color(0xFFEEEEEE),
    Brightness.dark: Color(0xFF333333),
  };

  static bool contains(
    ml.LngLatBounds bounds, {
    required double longitude,
    required double latitude,
  }) =>
      longitude >= bounds.longitudeWest &&
      longitude <= bounds.longitudeEast &&
      latitude >= bounds.latitudeSouth &&
      latitude <= bounds.latitudeNorth;
}
