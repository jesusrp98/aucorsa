import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/widgets/aucorsa_menu.dart';
import 'package:aucorsa/common/widgets/bus_stop_delete_dialog.dart';
import 'package:aucorsa/common/widgets/bus_stop_edit_name_dialog.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_ui/material_ui.dart';

class BusStopOptionsMenu extends StatelessWidget {
  final int stopId;
  final VoidCallback onDelete;

  const new({required this.stopId, required this.onDelete, super.key});

  @override
  Widget build(BuildContext context) => AucorsaMenu(
    menuChildren: [
      MenuItemButton(
        leadingIcon: const Icon(Symbols.edit_rounded),
        onPressed: () => showBusStopEditNameDialog(context, stopId: stopId),
        child: Text(context.l10n.editStopTitle),
      ),
      MenuItemButton(
        leadingIcon: const Icon(Symbols.delete_rounded),
        onPressed: () =>
            showBusStopDeleteDialog(context: context, onDelete: onDelete),
        child: Text(context.l10n.deleteStopTitle),
      ),
    ],
    builder: (context, toggleMenu) => TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: toggleMenu,
      icon: const Icon(Symbols.pending_rounded),
      label: Text(MaterialLocalizations.of(context).moreButtonTooltip),
    ),
  );
}
