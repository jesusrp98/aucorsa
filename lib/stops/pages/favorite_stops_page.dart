import 'package:aucorsa/about/widgets/about_button.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_search.dart';
import 'package:aucorsa/common/widgets/bus_stop_list_view.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:aucorsa/events/models/event.dart';
import 'package:aucorsa/events/models/event_id.dart';
import 'package:aucorsa/events/models/events_calendar.dart';
import 'package:aucorsa/events/widgets/feria_event_tile.dart';
import 'package:aucorsa/stops/cubits/favorite_stops_cubit.dart';
import 'package:aucorsa/stops/widgets/no_favorite_stops_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class FavoriteStopsPage extends StatelessWidget {
  static const path = '/favorite-stops';

  static final currentEvents = EventsCalendar.currentEvents;

  const FavoriteStopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteStops = context.watch<FavoriteStopsCubit>().state;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: Text(
              context.l10n.appName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            actions: const [AboutButton()],
          ),
          _PageSection(
            title: Text(context.l10n.favoritesPageTitle),
            sliver: favoriteStops.isNotEmpty
                ? BusStopListView(
                    stopIds: favoriteStops,
                    padding: currentEvents.isNotEmpty
                        ? const EdgeInsets.only(bottom: 16)
                        : null,
                  )
                : const SliverPadding(
                    padding: EdgeInsets.only(bottom: 16),
                    sliver: SliverToBoxAdapter(child: NoFavoriteStopsTile()),
                  ),
          ),
          if (currentEvents.isNotEmpty)
            _PageSection(
              title: Text(context.l10n.events),
              padding: EdgeInsets.only(
                bottom: 88 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverToBoxAdapter(
                child: ListViewSection(
                  children: [
                    _EventsSection(currentEvents),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: MaterialLocalizations.of(context).searchFieldLabel,
        onPressed: () => showBusStopSearch(
          context: context,
          stops: BusLineUtils.lines
              .expand((line) => line.stops)
              .toSet()
              .toList(),
        ),
        child: const Icon(Symbols.search_rounded),
      ),
    );
  }
}

class _PageSection extends StatelessWidget {
  final Widget title;
  final Widget sliver;
  final EdgeInsets padding;

  const _PageSection({
    required this.title,
    required this.sliver,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return SliverSafeArea(
      top: false,
      bottom: false,
      minimum: padding,
      sliver: sliver,
    );
  }
}

class _EventsSection extends StatelessWidget {
  final List<Event> currentEvents;
  const _EventsSection(this.currentEvents);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final event in currentEvents)
          if (event.id == EventId.feria) const FeriaEventTile(),
      ],
    );
  }
}
