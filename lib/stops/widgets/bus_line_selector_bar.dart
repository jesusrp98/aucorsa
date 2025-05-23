import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class BusLineSelectorBar extends StatelessWidget {
  final String? selectedLine;
  final VoidCallback? onTap;

  const BusLineSelectorBar({required this.selectedLine, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    const listTilePadding = EdgeInsets.only(left: 8, right: 4);

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeRight: true,
        child: InkWell(
          onTap: onTap,
          child: selectedLine == null
              ? ListTile(
                  contentPadding: listTilePadding,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer,
                    child: const Icon(Symbols.signpost_rounded, fill: 0.5),
                  ),
                  title: Text(
                    context.l10n.allStops,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Symbols.keyboard_arrow_down_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : BusLineTile(
                  lineId: selectedLine!,
                  padding: listTilePadding,
                  onTap: onTap,
                  trailing: IconButton(
                    icon: const Icon(Symbols.close_rounded),
                    onPressed: context.read<BusLineSelectorCubit>().clear,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }
}
