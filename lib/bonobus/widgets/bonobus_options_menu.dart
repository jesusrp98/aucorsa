import 'package:aucorsa/bonobus/widgets/bonobus_delete_dialog.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/widgets/aucorsa_menu.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_ui/material_ui.dart';

class BonobusOptionsMenu extends StatelessWidget {
  final Future<void> Function() onDelete;
  final VoidCallback? onEdit;
  final AucorsaMenuBuilder builder;

  const new({
    required this.onDelete,
    required this.builder,
    this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) => AucorsaMenu(
    alignment: AlignmentDirectional.bottomEnd,
    menuChildren: [
      if (onEdit != null)
        MenuItemButton(
          leadingIcon: const Icon(Symbols.edit_rounded),
          onPressed: onEdit,
          child: Text(context.l10n.editBonobusTitle),
        ),
      MenuItemButton(
        leadingIcon: const Icon(Symbols.delete_rounded),
        onPressed: () =>
            showBonobusDeleteDialog(context: context, onDelete: onDelete),
        child: Text(context.l10n.deleteBonobusTitle),
      ),
    ],
    builder: builder,
  );
}
