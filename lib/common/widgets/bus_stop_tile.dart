import 'dart:async';
import 'dart:math';

import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/favorite_stops/cubits/favorite_stops_cubit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

// TODO(any): Clean up this file
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
  late final AnimationController _controller;

  static final _easeInCurve = CurveTween(curve: Curves.easeInOutCubic);
  static final _halfTurn = Tween<double>(begin: 0, end: 0.5);

  late Animation<double> _heightFactor;
  late Animation<double> _iconTurns;

  var _expanded = false;

  String? _busStopData;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
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

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding:
          _expanded ? const EdgeInsets.symmetric(vertical: 8) : EdgeInsets.zero,
      child: Card(
        elevation: _expanded ? 3 : 0,
        color: Theme.of(context).colorScheme.surface,
        shadowColor: Colors.transparent,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _onTap,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            padding:
                _expanded ? const EdgeInsets.only(top: 8) : EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
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
                SizeTransition(
                  sizeFactor: _heightFactor,
                  child: _busStopData == null
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16).copyWith(
                            bottom: 8,
                            top: 0,
                          ),
                          child: Column(
                            children: [
                              HtmlWidget(_busStopData!),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                                      icon:
                                          const Icon(Symbols.favorite_rounded),
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
              ],
            ),
          ),
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
    setState(() => _busStopData = null);

    final response = await Dio().get<dynamic>(
      'https://aucorsa.es/wp-json/aucorsa/v1/estimations/stop?stop_id=${widget.stopId}&_wpnonce=b67f2b8b77',
    );

    return setState(() => _busStopData = response.data.toString());
  }

  void _toggleFavorite() =>
      context.read<FavoriteStopsCubit>().toggle(widget.stopId);
}
