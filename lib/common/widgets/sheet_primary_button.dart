import 'package:material_ui/material_ui.dart';

/// The primary action used by Aucorsa confirmation sheets.
class SheetPrimaryButton extends StatelessWidget {
  const new({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size.fromHeight(56),
      textStyle: Theme.of(context).textTheme.titleMedium,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      backgroundColor: Theme.of(context).colorScheme.primary,
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}
