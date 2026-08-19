import 'package:aucorsa/bonobus/widgets/bonobus_delete_dialog.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

Future<void> showBonobusOptionsDialog({
  required BuildContext context,
  required Future<void> Function() onDelete,
  VoidCallback? onEdit,
}) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _BonobusOptionsDialogView(onDelete: onDelete, onEdit: onEdit),
  backgroundColor: Colors.transparent,
);

class _BonobusOptionsDialogView extends StatelessWidget {
  static const _closeDuration = Duration(milliseconds: 150);

  final Future<void> Function() onDelete;
  final VoidCallback? onEdit;

  const _BonobusOptionsDialogView({required this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: ListViewSection(
        children: [
          if (onEdit != null)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: const Icon(Symbols.edit_rounded),
              title: Text(context.l10n.editBonobusTitle),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () async {
                Navigator.of(context).pop();

                await Future<void>.delayed(_closeDuration);

                return onEdit!();
              },
            ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(Symbols.delete_rounded),
            title: Text(context.l10n.deleteBonobusTitle),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () async {
              Navigator.of(context).pop();

              await Future<void>.delayed(_closeDuration);

              if (!context.mounted) return;
              return showBonobusDeleteDialog(
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
