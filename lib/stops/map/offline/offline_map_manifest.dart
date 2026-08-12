import 'package:maplibre/maplibre.dart' as ml;

final class OfflineMapManifest {
  final String cacheKey;
  final String archivePath;
  final String archiveSha256;
  final int archiveSize;
  final List<String> installFiles;
  final ml.LngLatBounds bounds;
  final double minimumZoom;
  final double maximumNativeZoom;

  const OfflineMapManifest({
    required this.cacheKey,
    required this.archivePath,
    required this.archiveSha256,
    required this.archiveSize,
    required this.installFiles,
    required this.bounds,
    required this.minimumZoom,
    required this.maximumNativeZoom,
  });

  factory OfflineMapManifest.fromJson(Map<String, dynamic> json) {
    final cacheKey = json['cache_key'];
    final archive = json['archive'];
    final installFiles = json['install_files'];
    if (json['schema_version'] != 1 ||
        cacheKey is! String ||
        !RegExp(r'^[a-f0-9]{16}$').hasMatch(cacheKey) ||
        archive is! Map<String, dynamic> ||
        archive['path'] is! String ||
        archive['sha256'] is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(archive['sha256'] as String) ||
        archive['size'] is! int ||
        archive['bounds'] is! List<dynamic> ||
        archive['min_zoom'] is! num ||
        archive['max_zoom'] is! num ||
        installFiles is! List<dynamic> ||
        !installFiles.every(_isSafeRelativePath)) {
      throw const FormatException('Invalid offline map manifest');
    }

    final archivePath = archive['path']! as String;
    final files = installFiles.cast<String>();
    final bounds = archive['bounds']! as List<dynamic>;
    if (!files.contains(archivePath) ||
        bounds.length != 4 ||
        !bounds.every((value) => value is num)) {
      throw const FormatException('Invalid offline map archive');
    }

    return OfflineMapManifest(
      cacheKey: cacheKey,
      archivePath: archivePath,
      archiveSha256: archive['sha256']! as String,
      archiveSize: archive['size']! as int,
      installFiles: List.unmodifiable(files),
      bounds: ml.LngLatBounds(
        longitudeWest: (bounds[0]! as num).toDouble(),
        latitudeSouth: (bounds[1]! as num).toDouble(),
        longitudeEast: (bounds[2]! as num).toDouble(),
        latitudeNorth: (bounds[3]! as num).toDouble(),
      ),
      minimumZoom: (archive['min_zoom']! as num).toDouble(),
      maximumNativeZoom: (archive['max_zoom']! as num).toDouble(),
    );
  }

  static bool _isSafeRelativePath(Object? value) {
    if (value is! String || value.isEmpty || value.startsWith('/')) {
      return false;
    }

    return !value.split('/').contains('..');
  }
}
