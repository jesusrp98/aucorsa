import 'dart:async';
import 'dart:math';

import 'package:aucorsa/common/cubits/bus_service_cubit.dart';
import 'package:aucorsa/common/models/bus_stop_line_estimation.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/common/widgets/aucorsa_shimmer.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:aucorsa/favorite_stops/cubits/favorite_stops_cubit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class BusStopTile extends StatefulWidget {
  final int stopId;

  const BusStopTile({
    required this.stopId,
    super.key,
  });

  @override
  State<BusStopTile> createState() => _BusStopTileState();
}

class _BusStopTileState extends State<BusStopTile>
    with SingleTickerProviderStateMixin {
  static final _easeInCurve = CurveTween(curve: Curves.easeInOutCubic);
  static final _halfTurn = Tween<double>(begin: 0, end: 0.5);

  late final Animation<double> _heightFactor;
  late final Animation<double> _iconTurns;
  late final AnimationController _controller;

  final _busStopLineEstimations = <BusStopLineEstimation>[];
  var _expanded = false;

  late final _stopsLength = BusLineUtils.getStopsLength(widget.stopId);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Durations.medium2,
      vsync: this,
    );

    _heightFactor = _controller.drive(_easeInCurve);
    _iconTurns = _controller.drive(_halfTurn.chain(_easeInCurve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select(
      (FavoriteStopsCubit cubit) => cubit.isFavorite(widget.stopId),
    );

    return Card(
      elevation: 1,
      shadowColor: Colors.transparent,
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: _onTap,
        child: Column(
          children: [
            Material(
              type: MaterialType.card,
              elevation: _expanded ? 6 : 1,
              shadowColor: Colors.transparent,
              color: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSecondaryContainer,
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
                trailing: RotationTransition(
                  turns: _iconTurns,
                  child: Transform.rotate(
                    angle: pi / 2,
                    child: const Icon(Symbols.chevron_forward_rounded),
                  ),
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _heightFactor,
              child: FadeTransition(
                opacity: _heightFactor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      if (_busStopLineEstimations.isNotEmpty)
                        _BusStopTileBody(_busStopLineEstimations)
                      else
                        _BusStopTileLoading(_stopsLength),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (isFavorite)
                            TextButton.icon(
                              onPressed: _toggleFavorite,
                              icon: const Icon(Symbols.delete_rounded),
                              label: const Text('Eliminar'),
                            )
                          else
                            TextButton.icon(
                              onPressed: _toggleFavorite,
                              icon: const Icon(Symbols.favorite_rounded),
                              label: const Text('Favorito'),
                            ),
                          TextButton.icon(
                            onPressed: _requestData,
                            icon: const Icon(Symbols.refresh_rounded),
                            label: const Text('Recargar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap() async {
    setState(() => _expanded = !_expanded);

    if (_expanded) {
      unawaited(_requestData());
      return _controller.forward();
    }

    return _controller.reverse();
  }

  Future<void> _requestData() async {
    if (_busStopLineEstimations.isNotEmpty) {
      setState(_busStopLineEstimations.clear);
    }

    final response = await context.read<BusServiceCubit>().requestBusStopData(
          widget.stopId,
        );

    return setState(() => _busStopLineEstimations.addAll(response));
  }

  void _toggleFavorite() =>
      context.read<FavoriteStopsCubit>().toggle(widget.stopId);
}

class _BusStopTileLoading extends StatelessWidget {
  final int rows;

  const _BusStopTileLoading(this.rows);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows; i++)
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
  final List<BusStopLineEstimation> lineEstimations;

  const _BusStopTileBody(this.lineEstimations);

  @override
  Widget build(BuildContext context) {
    final filteredLineEstimations = lineEstimations.where(
      (lineEstimation) => BusLineUtils.isLineAvailable(
        lineEstimation.lineId,
      ),
    );

    return Column(
      children: [
        for (final lineEstimation in filteredLineEstimations)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: BusLineTile(
                  lineId: lineEstimation.lineId,
                  embedded: true,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final estimation in lineEstimation.estimations)
                      Text(
                        estimation == Duration.zero
                            ? 'Ahora'
                            : estimation.pretty(
                                abbreviated: true,
                                delimiter: ' ',
                              ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
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
