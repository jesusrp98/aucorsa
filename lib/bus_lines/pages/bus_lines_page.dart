import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:flutter/material.dart';

class BusLinesPages extends StatelessWidget {
  static const path = '/bus-lines';

  const BusLinesPages({super.key});

  @override
  Widget build(BuildContext context) {
    const lines = BusLineUtils.lines;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.medium(
            title: Text(
              'Líneas',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 8),
            sliver: SliverList.builder(
              itemCount: lines.length,
              itemBuilder: (context, index) => BusLineTile(
                lineId: lines[index].id,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
