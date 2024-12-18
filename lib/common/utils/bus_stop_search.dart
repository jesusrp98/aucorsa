import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/common/widgets/bus_stop_tile.dart';
import 'package:flutter/material.dart';
import 'package:search_page/search_page.dart';

Future<void> showBusStopSearch({
  required BuildContext context,
  required List<int> stops,
}) =>
    showSearch<int?>(
      context: context,
      useRootNavigator: true,
      delegate: SearchPage(
        items: stops,
        showItemsOnEmpty: true,
        filter: (stopId) => [
          BusStopUtils.resolveName(stopId),
          stopId.toString(),
        ],
        builder: (stopId) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BusStopTile(
            stopId: stopId,
          ),
        ),
      ),
    );
