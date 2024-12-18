import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_search.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:aucorsa/favorite_stops/cubits/favorite_stops_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          const SliverAppBar.medium(
            title: Text(
              'Líneas',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
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
          stops: context.read<FavoriteStopsCubit>().state,
        ),
        child: const Icon(Symbols.search_rounded),
      ),
    );
  }
}
