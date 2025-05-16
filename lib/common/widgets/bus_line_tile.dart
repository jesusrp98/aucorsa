import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class BusLineTile extends StatelessWidget {
  final String lineId;
  final EdgeInsets padding;
  final TextStyle? titleStyle;
  final VoidCallback? onTap;
  final Widget? trailing;

  static Color resolveLineBackgroundColor(BuildContext context, Color color) =>
      switch (Theme.of(context).colorScheme.brightness) {
        Brightness.light => color,
        Brightness.dark => Color.lerp(color, Colors.black, 0.32)!,
      };

  static Color resolveLineForegroundColor(BuildContext context) =>
      switch (Theme.of(context).colorScheme.brightness) {
        Brightness.light => Colors.white,
        Brightness.dark => Theme.of(context).colorScheme.onSurface,
      };

  const BusLineTile({
    required this.lineId,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.onTap,
    this.titleStyle,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final line = BusLineUtils.getLine(lineId);

    return ListTile(
      contentPadding: padding,
      leading: CircleAvatar(
        backgroundColor: resolveLineBackgroundColor(context, line.color),
        foregroundColor: resolveLineForegroundColor(context),
        child: Text(line.id),
      ),
      title: AutoSizeText(
        line.name,
        maxLines: 1,
        style: titleStyle,
        overflow: TextOverflow.ellipsis,
      ),
      leadingAndTrailingTextStyle:
          Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
