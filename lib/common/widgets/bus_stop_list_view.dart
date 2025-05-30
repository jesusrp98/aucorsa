import 'package:aucorsa/common/widgets/bus_stop_tile.dart';
import 'package:flutter/material.dart';

class BusStopListView extends StatelessWidget {
  final List<int> stopIds;
  final EdgeInsets? padding;

  const BusStopListView({required this.stopIds, this.padding, super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding:
          padding ??
          EdgeInsets.only(bottom: 88 + MediaQuery.paddingOf(context).bottom),
      sliver: SliverList.separated(
        itemCount: stopIds.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            BusStopTile(key: ValueKey(stopIds[index]), stopId: stopIds[index]),
      ),
    );
  }
}
