import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/widgets/bus_stop_delete_dialog.dart';
import 'package:aucorsa/common/widgets/bus_stop_edit_name_dialog.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

Future<void> showBusStopOptionsDialog({
  required BuildContext context,
  required int stopId,
  required VoidCallback onDelete,
}) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _BusStopOptionsDialogView(onDelete, stopId),
  backgroundColor: Colors.transparent,
);

class _BusStopOptionsDialogView extends StatelessWidget {
  final VoidCallback onDelete;
  final int stopId;

  const _BusStopOptionsDialogView(this.onDelete, this.stopId);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: ListViewSection(
        children: [
          ListTile(
            leading: const Icon(Symbols.edit_rounded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(context.l10n.editStopTitle),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () async {
              Navigator.of(context).pop();

              await Future<void>.delayed(const Duration(milliseconds: 150));

              if (!context.mounted) return;
              return showBusStopEditNameDialog(context, stopId: stopId);
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(Symbols.delete_rounded),
            title: Text(context.l10n.deleteStopTitle),
            trailing: const Icon(Symbols.chevron_right_rounded),
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
