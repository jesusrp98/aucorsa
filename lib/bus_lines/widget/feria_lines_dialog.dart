import 'package:aucorsa/bus_lines/pages/bus_line_page.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/widgets/aucorsa_scrolling_sheet.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:aucorsa/events/models/event_id.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

Future<void> showFeriaLinesDialog(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    builder: (_) => const _FeriaLinesDialog(),
  );
}

class _FeriaLinesDialog extends StatelessWidget {
  const _FeriaLinesDialog();

  @override
  Widget build(BuildContext context) {
    final busLines = BusLineUtils.lines
        .where((line) => line.eventId == EventId.feria)
        .toList();

    return AucorsaScrollingSheet(
      initialSheetSize: 0.96,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        children: [
          const CircleAvatar(
            radius: 40,
            child: Icon(
              Symbols.festival_rounded,
              size: 40,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Feria de Córdoba',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.l10n.feriaDialogBody,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          for (final line in busLines)
            BusLineTile(
              lineId: line.id,
              trailing: Icon(
                Symbols.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onTap: () => context
                ..pop()
                ..push(
                  BusLinePage.path,
                  extra: line.id,
                ),
            ),
        ],
      ),
    );
  }
}
