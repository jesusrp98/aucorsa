import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/widgets/aucorsa_scrolling_sheet.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showBusLineSelector(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      useSafeArea: true,
      builder: (_) => const _BusLineSelectorDialogView(),
    );

class _BusLineSelectorDialogView extends StatelessWidget {
  static final lines = BusLineUtils.lines;

  const new();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BusLineSelectorCubit>();
    final selectedLine = cubit.state.lineId;
    final colorScheme = Theme.of(context).colorScheme;

    return AucorsaScrollingSheet(
      builder: (context, scrollController) => ListView.builder(
        controller: scrollController,
        itemCount: lines.length + 1,
        itemBuilder: (context, index) {
          final line = index == 0 ? null : lines[index - 1];
          final isSelected = selectedLine == line?.id;
          final trailing = Icon(
            isSelected ? Symbols.check_circle_rounded : Symbols.circle_rounded,
            color: isSelected
                ? colorScheme.onPrimaryFixed
                : colorScheme.onSurfaceVariant,
            fill: isSelected ? 1 : 0,
          );

          void onTap() {
            if (!isSelected) {
              if (line == null) {
                cubit.clear();
              } else {
                cubit.select(line.id);
              }
            }
            context.pop();
          }

          return Material(
            color: isSelected ? colorScheme.primaryFixed : Colors.transparent,
            child: line == null
                ? ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                      child: const Icon(Symbols.signpost_rounded, fill: 0.5),
                    ),
                    title: Text(context.l10n.allStops),
                    textColor: isSelected ? colorScheme.onPrimaryFixed : null,
                    trailing: trailing,
                    onTap: onTap,
                  )
                : BusLineTile(
                    lineId: line.id,
                    onTap: onTap,
                    titleStyle: TextStyle(
                      color: isSelected ? colorScheme.onPrimaryFixed : null,
                    ),
                    trailing: trailing,
                  ),
          );
        },
      ),
    );
  }
}
