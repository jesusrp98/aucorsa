import 'package:aucorsa/bus_lines/pages/bus_line_page.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class BusLineTile extends StatelessWidget {
  final String lineId;
  final bool embedded;

  const BusLineTile({
    required this.lineId,
    this.embedded = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final line = BusLineUtils.getLine(lineId);

    return ListTile(
      contentPadding: embedded
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16),
      leading: CircleAvatar(
        backgroundColor: _resolveLineBackgroundColor(context, line.color),
        foregroundColor: _resolveLineForegroundColor(context),
        child: Text(line.id),
      ),
      title: AutoSizeText(
        line.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leadingAndTrailingTextStyle:
          Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
      trailing: embedded ? null : const Icon(Symbols.chevron_forward_rounded),
      onTap: embedded
          ? null
          : () => context.push(
                BusLinePage.path,
                extra: line.id,
              ),
    );
  }

  Color _resolveLineBackgroundColor(BuildContext context, Color color) =>
      switch (Theme.of(context).colorScheme.brightness) {
        Brightness.light => color,
        Brightness.dark => Color.lerp(color, Colors.black, 0.32)!,
      };

  Color _resolveLineForegroundColor(BuildContext context) =>
      switch (Theme.of(context).colorScheme.brightness) {
        Brightness.light => Colors.white,
        Brightness.dark => Theme.of(context).colorScheme.onSurface,
      };
}
