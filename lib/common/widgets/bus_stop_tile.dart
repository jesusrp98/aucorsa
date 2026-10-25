import 'dart:async';
import 'dart:math';

import 'package:aucorsa/common/cubits/bus_service_cubit.dart';
import 'package:aucorsa/common/cubits/bus_stop_cubit.dart';
import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/common/models/bus_stop_custom_data.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/aucorsa_state_status.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_custom_icons.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/common/widgets/aucorsa_shimmer.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:aucorsa/common/widgets/bus_stop_options_menu.dart';
import 'package:aucorsa/live_activity/live_activity_controls.dart';
import 'package:aucorsa/stops/cubits/favorite_stops_cubit.dart';
import 'package:aucorsa/stops/pages/favorite_stops_page.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:duration/duration.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_ui/material_ui.dart';

class BusStopTile extends StatelessWidget {
  final int stopId;
  final bool alwaysExpanded;

  /// A new non-null value opens the card without changing its tap behavior.
  final Object? expandRequest;

  const new({
    required this.stopId,
    super.key,
    this.alwaysExpanded = false,
    this.expandRequest,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BusStopCubit(
        busServiceCubit: context.read<BusServiceCubit>(),
        stopId: stopId,
      ),
      child: _BusStopTileView(
        stopId: stopId,
        alwaysExpanded: alwaysExpanded,
        expandRequest: expandRequest,
      ),
    );
  }
}

class _BusStopTileView extends StatefulWidget {
  final int stopId;
  final bool alwaysExpanded;
  final Object? expandRequest;

  const new({
    required this.stopId,
    this.alwaysExpanded = false,
    this.expandRequest,
  });

  @override
  State<_BusStopTileView> createState() => _BusStopTileViewState();
}

class _BusStopTileViewState extends State<_BusStopTileView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _curve = Curves.easeInOutCubic;
  static const _duration = Durations.medium2;

  static final _easeInCurve = CurveTween(curve: _curve);
  static final _halfTurn = Tween<double>(begin: 0, end: 0.5);

  late final Animation<double> _heightFactor;
  late final Animation<double> _iconTurns;
  late final AnimationController _controller;

  late var _expanded = widget.alwaysExpanded || widget.expandRequest != null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _controller = AnimationController(
      duration: _duration,
      value: _expanded ? 1 : 0,
      vsync: this,
    );

    _heightFactor = _controller.drive(_easeInCurve);
    _iconTurns = _controller.drive(_halfTurn.chain(_easeInCurve));

    if (_expanded) {
      unawaited(_requestData());
    }
    _updateAutoRefresh();
  }

  @override
  void didUpdateWidget(covariant _BusStopTileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expandRequest != null &&
        widget.expandRequest != oldWidget.expandRequest) {
      _expanded = true;
      _controller.value = 1;
      _updateAutoRefresh();
      unawaited(_requestData());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<BusStopCubit>().setAutoRefresh(
      enabled: _expanded && state == AppLifecycleState.resumed,
    );
    // Refresh data when the app is resumed and it's expanded
    if (_expanded && state == AppLifecycleState.resumed) {
      unawaited(_requestData());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<FavoriteStopsCubit, bool>(
      (cubit) => cubit.isFavorite(widget.stopId),
    );

    final busStopCustomData = context.watch<BusStopCustomDataCubit>().get(
      widget.stopId,
    );

    return SafeArea(
      top: false,
      bottom: widget.alwaysExpanded,
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onTap: _onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: _duration,
                curve: _curve,
                color: _expanded
                    ? Theme.of(context).colorScheme.surfaceContainer
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16)
                      .copyWith(right: 20),
                  leading: SizedBox.square(
                    dimension: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                      child: Icon(
                        _resolveIcon(busStopCustomData, isFavorite),
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                        fill: 1,
                      ),
                    ),
                  ),
                  title: AutoSizeText(
                    _resolveTitle(busStopCustomData),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                  ),
                  subtitle: AutoSizeText(
                    _resolveSubtitle(busStopCustomData),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    minFontSize: 14,
                  ),
                  trailing: widget.alwaysExpanded
                      ? const Icon(Symbols.close_rounded)
                      : RotationTransition(
                          turns: _iconTurns,
                          child: Transform.rotate(
                            angle: pi / 2,
                            child: const Icon(Symbols.chevron_forward_rounded),
                          ),
                        ),
                ),
              ),
              Flexible(
                child: SizeTransition(
                  sizeFactor: _heightFactor,
                  child: FadeTransition(
                    opacity: _heightFactor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: AnimatedSize(
                              alignment: Alignment.topCenter,
                              duration: _duration,
                              curve: _curve,
                              child: SingleChildScrollView(
                                child: _BusStopTileBody(
                                  stopName: _resolveTitle(busStopCustomData),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () =>
                                        _requestData(hapticFeedback: true),
                                    icon: const Icon(Symbols.refresh_rounded),
                                    label: Text(
                                      MaterialLocalizations.of(context)
                                          .refreshIndicatorSemanticLabel,
                                    ),
                                  ),
                                ),
                                if (isFavorite)
                                  Expanded(
                                    child: BusStopOptionsMenu(
                                      stopId: widget.stopId,
                                      onDelete: _toggleFavorite,
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: TextButton.icon(
                                      style: TextButton.styleFrom(
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: _toggleFavorite,
                                      icon: const Icon(
                                        Symbols.favorite_rounded,
                                      ),
                                      label: Text(
                                        context.l10n.busStopTileFavorite,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resolveIcon(BusStopCustomData? data, bool isFavorite) {
    final customIcon = BusStopCustomIcons.resolve(data?.icon);
    if (customIcon != null) return customIcon;

    return Symbols.directions_bus_rounded;
  }

  String _resolveTitle(BusStopCustomData? data) {
    if (data?.name?.isNotEmpty ?? false) {
      return data!.name!;
    }

    return BusStopUtils.resolveName(widget.stopId);
  }

  String _resolveSubtitle(BusStopCustomData? data) {
    if (data?.name?.isNotEmpty ?? false) {
      return BusStopUtils.resolveName(widget.stopId);
    }

    final linesIds = BusLineUtils.getLinesByStop(widget.stopId);
    final joinedLineIds = linesIds.join(', ');

    if (linesIds.length == 1) {
      return context.l10n.busLine(joinedLineIds);
    }

    return '${context.l10n.busLines} $joinedLineIds';
  }

  Future<void> _onTap() async {
    if (widget.alwaysExpanded) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go(FavoriteStopsPage.path);
      }
      return;
    }

    setState(() => _expanded = !_expanded);
    _updateAutoRefresh();

    if (_expanded) {
      unawaited(_requestData());
      return await _controller.forward();
    }

    return await _controller.reverse();
  }

  void _updateAutoRefresh() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    context.read<BusStopCubit>().setAutoRefresh(
      enabled:
          _expanded &&
          (lifecycle == null || lifecycle == AppLifecycleState.resumed),
    );
  }

  Future<void> _requestData({bool hapticFeedback = false}) async {
    if (hapticFeedback) unawaited(HapticFeedback.lightImpact());

    await context.read<BusStopCubit>().fetchEstimations();

    if (hapticFeedback) unawaited(HapticFeedback.lightImpact());
  }

  void _toggleFavorite() {
    unawaited(HapticFeedback.lightImpact());

    context.read<FavoriteStopsCubit>().toggle(widget.stopId);
  }
}

class _BusStopTileLoading extends StatelessWidget {
  static const _maxRows = 5;

  final int rows;

  const new(this.rows);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < (rows > _maxRows ? _maxRows : rows); i++)
          AucorsaShimmer(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                height: 40,
                width: 40,
                decoration: const ShapeDecoration(
                  shape: CircleBorder(),
                  color: Colors.white,
                ),
              ),
              title: Container(
                height: 16,
                width: 196,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  color: Colors.white,
                ),
              ),
              trailing: Container(
                height: 16,
                width: 48,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BusStopTileBody extends StatelessWidget {
  const new({required this.stopName});

  final String stopName;

  @override
  Widget build(BuildContext context) {
    final busStopState = context.watch<BusStopCubit>().state;

    if (busStopState.status == AucorsaStateStatus.loading &&
        busStopState.estimations.isEmpty) {
      return _BusStopTileLoading(
        BusLineUtils.getStopsLength(busStopState.stopId),
      );
    }

    if (busStopState.estimations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Icon(
                Symbols.history_toggle_off_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              Text(
                context.l10n.busStopTileNoEstimations,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredLineEstimations = busStopState.estimations.where(
      (lineEstimation) => BusLineUtils.isLineAvailable(lineEstimation.lineId),
    );

    return Column(
      children: [
        if (busStopState.status == AucorsaStateStatus.error)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              context.l10n.estimationsRefreshFailed,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        for (final lineEstimation in filteredLineEstimations)
          TargetBusLine(
            stopID: busStopState.stopId,
            stopName: stopName,
            lineID: lineEstimation.lineId,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 8,
              children: [
                Expanded(
                  flex: 4,
                  child: BusLineTile(
                    lineId: lineEstimation.lineId,
                    padding: EdgeInsets.zero,
                  ),
                ),
                Flexible(
                  child: busStopState.status == AucorsaStateStatus.loading
                      ? AucorsaShimmer(
                          child: Container(
                            height: 16,
                            width: 48,
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final estimation in lineEstimation.estimations)
                              DefaultTextStyle(
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(fontWeight: FontWeight.w500),
                                child: estimation == Duration.zero
                                    ? const _BusStopCloseEstimation()
                                    : AutoSizeText(
                                        estimation.pretty(
                                          abbreviated: true,
                                          delimiter: ' ',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                      ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BusStopCloseEstimation extends StatefulWidget {
  const new();

  @override
  State<StatefulWidget> createState() => _BusStopCloseEstimationState();
}

class _BusStopCloseEstimationState extends State<_BusStopCloseEstimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _curvedAnimation;

  final _curveTween = CurveTween(curve: Curves.easeInOutCubic);
  final _opacityTween = Tween(begin: .32, end: .99);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Durations.extralong1,
      vsync: this,
    )..repeat(reverse: true);

    _curvedAnimation = _animationController.drive(
      _opacityTween.chain(_curveTween),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curvedAnimation,
      child: Text(
        context.l10n.busStopTileNow,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
