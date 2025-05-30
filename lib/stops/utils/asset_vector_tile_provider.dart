import 'package:flutter/services.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

class AssetVectorTileProvider extends VectorTileProvider {
  AssetVectorTileProvider();

  @override
  int get maximumZoom => 14;

  @override
  int get minimumZoom => 11;

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    final assetPath =
        'assets/vector-map-tiles/${tile.z}-${tile.x}-${tile.y}.pbf';

    try {
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      // Return an empty Uint8List if the asset is not found
      return Uint8List(0);
    }
  }

  @override
  TileOffset get tileOffset => TileOffset.DEFAULT;
}
