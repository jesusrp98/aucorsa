import 'package:aucorsa/bus_lines/widget/feria_lines_dialog.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class FeriaEventTile extends StatelessWidget {
  const FeriaEventTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.transparent,
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => showFeriaLinesDialog(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          child: const Icon(Symbols.festival_rounded),
        ),
        title: const Text(
          'Feria de Córdoba',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(context.l10n.feriaEventDescription),
        trailing: const Icon(Symbols.chevron_right_rounded),
      ),
    );
  }
}
