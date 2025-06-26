import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/common/widgets/bus_stop_delete_dialog.dart';
import 'package:aucorsa/common/widgets/bus_stop_edit_name_dialog.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

Future<void> showBusStopOptionsDialog({
  required BuildContext context,
  required int stopId,
  required VoidCallback onDelete,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  clipBehavior: Clip.antiAlias,
  builder: (_) => _BusStopOptionsDialogView(onDelete, stopId),
);

class _BusStopOptionsDialogView extends StatelessWidget {
  final VoidCallback onDelete;
  final int stopId;

  const _BusStopOptionsDialogView(this.onDelete, this.stopId);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AutoSizeText(
                        BusStopUtils.resolveName(stopId),
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      icon: const Icon(Symbols.close_rounded),
                      onPressed: Navigator.of(context).pop,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.edit_rounded),
            title: Text(context.l10n.editStopTitle),
            onTap: () async {
              Navigator.of(context).pop();

              await Future<void>.delayed(const Duration(milliseconds: 150));

              if (!context.mounted) return;
              return showBusStopEditNameDialog(context, stopId: stopId);
            },
          ),
          ListTile(
            leading: const Icon(Symbols.delete_rounded),
            title: Text(context.l10n.deleteStopTitle),
            onTap: () async {
              Navigator.of(context).pop();

              await Future<void>.delayed(const Duration(milliseconds: 150));

              if (!context.mounted) return;
              return showBusStopDeleteDialog(
                context: context,
                onDelete: onDelete,
              );
            },
          ),
        ],
      ),
    );
  }
}
