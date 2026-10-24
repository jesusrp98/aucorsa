import 'package:material_ui/material_ui.dart';

typedef AucorsaMenuBuilder = Widget Function(
  BuildContext context,
  VoidCallback toggleMenu,
);

class AucorsaMenu extends StatelessWidget {
  final List<Widget> menuChildren;
  final AucorsaMenuBuilder builder;
  final AlignmentGeometry? alignment;

  const new({
    required this.menuChildren,
    required this.builder,
    this.alignment,
    super.key,
  });

  @override
  Widget build(BuildContext context) => MenuAnchor(
    style: MenuStyle(
      alignment: alignment,
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    ),
    alignmentOffset: const Offset(0, 4),
    consumeOutsideTap: true,
    useRootOverlay: true,
    animated: true,
    menuChildren: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          elevation: 3,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: menuChildren,
            ),
          ),
        ),
      ),
    ],
    builder: (context, controller, _) => builder(
      context,
      () => controller.isOpen ? controller.close() : controller.open(),
    ),
  );
}
