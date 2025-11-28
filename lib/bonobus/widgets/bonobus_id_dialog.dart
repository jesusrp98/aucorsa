import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

Future<String?> showBonobusIdDialog(
  BuildContext context,
) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => const _BonobusIdDialog(),
  backgroundColor: Colors.transparent,
);

class _BonobusIdDialog extends StatefulWidget {
  static const bonobusIdLength = 10;

  const _BonobusIdDialog();

  @override
  State<_BonobusIdDialog> createState() => _BonobusIdDialogState();
}

class _BonobusIdDialogState extends State<_BonobusIdDialog> {
  late final _controller = TextEditingController()
    ..addListener(() => setState(() {}));

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final actionEnabled =
        _controller.text.length == _BonobusIdDialog.bonobusIdLength;

    return SafeArea(
      minimum: MediaQuery.of(context).viewInsets + const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        maxLength: _BonobusIdDialog.bonobusIdLength,
        decoration: InputDecoration(
          prefixIcon: const Icon(Symbols.credit_card_rounded),
          suffixIcon: IconButton(
            icon: Icon(
              Symbols.check_circle_rounded,
              fill: actionEnabled ? 1 : 0,
              color: actionEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: actionEnabled ? _submit : null,
          ),
        ),
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
