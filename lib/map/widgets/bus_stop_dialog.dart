import 'package:aucorsa/common/widgets/bus_stop_tile.dart';
import 'package:flutter/material.dart';

Future<void> showBusStopDialog(BuildContext context, int stopId) =>
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeRight: true,
        child: BusStopTile(
          stopId: stopId,
          alwaysExpanded: true,
        ),
      ),
    );
