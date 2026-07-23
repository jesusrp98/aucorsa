import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final controller = TextEditingController()
    ..addListener(() => setState(() {}));

  bool get actionEnabled =>
      controller.text.length == _BonobusIdDialog.bonobusIdLength;

  void submit() {
    if (actionEnabled) Navigator.of(context).pop(controller.text);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: MediaQuery.of(context).viewInsets + const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: _BonobusIdDialog.bonobusIdLength,
        decoration: InputDecoration(
          labelText: context.l10n.aucorsaCardNumber,
          prefixIcon: const Icon(Symbols.credit_card_rounded),
          suffixIcon: IconButton(
            icon: Icon(
              Symbols.check_circle_rounded,
              fill: actionEnabled ? 1 : 0,
              color: actionEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: actionEnabled ? submit : null,
          ),
        ),
        autofocus: true,
        onSubmitted: (_) => submit(),
      ),
    );
  }
}
