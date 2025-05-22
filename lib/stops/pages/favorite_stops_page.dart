import 'package:aucorsa/about/widgets/about_button.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_search.dart';
import 'package:aucorsa/common/widgets/big_tip.dart';
import 'package:aucorsa/common/widgets/bus_stop_list_view.dart';
import 'package:aucorsa/events/models/event.dart';
import 'package:aucorsa/events/models/event_id.dart';
import 'package:aucorsa/events/models/events_calendar.dart';
import 'package:aucorsa/events/widgets/feria_event_tile.dart';
import 'package:aucorsa/stops/cubits/favorite_stops_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class FavoriteStopsPage extends StatelessWidget {
  static const path = '/favorite-stops';

  const FavoriteStopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteStops = context.watch<FavoriteStopsCubit>().state;
    final currentEvents = EventsCalendar.currentEvents;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          if (favoriteStops.isNotEmpty) ...[
            SliverAppBar.medium(
              title: Text(
                context.l10n.appName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              actions: const [AboutButton()],
            ),
            _PageSection(
              title: Text(context.l10n.favoritesPageTitle),
              child: BusStopListView(
                stopIds: favoriteStops,
                padding: const EdgeInsets.only(bottom: 16),
              ),
            ),
            if (currentEvents.isNotEmpty)
              _PageSection(
                title: Text(context.l10n.events),
                child: SliverPadding(
                  padding: const EdgeInsets.only(bottom: 16),
                  sliver: SliverToBoxAdapter(
                    child: _EventsSection(currentEvents),
                  ),
                ),
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
  final Widget child;

  const _PageSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverSafeArea(
      top: false,
      bottom: false,
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(
                16,
              ).copyWith(top: 0, bottom: 8, right: 8),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                child: title,
              ),
            ),
          ),
          child,
        ],
      ),
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
