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
            ListViewSectionItem(
              index: child.$1,
              itemCount: children.length,
              child: child.$2,
            ),
        ],
      ),
    );
  }
}

/// A single item of a [ListViewSection], rounded according to its position.
///
/// Lets lazily built lists, like the ones paginated by `SliverInfiniteList`,
/// wear the same look as the eager [ListViewSection].
class ListViewSectionItem extends StatelessWidget {
  final int index;
  final int itemCount;
  final Widget child;

  const ListViewSectionItem({
    required this.index,
    required this.itemCount,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.vertical(
        top: index == 0 ? const Radius.circular(24) : const Radius.circular(4),
        bottom: index == itemCount - 1
            ? const Radius.circular(24)
            : const Radius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
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
