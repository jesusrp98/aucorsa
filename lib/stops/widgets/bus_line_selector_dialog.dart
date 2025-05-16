import 'package:aucorsa/common/utils/bus_line_utils.dart';
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
  static const lines = BusLineUtils.lines;
  static const dragHandleSize = Size(32, 4);
  static const initialDialogSize = 0.64;

  const _BusLineSelectorDialogView();

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.surfaceContainerLow;
    final selectedLine = context.read<BusLineSelectorCubit>().state;

    return DraggableScrollableSheet(
      initialChildSize: initialDialogSize,
      minChildSize: initialDialogSize,
      expand: false,
      snap: true,
      builder: (context, scrollController) => MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeRight: true,
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kMinInteractiveDimension),
            child: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: backgroundColor,
              centerTitle: true,
              title: Container(
                height: dragHandleSize.height,
                width: dragHandleSize.width,
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          body: ListView.builder(
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
        ),
      ),
    );
  }
}
