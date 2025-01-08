import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_search.dart';
import 'package:aucorsa/common/widgets/bus_stop_list_view.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

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
              context.l10n.busLine(line.id),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          BusStopListView(
            stopIds: line.stops,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: MaterialLocalizations.of(context).searchFieldLabel,
        onPressed: () => showBusStopSearch(
          context: context,
          stops: line.stops,
        ),
        child: const Icon(Symbols.search_rounded),
      ),
    );
  }
}
