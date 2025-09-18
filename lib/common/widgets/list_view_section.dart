import 'package:flutter/material.dart';

class ListViewSection extends StatelessWidget {
  final List<Widget> children;

  const ListViewSection({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          spacing: 4,
          children: [
            for (final child in children.indexed)
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
                clipBehavior: Clip.antiAlias,
                child: child.$2,
              ),
          ],
        ),
      ),
    );
  }
}
