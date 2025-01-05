import 'package:aucorsa/about/widgets/about_button.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_search.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class BusLinesPages extends StatelessWidget {
  static const path = '/bus-lines';

  const BusLinesPages({super.key});

  @override
  Widget build(BuildContext context) {
    const lines = BusLineUtils.lines;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: Text(
              context.l10n.busLines,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            actions: const [AboutButton()],
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: 88 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverList.builder(
              itemCount: lines.length,
              itemBuilder: (context, index) => BusLineTile(
                lineId: lines[index].id,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBusStopSearch(
          context: context,
          stops: lines.expand((line) => line.stops).toSet().toList(),
        ),
        child: const Icon(Symbols.search_rounded),
      ),
    );
  }
}
