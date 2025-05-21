import 'package:flutter/material.dart';

class AucorsaScrollingSheet extends StatelessWidget {
  static const _dragHandleSize = Size(32, 4);

  final double initialSheetSize;
  final ScrollableWidgetBuilder builder;

  const AucorsaScrollingSheet({
    required this.builder,
    this.initialSheetSize = 0.72,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.surfaceContainerLow;

    return DraggableScrollableSheet(
      initialChildSize: initialSheetSize,
      minChildSize: initialSheetSize,
      expand: false,
      snap: true,
      builder: (context, scrollController) => MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeRight: true,
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kMinInteractiveDimension),
            child: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: backgroundColor,
              centerTitle: true,
              title: Container(
                height: _dragHandleSize.height,
                width: _dragHandleSize.width,
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          body: builder(context, scrollController),
        ),
      ),
    );
  }
}
