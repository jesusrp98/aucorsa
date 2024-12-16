import 'package:aucorsa/common/widgets/bus_stop_tile.dart';
import 'package:flutter/material.dart';

class BusStopListView extends StatelessWidget {
  final List<int> stopIds;

  const BusStopListView({
    required this.stopIds,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverSafeArea(
      minimum: const EdgeInsets.only(bottom: 64),
      top: false,
      sliver: SliverList.builder(
        itemCount: stopIds.length,
        itemBuilder: (context, index) => BusStopTile(
          stopId: stopIds[index],
        ),
      ),
    );
  }
}
