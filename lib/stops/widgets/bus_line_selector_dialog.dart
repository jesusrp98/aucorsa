import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/widgets/aucorsa_scrolling_sheet.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

Future<String?> showBusLineSelector(BuildContext context) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      useSafeArea: true,
      builder: (_) => const _BusLineSelectorDialogView(),
    );

class _BusLineSelectorDialogView extends StatelessWidget {
  static final lines = BusLineUtils.lines;

  const _BusLineSelectorDialogView();

  @override
  Widget build(BuildContext context) {
    final selectedLine = context.read<BusLineSelectorCubit>().state.lineId;

    return AucorsaScrollingSheet(
      builder: (context, scrollController) => ListView.builder(
        controller: scrollController,
        itemCount: lines.length,
        itemBuilder: (context, index) => ColoredBox(
          color: selectedLine == lines[index].id
              ? Theme.of(context).colorScheme.primaryFixed
              : Colors.transparent,
          child: BusLineTile(
            lineId: lines[index].id,
            onTap: () => context.pop(lines[index].id),
            titleStyle: TextStyle(
              color: selectedLine == lines[index].id
                  ? Theme.of(context).colorScheme.onPrimaryFixed
                  : null,
            ),
            trailing: selectedLine == lines[index].id
                ? Icon(
                    Symbols.check_circle_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryFixed,
                    fill: 1,
                  )
                : Icon(
                    Symbols.circle_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );
  }
}
