import 'dart:async';
import 'dart:math';

import 'package:aucorsa/common/cubits/bus_service_cubit.dart';
import 'package:aucorsa/common/cubits/bus_stop_cubit.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/aucorsa_state_status.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/common/widgets/aucorsa_shimmer.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:aucorsa/common/widgets/bus_stop_delete_dialog.dart';
import 'package:aucorsa/stops/cubits/favorite_stops_cubit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class BusStopTile extends StatelessWidget {
  final int stopId;
  final bool alwaysExpanded;

  const BusStopTile({
    required this.stopId,
    super.key,
    this.alwaysExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BusStopCubit(
        busServiceCubit: context.read<BusServiceCubit>(),
        stopId: stopId,
      ),
      child: _BusStopTileView(stopId: stopId, alwaysExpanded: alwaysExpanded),
    );
  }
}

class _BusStopTileView extends StatefulWidget {
  final int stopId;
  final bool alwaysExpanded;

  const _BusStopTileView({required this.stopId, this.alwaysExpanded = false});

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

  late var _expanded = widget.alwaysExpanded;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _controller = AnimationController(
      duration: _duration,
      value: widget.alwaysExpanded ? 1 : 0,
      vsync: this,
    );

    _heightFactor = _controller.drive(_easeInCurve);
    _iconTurns = _controller.drive(_halfTurn.chain(_easeInCurve));

    if (widget.alwaysExpanded) {
      _requestData();
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
    // Refresh data when the app is resumed and it's expanded
    if (_expanded && state == AppLifecycleState.resumed) _requestData();
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select(
      (FavoriteStopsCubit cubit) => cubit.isFavorite(widget.stopId),
    );

    final linesIds = BusLineUtils.getLinesByStop(widget.stopId);
    final joinedLineIds = linesIds.join(', ');

    final subtitle = linesIds.length == 1
        ? context.l10n.busLine(joinedLineIds)
        : '${context.l10n.busLines} $joinedLineIds';

    return SafeArea(
      top: false,
      bottom: widget.alwaysExpanded,
      child: Card(
        elevation: 1,
        shadowColor: Colors.transparent,
        color: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onTap: _onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                type: MaterialType.card,
                elevation: _expanded ? 4 : 1,
                shadowColor: Colors.transparent,
                color: Theme.of(context).colorScheme.surface,
                surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: AutoSizeText(
                        widget.stopId.toString(),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  title: Text(
                    BusStopUtils.resolveName(widget.stopId),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: AutoSizeText(
                    subtitle,
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
                          const Flexible(
                            child: AnimatedSize(
                              alignment: Alignment.topCenter,
                              duration: _duration,
                              curve: _curve,
                              child: SingleChildScrollView(
                                child: _BusStopTileBody(),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (isFavorite)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => showBusStopDeleteDialog(
                                    context: context,
                                    stopName: BusStopUtils.resolveName(
                                      widget.stopId,
                                    ),
                                    onDelete: _toggleFavorite,
                                  ),
                                  icon: const Icon(Symbols.delete_rounded),
                                  label: Text(
                                    MaterialLocalizations.of(
                                      context,
                                    ).deleteButtonTooltip,
                                  ),
                                )
                              else
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: _toggleFavorite,
                                  icon: const Icon(Symbols.favorite_rounded),
                                  label: Text(context.l10n.busStopTileFavorite),
                                ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () =>
                                    _requestData(hapticFeedback: true),
                                icon: const Icon(Symbols.refresh_rounded),
                                label: Text(context.l10n.busStopTileReload),
                              ),
                            ],
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

  Future<void> _onTap() async {
    if (widget.alwaysExpanded) return Navigator.of(context).pop();

    setState(() => _expanded = !_expanded);

    if (_expanded) {
      unawaited(_requestData());
      return _controller.forward();
    }

    return _controller.reverse();
  }

  Future<void> _requestData({bool hapticFeedback = false}) async {
    if (hapticFeedback) unawaited(HapticFeedback.selectionClick());

    await context.read<BusStopCubit>().fetchEstimations();

    if (hapticFeedback) unawaited(HapticFeedback.selectionClick());
  }

  void _toggleFavorite() {
    HapticFeedback.selectionClick();

    context.read<FavoriteStopsCubit>().toggle(widget.stopId);
  }
}

class _BusStopTileLoading extends StatelessWidget {
  static const _maxRows = 5;

  final int rows;

  const _BusStopTileLoading(this.rows);

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
  const _BusStopTileBody();

  @override
  Widget build(BuildContext context) {
    final busStopState = context.watch<BusStopCubit>().state;

    if (busStopState.status == AucorsaStateStatus.loading &&
        busStopState.estimations.isEmpty) {
      return _BusStopTileLoading(
        BusLineUtils.getStopsLength(busStopState.stopId),
      );
    }

    if (busStopState.status == AucorsaStateStatus.error ||
        busStopState.estimations.isEmpty) {
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
        for (final lineEstimation in filteredLineEstimations)
          Row(
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
      ],
    );
  }
}

class _BusStopCloseEstimation extends StatefulWidget {
  const _BusStopCloseEstimation();

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
