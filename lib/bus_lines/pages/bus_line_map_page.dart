import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:aucorsa/stops/widgets/aucorsa_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BusLineMapPage extends StatefulWidget {
  static const path = '/bus-line-map';

  final String lineId;

  const BusLineMapPage({required this.lineId, super.key});

  @override
  State<BusLineMapPage> createState() => _BusLineMapPageState();
}

class _BusLineMapPageState extends State<BusLineMapPage> {
  late final busLineSelectorCubit = context.read<BusLineSelectorCubit>();
  String? previousLineId;

  @override
  void initState() {
    super.initState();

    previousLineId = busLineSelectorCubit.state.lineId;
    busLineSelectorCubit.select(widget.lineId);
  }

  @override
  void dispose() {
    if (previousLineId != null) {
      busLineSelectorCubit.select(previousLineId!);
    } else {
      busLineSelectorCubit.clear();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.busLine(widget.lineId),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        elevation: 4,
      ),
      body: const AucorsaMap(zoomToLocationOnStart: false),
    );
  }
}
