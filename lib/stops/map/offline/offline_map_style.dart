import 'dart:convert';
import 'dart:io';

import 'package:aucorsa/stops/map/offline/offline_map_installer.dart';
import 'package:flutter/services.dart';
import 'package:maplibre/maplibre.dart' as ml;

final class PreparedOfflineMap {
  final String styleJson;
  final ml.LngLatBounds bounds;
  final double minimumZoom;
  final double maximumNativeZoom;

  const PreparedOfflineMap({
    required this.styleJson,
    required this.bounds,
    required this.minimumZoom,
    required this.maximumNativeZoom,
  });
}

/// Prepares a MapLibre style backed by the installed offline Córdoba map.
class OfflineMapStyle {
  OfflineMapStyle._();

  static Future<PreparedOfflineMap> prepare(Brightness brightness) async {
    final installation = await OfflineMapInstaller.shared.install();
    final dataDirectory = installation.directory;
    final manifest = installation.manifest;

    final styleName = brightness == Brightness.dark ? 'dark' : 'light';
    final styleJson = await File(
      '${dataDirectory.path}/styles/$styleName.json',
    ).readAsString();
    final style = jsonDecode(styleJson) as Map<String, dynamic>;
    final sources = style['sources']! as Map<String, dynamic>;
    final source = sources['openmaptiles']! as Map<String, dynamic>;
    final pmtilesUri = Uri.file(
      '${dataDirectory.path}/${manifest.archivePath}',
    ).toString();
    final spriteDirectory = brightness == Brightness.dark
        ? 'alidade-smooth-dark'
        : 'alidade-smooth';

    source
      ..remove('tiles')
      ..['url'] = 'pmtiles://$pmtilesUri';
    style['sprite'] = Uri.file(
      '${dataDirectory.path}/sprites/$spriteDirectory/sprite',
    ).toString();
    style['glyphs'] =
        '${Uri.file('${dataDirectory.path}/glyphs/')}{fontstack}/{range}.pbf';

    return PreparedOfflineMap(
      styleJson: jsonEncode(style),
      bounds: manifest.bounds,
      minimumZoom: manifest.minimumZoom,
      maximumNativeZoom: manifest.maximumNativeZoom,
    );
  }
}
