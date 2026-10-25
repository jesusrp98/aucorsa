import 'dart:async';

import 'package:aucorsa/about/widgets/about_button.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/common/widgets/bus_stop_list_view.dart';
import 'package:aucorsa/common/widgets/bus_stop_tile.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:aucorsa/events/models/event.dart';
import 'package:aucorsa/events/models/event_id.dart';
import 'package:aucorsa/events/models/events_calendar.dart';
import 'package:aucorsa/events/widgets/feria_event_tile.dart';
import 'package:aucorsa/stops/cubits/favorite_stops_cubit.dart';
import 'package:aucorsa/stops/widgets/bus_stop_dialog.dart';
import 'package:aucorsa/stops/widgets/no_favorite_stops_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class FavoriteStopsPage extends StatefulWidget {
  static const path = '/favorite-stops';

  static final currentEvents = EventsCalendar.currentEvents;

  const new({this.stopToOpen, super.key});

  final String? stopToOpen;

  @override
  State<FavoriteStopsPage> createState() => _FavoriteStopsPageState();
}

class _FavoriteStopsPageState extends State<FavoriteStopsPage> {
  final _scrollController = ScrollController();
  final _stopKeys = <int, GlobalKey>{};
  int? _expandedStopID;
  var _request = 0;

  @override
  void initState() {
    super.initState();
    _scheduleRequestedStop();
  }

  @override
  void didUpdateWidget(covariant FavoriteStopsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stopToOpen != oldWidget.stopToOpen) _scheduleRequestedStop();
  }

  void _scheduleRequestedStop() {
    final stop = widget.stopToOpen;
    if (stop == null) return;
    final request = ++_request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || request != _request) return;
      unawaited(_openStop(stop, request));
    });
  }

  Future<void> _openStop(String stop, int request) async {
    // An activity can be tapped again while a previous stop sheet is open.
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route is PageRoute);
    // Consume the request so a later tap on the same activity opens it again.
    context.go(FavoriteStopsPage.path);
    final stopID = int.tryParse(stop);
    if (stopID == null || BusStopUtils.resolveName(stopID).isEmpty) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(context.l10n.liveActivityInvalidStop),
          ),
        );
      return;
    }

    if (!context.read<FavoriteStopsCubit>().isFavorite(stopID)) {
      // Let navigation settle before presenting the existing map stop sheet.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || request != _request) return;
      await showBusStopDialog(context, stopID);
      return;
    }

    setState(() => _expandedStopID = stopID);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || request != _request || !_scrollController.hasClients) {
      return;
    }

    // SliverList builds lazily. Walk forward from the top until the target is
    // laid out, then reveal it precisely without assuming fixed card heights.
    if (_stopKeys[stopID]?.currentContext == null) _scrollController.jumpTo(0);
    while (mounted && request == _request && _scrollController.hasClients) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || request != _request || !_scrollController.hasClients) {
        return;
      }
      final target = _stopKeys[stopID]?.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(target, alignment: .1);
        if (mounted && request == _request) {
          // The card owns its expansion from here, including manual collapse.
          setState(() => _expandedStopID = null);
        }
        return;
      }
      final position = _scrollController.position;
      final next = (position.pixels + position.viewportDimension).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (next <= position.pixels) return;
      _scrollController.jumpTo(next);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoriteStops = context.watch<FavoriteStopsCubit>().state;
    final currentEvents = FavoriteStopsPage.currentEvents;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
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
                    stopBuilder: (_, stopID) => BusStopTile(
                      key: _stopKeys.putIfAbsent(stopID, GlobalKey.new),
                      stopId: stopID,
                      expandRequest: stopID == _expandedStopID
                          ? _request
                          : null,
                    ),
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
                  children: [_EventsSection(currentEvents)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PageSection extends StatelessWidget {
  final Widget title;
  final Widget sliver;
  final EdgeInsets padding;

  const new({
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
  const new(this.currentEvents);

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
