import 'package:aucorsa/about/widgets/about_button.dart';
import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:aucorsa/bonobus/widgets/bonobus_id_dialog.dart';
import 'package:aucorsa/bonobus/widgets/bonobus_scan_controller.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/widgets/big_tip.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class EmptyBonobusView extends StatefulWidget {
  const EmptyBonobusView({super.key});

  @override
  State<EmptyBonobusView> createState() => _EmptyBonobusViewState();
}

class _EmptyBonobusViewState extends State<EmptyBonobusView> {
  BonobusProvider? provider;

  @override
  Widget build(BuildContext context) {
    if (provider == null) {
      return _EmptyProviderView(
        onSelect: (provider) async {
          if (provider == BonobusProvider.consorcio) {
            return setState(() => this.provider = provider);
          }

          final id = await showBonobusIdDialog(context);

          if (!context.mounted || id == null) return;

          return context.read<BonobusCubit>().set(
            provider: provider,
            id: id,
          );
        },
      );
    }

    return _ScanBonobusView(
      onCancel: () => setState(() => provider = null),
      provider: provider!,
    );
  }
}

class _EmptyProviderView extends StatelessWidget {
  final ValueSetter<BonobusProvider> onSelect;

  const _EmptyProviderView({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(
          context.l10n.bonobus,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: const [
          AboutButton(),
        ],
      ),
      body: Center(
        child: BigTip(
          title: Text(context.l10n.addBonobusTitle),
          subtitle: Text(
            context.l10n.addBonobusSubtitle,
          ),
          action: Column(
            spacing: 16,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(56),
                    textStyle: Theme.of(context).textTheme.titleMedium,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimary,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => onSelect(BonobusProvider.aucorsa),
                  child: AutoSizeText(context.l10n.aucorsa),
                ),
              ),
              // Consorcio card red ops. are not compatible with NFC on iOS
              if (Theme.of(context).platform == TargetPlatform.android)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size.fromHeight(56),
                      textStyle: Theme.of(context).textTheme.titleMedium,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimary,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary,
                    ),
                    onPressed: () => onSelect(BonobusProvider.consorcio),
                    child: AutoSizeText(
                      context.l10n.consorcio,
                      maxLines: 1,
                    ),
                  ),
                ),
            ],
          ),
          child: const Icon(Symbols.credit_card_rounded),
        ),
      ),
    );
  }
}

class _ScanBonobusView extends StatelessWidget {
  final VoidCallback onCancel;
  final BonobusProvider provider;

  const _ScanBonobusView({required this.onCancel, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(
          context.l10n.bonobus,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: const [
          AboutButton(),
        ],
      ),
      body: Stack(
        children: [
          BonobusScanController(
            onStateChanged: (state) {
              context.read<BonobusCubit>().set(
                provider: provider,
                id: state.id,
              );
              context.read<BonobusCubit>().loaded(
                balance: state.balance,
              );
            },
          ),
          Center(
            child: BigTip(
              title: Text(context.l10n.scanBonobusTitle),
              subtitle: Text(context.l10n.scanBonobusSubtitle),
              action: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ).copyWith(top: 72),
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(56),
                    textStyle: Theme.of(context).textTheme.titleMedium,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  onPressed: onCancel,
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
              ),
              child: const Icon(Symbols.contactless_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
