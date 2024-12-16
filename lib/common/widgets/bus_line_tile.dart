import 'package:aucorsa/bus_lines/pages/bus_line_page.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class BusLineTile extends StatelessWidget {
  final String lineId;

  const BusLineTile({
    required this.lineId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final line = BusLineUtils.getLine(lineId);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _resolveLineColor(context, line.color),
        foregroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AutoSizeText(
            line.id,
            maxLines: 1,
          ),
        ),
      ),
      title: AutoSizeText(
        line.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
      ),
      trailing: const Icon(Symbols.chevron_forward_rounded),
      onTap: () => context.push(BusLinePage.path, extra: line.id),
    );
  }

  Color _resolveLineColor(BuildContext context, Color color) {
    final brightness = Theme.of(context).colorScheme.brightness;

    return switch (brightness) {
      Brightness.light => color,
      Brightness.dark => Color.lerp(color, Colors.black, 0.32)!,
    };
  }
}
