import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/common/utils/search_page.dart';
import 'package:aucorsa/common/widgets/bus_stop_tile.dart';
import 'package:flutter/material.dart';

Future<void> showBusStopSearch({
  required BuildContext context,
  required List<int> stops,
}) => showSearch<int?>(
  context: context,
  useRootNavigator: true,
  delegate: SearchPage(
    items: stops,
    showItemsOnEmpty: true,
    filter: (stopId) => [BusStopUtils.resolveName(stopId), stopId.toString()],
    separatorBuilder: (context, index) => const SizedBox(height: 4),
    builder: (stopId) => BusStopTile(key: ValueKey(stopId), stopId: stopId),
  ),
);
