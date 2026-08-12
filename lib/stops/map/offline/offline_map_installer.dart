import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:aucorsa/stops/map/offline/offline_map_manifest.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _offlineMapStylePaths = ['styles/light.json', 'styles/dark.json'];

typedef _DecodedMapPackage = ({
  String manifestJson,
  Map<String, Uint8List> files,
});

final class OfflineMapAssetsUnavailable implements Exception {
  const OfflineMapAssetsUnavailable();
}

final class InstalledOfflineMap {
  final Directory directory;
  final OfflineMapManifest manifest;

  const InstalledOfflineMap({
    required this.directory,
    required this.manifest,
  });
}

/// Installs bundled map data where MapLibre Native can access it directly.
final class OfflineMapInstaller {
  static const bundleAsset = 'assets/offline_map.zip';
  static final shared = OfflineMapInstaller();

  final AssetBundle _assetBundle;
  final Future<Directory> Function() _supportDirectoryProvider;
  Future<InstalledOfflineMap>? _installation;

  OfflineMapInstaller({
    AssetBundle? assetBundle,
    Future<Directory> Function()? supportDirectoryProvider,
  }) : _assetBundle = assetBundle ?? rootBundle,
       _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  Future<InstalledOfflineMap> install() async {
    final cached = _installation;
    if (cached != null) return cached;

    final attempt = _install();
    _installation = attempt;
    try {
      return await attempt;
    } on Object {
      if (identical(_installation, attempt)) _installation = null;
      rethrow;
    }
  }

  Future<InstalledOfflineMap> _install() async {
    final mapPackage = await _loadPackage();
    final manifest = mapPackage.manifest;
    final installFiles = {
      ...manifest.installFiles,
      ..._offlineMapStylePaths,
    };
    final supportDirectory = await _supportDirectoryProvider();
    final installationRoot = Directory('${supportDirectory.path}/offline-map');
    final dataDirectory = Directory(
      '${installationRoot.path}/${manifest.cacheKey}',
    );
    final installationMarker = File('${dataDirectory.path}/.installed');
    final archive = File('${dataDirectory.path}/${manifest.archivePath}');

    await dataDirectory.create(recursive: true);
    final installationIsValid =
        installationMarker.existsSync() &&
        await _matchesArchive(archive, manifest) &&
        installFiles.every(
          (path) => File('${dataDirectory.path}/$path').existsSync(),
        );
    if (!installationIsValid) {
      for (final relativePath in installFiles) {
        await _installAsset(
          mapPackage.files,
          dataDirectory,
          relativePath,
          expectedSha256: relativePath == manifest.archivePath
              ? manifest.archiveSha256
              : null,
        );
      }
      await installationMarker.writeAsString(manifest.cacheKey, flush: true);
    }

    await _deleteObsoleteInstallations(
      installationRoot,
      currentCacheKey: manifest.cacheKey,
    );
    return InstalledOfflineMap(directory: dataDirectory, manifest: manifest);
  }

  Future<({Map<String, Uint8List> files, OfflineMapManifest manifest})>
  _loadPackage() async {
    final ByteData bundleData;
    try {
      bundleData = await _assetBundle.load(bundleAsset);
      // Flutter's asset bundle reports an absent asset as an Error, not an
      // Exception. Here that specifically means this build has no generated
      // map.
      // ignore: avoid_catching_errors
    } on FlutterError {
      throw const OfflineMapAssetsUnavailable();
    }

    final bytes = bundleData.buffer.asUint8List(
      bundleData.offsetInBytes,
      bundleData.lengthInBytes,
    );
    final decoded = await compute(_decodeMapPackage, bytes);
    final manifest = OfflineMapManifest.fromJson(
      jsonDecode(decoded.manifestJson) as Map<String, dynamic>,
    );
    return (files: decoded.files, manifest: manifest);
  }

  Future<void> _installAsset(
    Map<String, Uint8List> files,
    Directory dataDirectory,
    String relativePath, {
    String? expectedSha256,
  }) async {
    final bytes = files[relativePath];
    if (bytes == null) {
      throw FormatException('Offline map package is missing $relativePath');
    }

    final destination = File('${dataDirectory.path}/$relativePath');
    if (destination.existsSync() &&
        destination.lengthSync() == bytes.length &&
        (expectedSha256 == null ||
            await _sha256Of(destination) == expectedSha256)) {
      return;
    }

    await destination.parent.create(recursive: true);
    await destination.writeAsBytes(bytes, flush: true);
  }

  Future<bool> _matchesArchive(
    File archive,
    OfflineMapManifest manifest,
  ) async =>
      archive.existsSync() &&
      archive.lengthSync() == manifest.archiveSize &&
      await _sha256Of(archive) == manifest.archiveSha256;

  Future<String> _sha256Of(File file) async =>
      compute(_sha256Hex, await file.readAsBytes());

  Future<void> _deleteObsoleteInstallations(
    Directory installationRoot, {
    required String currentCacheKey,
  }) async {
    await for (final entity in installationRoot.list()) {
      if (entity is! Directory ||
          entity.uri.pathSegments.where((segment) => segment.isNotEmpty).last ==
              currentCacheKey) {
        continue;
      }

      try {
        await entity.delete(recursive: true);
      } on FileSystemException catch (error) {
        debugPrint('Could not remove old offline map data: $error');
      }
    }
  }
}

_DecodedMapPackage _decodeMapPackage(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final manifestFile = archive.findFile('manifest.json');
  if (manifestFile == null) {
    throw const FormatException('Offline map package has no manifest');
  }

  final manifestJson = utf8.decode(manifestFile.content);
  final manifest = OfflineMapManifest.fromJson(
    jsonDecode(manifestJson) as Map<String, dynamic>,
  );
  final installFiles = {
    ...manifest.installFiles,
    ..._offlineMapStylePaths,
  };
  final files = <String, Uint8List>{};
  for (final relativePath in installFiles) {
    final bundledFile = archive.findFile(relativePath);
    if (bundledFile == null) {
      throw FormatException('Offline map package is missing $relativePath');
    }
    files[relativePath] = Uint8List.fromList(bundledFile.content);
  }

  if (_sha256Hex(files[manifest.archivePath]!) != manifest.archiveSha256) {
    throw const FormatException('Offline map archive checksum mismatch');
  }
  return (manifestJson: manifestJson, files: files);
}

String _sha256Hex(Uint8List bytes) => sha256.convert(bytes).toString();
