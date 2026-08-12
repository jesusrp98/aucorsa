import 'package:aucorsa/stops/map/offline/offline_map_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> manifestJson() => {
    'schema_version': 1,
    'cache_key': '0123456789abcdef',
    'archive': {
      'path': 'cordoba.pmtiles',
      'sha256':
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      'size': 3,
      'bounds': [-5.27, 37.57, -4.39, 38.27],
      'min_zoom': 11,
      'max_zoom': 14,
    },
    'install_files': ['cordoba.pmtiles', 'glyphs/font/0-255.pbf'],
  };

  test('parses map coverage and zoom metadata', () {
    final manifest = OfflineMapManifest.fromJson(manifestJson());

    expect(manifest.cacheKey, '0123456789abcdef');
    expect(
      manifest.archiveSha256,
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    );
    expect(manifest.archiveSize, 3);
    expect(manifest.bounds.longitudeWest, -5.27);
    expect(manifest.bounds.latitudeSouth, 37.57);
    expect(manifest.bounds.longitudeEast, -4.39);
    expect(manifest.bounds.latitudeNorth, 38.27);
    expect(manifest.minimumZoom, 11);
    expect(manifest.maximumNativeZoom, 14);
  });

  test('rejects paths that can escape the map installation directory', () {
    final json = manifestJson();
    json['install_files'] = ['cordoba.pmtiles', '../outside'];

    expect(
      () => OfflineMapManifest.fromJson(json),
      throwsFormatException,
    );
  });

  test('requires the archive to be included in installation files', () {
    final json = manifestJson();
    json['install_files'] = ['glyphs/font/0-255.pbf'];

    expect(
      () => OfflineMapManifest.fromJson(json),
      throwsFormatException,
    );
  });
}
