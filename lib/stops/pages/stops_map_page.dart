import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:aucorsa/stops/widgets/aucrosa_map.dart';
import 'package:aucorsa/stops/widgets/bus_line_selector_bar.dart';
import 'package:aucorsa/stops/widgets/bus_line_selector_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StopsMapPage extends StatefulWidget {
  static const path = '/stops-map';

  const StopsMapPage({super.key});

  @override
  State<StopsMapPage> createState() => _StopsMapPageState();
}

class _StopsMapPageState extends State<StopsMapPage> {
  @override
  Widget build(BuildContext context) {
    final selectedLine = context.select(
      (BusLineSelectorCubit cubit) => cubit.state.lineId,
    );

    return Scaffold(
      body: Stack(
        children: [
          const AucorsaMap(),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            left: MediaQuery.paddingOf(context).left + 16,
            right: MediaQuery.paddingOf(context).right + 16,
            height: kToolbarHeight,
            child: BusLineSelectorBar(
              selectedLine: selectedLine,
              onTap: onBusLineSelectorTap,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onBusLineSelectorTap() async {
    final busLineSelectorCubit = context.read<BusLineSelectorCubit>();

    final selectedLine = await showBusLineSelector(context);

    // Ignore if the selected line is the same as the current one
    if (selectedLine == busLineSelectorCubit.state.lineId) return;

    if (selectedLine == null) return;

    return busLineSelectorCubit.select(selectedLine);
  }
}
