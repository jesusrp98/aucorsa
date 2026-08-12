import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:aucorsa/stops/map/offline/offline_map_installer.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory supportDirectory;
  late Uint8List archiveBytes;
  late _MemoryAssetBundle assetBundle;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'aucorsa-map-installer-',
    );
    archiveBytes = Uint8List.fromList([1, 2, 3, 4]);
    assetBundle = _MemoryAssetBundle({
      OfflineMapInstaller.bundleAsset: _offlineMapBundle(archiveBytes),
    });
  });

  tearDown(() async {
    if (supportDirectory.existsSync()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  OfflineMapInstaller installer() => OfflineMapInstaller(
    assetBundle: assetBundle,
    supportDirectoryProvider: () async => supportDirectory,
  );

  test('does not retain a failed installation future', () async {
    assetBundle.bundleFailuresRemaining = 1;
    final mapInstaller = installer();

    await expectLater(
      mapInstaller.install(),
      throwsA(isA<OfflineMapAssetsUnavailable>()),
    );
    final installation = await mapInstaller.install();

    expect(installation.manifest.archiveSize, archiveBytes.length);
    expect(assetBundle.bundleLoads, 2);
  });

  test(
    'installs data, writes its marker, and removes an old version',
    () async {
      final oldDirectory = Directory(
        '${supportDirectory.path}/offline-map/old-cache',
      );
      await oldDirectory.create(recursive: true);
      await File('${oldDirectory.path}/old.pmtiles').writeAsBytes([9]);

      final installation = await installer().install();
      final installedArchive = File(
        '${installation.directory.path}/cordoba.pmtiles',
      );

      expect(await installedArchive.readAsBytes(), archiveBytes);
      expect(
        File('${installation.directory.path}/.installed').existsSync(),
        isTrue,
      );
      expect(oldDirectory.existsSync(), isFalse);
    },
  );

  test('repairs an equal-length archive with the wrong checksum', () async {
    final firstInstallation = await installer().install();
    final installedArchive = File(
      '${firstInstallation.directory.path}/cordoba.pmtiles',
    );
    await installedArchive.writeAsBytes([9, 9, 9, 9], flush: true);

    await installer().install();

    expect(await installedArchive.readAsBytes(), archiveBytes);
  });
}

String _manifestJson(Uint8List archiveBytes) => jsonEncode({
  'schema_version': 1,
  'cache_key': '0123456789abcdef',
  'archive': {
    'path': 'cordoba.pmtiles',
    'sha256': sha256.convert(archiveBytes).toString(),
    'size': archiveBytes.length,
    'bounds': [-5.27, 37.57, -4.39, 38.27],
    'min_zoom': 11,
    'max_zoom': 14,
  },
  'install_files': ['cordoba.pmtiles', 'glyphs/font.pbf'],
});

Uint8List _offlineMapBundle(Uint8List archiveBytes) {
  final archive = Archive()
    ..addFile(ArchiveFile.string('manifest.json', _manifestJson(archiveBytes)))
    ..addFile(ArchiveFile.bytes('cordoba.pmtiles', archiveBytes))
    ..addFile(ArchiveFile.bytes('glyphs/font.pbf', [5, 6]))
    ..addFile(ArchiveFile.string('styles/light.json', '{}'))
    ..addFile(ArchiveFile.string('styles/dark.json', '{}'));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

final class _MemoryAssetBundle extends CachingAssetBundle {
  final Map<String, Uint8List> assets;
  int bundleFailuresRemaining = 0;
  int bundleLoads = 0;

  _MemoryAssetBundle(this.assets);

  @override
  Future<ByteData> load(String key) async {
    if (key == OfflineMapInstaller.bundleAsset) {
      bundleLoads++;
      if (bundleFailuresRemaining > 0) {
        bundleFailuresRemaining--;
        throw FlutterError('Temporary map bundle failure');
      }
    }

    final bytes = assets[key];
    if (bytes == null) throw FlutterError('Missing asset: $key');

    return ByteData.sublistView(bytes);
  }
}
