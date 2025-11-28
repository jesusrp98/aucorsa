import 'package:aucorsa/bus_lines/widget/feria_lines_dialog.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class FeriaEventTile extends StatelessWidget {
  const FeriaEventTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListViewSectionTile(
      onTap: () => showFeriaLinesDialog(context),
      leading: const Icon(Symbols.festival_rounded),
      title: const Text(
        'Feria de Córdoba',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(context.l10n.feriaEventDescription),
    );
  }
}
