import 'package:flutter/material.dart';

Future<String?> showBonobusIdDialog(
  BuildContext context,
) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => const _BonobusIdDialog(),
);

class _BonobusIdDialog extends StatefulWidget {
  const _BonobusIdDialog();

  @override
  State<_BonobusIdDialog> createState() => _BonobusIdDialogState();
}

class _BonobusIdDialogState extends State<_BonobusIdDialog> {
  final _controller = TextEditingController();

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        minimum: MediaQuery.of(context).viewInsets + const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          maxLength: 10,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: const Icon(Icons.check),
              onPressed: _submit,
            ),
          ),
          autofocus: true,
          onSubmitted: (_) => _submit(),
        ),
      ),
    );
  }
}
