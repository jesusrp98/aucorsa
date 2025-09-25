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
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: index == 0
                ? const Radius.circular(24)
                : const Radius.circular(4),
            bottom: index == stopIds.length - 1
                ? const Radius.circular(24)
                : const Radius.circular(4),
          ),
          child: BusStopTile(stopId: stopIds[index]),
        ),
      ),
    );
  }
}
