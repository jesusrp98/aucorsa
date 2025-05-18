import 'package:aucorsa/bus_lines/pages/bus_line_map_page.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_search.dart';
import 'package:aucorsa/common/widgets/bus_stop_list_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          FloatingActionButton(
            heroTag: null,
            tooltip: MaterialLocalizations.of(context).searchFieldLabel,
            shape: const CircleBorder(),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            onPressed: () => context.push(
              BusLineMapPage.path,
              extra: lineId,
            ),
            child: const Icon(Symbols.map_rounded),
          ),
          FloatingActionButton(
            tooltip: MaterialLocalizations.of(context).searchFieldLabel,
            onPressed: () => showBusStopSearch(
              context: context,
              stops: line.stops,
            ),
            child: const Icon(Symbols.search_rounded),
          ),
        ],
      ),
    );
  }
}
