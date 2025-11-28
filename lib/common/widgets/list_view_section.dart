import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class ListViewSection extends StatelessWidget {
  final List<Widget> children;

  const ListViewSection({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          for (final child in children.indexed)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.vertical(
                top: child.$1 == 0
                    ? const Radius.circular(24)
                    : const Radius.circular(4),
                bottom: child.$1 == children.length - 1
                    ? const Radius.circular(24)
                    : const Radius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: child.$2,
            ),
        ],
      ),
    );
  }
}

class ListViewSectionTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ListViewSectionTile({
    this.leading,
    this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      leading: leading != null
          ? SizedBox.square(
              dimension: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer,
                  ),
                  child: leading!,
                ),
              ),
            )
          : null,
      title: title,
      subtitle: subtitle,
      trailing: trailing == null && onTap != null
          ? const Icon(Symbols.chevron_right_rounded)
          : trailing,
      onTap: onTap,
    );
  }
}
