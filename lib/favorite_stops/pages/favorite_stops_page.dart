import 'package:aucorsa/about/widgets/about_button.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_search.dart';
import 'package:aucorsa/common/widgets/big_tip.dart';
import 'package:aucorsa/common/widgets/bus_stop_list_view.dart';
import 'package:aucorsa/favorite_stops/cubits/favorite_stops_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class FavoriteStopsPage extends StatelessWidget {
  static const path = '/favorite-stops';

  const FavoriteStopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteStops = context.watch<FavoriteStopsCubit>().state;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          if (favoriteStops.isNotEmpty) ...[
            SliverAppBar.medium(
              title: Text(
                context.l10n.favoritesPageTitle,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              actions: const [AboutButton()],
            ),
            BusStopListView(
              stopIds: favoriteStops,
            ),
          ] else
            SliverFillRemaining(
              child: BigTip(
                title: Text(context.l10n.noFavoritesTitle),
                subtitle: Text(context.l10n.noFavoritesSubtitle),
                child: const Icon(Symbols.favorite_rounded),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: MaterialLocalizations.of(context).searchFieldLabel,
        onPressed: () => showBusStopSearch(
          context: context,
          stops:
              BusLineUtils.lines.expand((line) => line.stops).toSet().toList(),
        ),
        child: const Icon(Symbols.search_rounded),
      ),
    );
  }
}
