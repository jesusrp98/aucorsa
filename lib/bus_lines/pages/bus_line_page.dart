import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/widgets/bus_stop_list_view.dart';
import 'package:flutter/material.dart';

class BusLinePage extends StatelessWidget {
  static const path = '/bus-line';

  final String lineId;

  const BusLinePage({
    required this.lineId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final line = BusLineUtils.getLine(lineId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: Text(
              'Línea $lineId',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          BusStopListView(
            stopIds: line.stops,
          ),
        ],
      ),
    );
  }
}
