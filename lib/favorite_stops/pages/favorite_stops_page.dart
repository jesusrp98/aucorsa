import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_search.dart';
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
          const SliverAppBar.medium(
            title: Text(
              'Favoritos',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          BusStopListView(
            stopIds: favoriteStops,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
