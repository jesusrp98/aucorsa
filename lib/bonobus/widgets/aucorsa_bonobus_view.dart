import 'dart:async';

import 'package:aucorsa/about/widgets/about_button.dart';
import 'package:aucorsa/bonobus/cubits/aucorsa_cards_cubit.dart';
import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/pages/aucorsa_account_webview_page.dart';
import 'package:aucorsa/bonobus/pages/aucorsa_movements_page.dart';
import 'package:aucorsa/bonobus/repositories/aucorsa_card_repository.dart';
import 'package:aucorsa/bonobus/widgets/bonobus_balance_view.dart';
import 'package:aucorsa/bonobus/widgets/bonobus_delete_dialog.dart';
import 'package:aucorsa/bonobus/widgets/bonobus_id_dialog.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/urls.dart';
import 'package:aucorsa/common/widgets/big_tip.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AucorsaBonobusView extends StatefulWidget {
  const AucorsaBonobusView({super.key});

  @override
  State<AucorsaBonobusView> createState() => _AucorsaBonobusViewState();
}

class _AucorsaBonobusViewState extends State<AucorsaBonobusView> {
  late final AucorsaCardRepository repository;
  late final AucorsaCardsCubit cubit;

  @override
  void initState() {
    super.initState();
    repository = AucorsaCardRepository();
    cubit = AucorsaCardsCubit(repository);
    unawaited(cubit.load());
  }

  @override
  void dispose() {
    unawaited(cubit.close());
    repository.close();
    super.dispose();
  }

  Future<void> _openAccount(String url, {required bool finishOnSignIn}) async {
    final authenticated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AucorsaAccountWebViewPage(
          initialUrl: url,
          finishWhenAuthenticated: finishOnSignIn,
        ),
      ),
    );
    if (!mounted) return;
    if (authenticated ?? !finishOnSignIn) {
      await cubit.load();
    }
  }

  Future<void> _addCard() async {
    final cardNumber = await showBonobusIdDialog(context);
    if (!mounted || cardNumber == null) return;

    final added = await cubit.addCard(cardNumber);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (added) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.aucorsaCardAdded)),
      );
    } else if (cubit.state.status == AucorsaCardsStatus.failure) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(cubit.state.error ?? context.l10n.aucorsaDataError),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          title: Text(
            context.l10n.bonobus,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          actions: [
            AboutButton(onReturn: () => unawaited(cubit.load())),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<AucorsaCardsCubit, AucorsaCardsState>(
            builder: (context, state) => switch (state.status) {
              AucorsaCardsStatus.initial || AucorsaCardsStatus.loading
                  when state.cards.isEmpty =>
                const _LoadingCardsView(),
              AucorsaCardsStatus.unauthenticated => _AccountAccessView(
                onSignIn: () => _openAccount(
                  AucorsaCardRepository.signInUrl,
                  finishOnSignIn: true,
                ),
                onCreateAccount: () => _openAccount(
                  AucorsaCardRepository.registerUrl,
                  finishOnSignIn: true,
                ),
              ),
              AucorsaCardsStatus.failure when state.cards.isEmpty => _ErrorView(
                message: state.error ?? '',
                onRetry: cubit.load,
              ),
              AucorsaCardsStatus.authenticated when state.cards.isEmpty =>
                _NoCardsView(onAddCard: () => unawaited(_addCard())),
              _ => _CardsView(
                state: state,
                onRefresh: cubit.load,
                onMovements: (card) async {
                  await context.push<void>(
                    AucorsaMovementsPage.path,
                    extra: AucorsaMovementsRouteArguments(
                      card: card,
                      repository: repository,
                    ),
                  );
                  if (mounted) await cubit.load();
                },
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _AccountAccessView extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  const _AccountAccessView({
    required this.onSignIn,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    return BigTip(
      title: Text(context.l10n.aucorsaAccountTitle),
      subtitle: Text(context.l10n.aucorsaAccountSubtitle),
      action: Column(
        spacing: 16,
        children: [
          TextButton(
            style: _actionButtonStyle(context, primary: true),
            onPressed: onSignIn,
            child: Text(context.l10n.aucorsaSignIn),
          ),
          TextButton(
            style: _actionButtonStyle(context),
            onPressed: onCreateAccount,
            child: Text(context.l10n.aucorsaCreateAccount),
          ),
          TextButton(
            onPressed: context.read<BonobusCubit>().reset,
            child: Text(context.l10n.chooseAnotherProvider),
          ),
        ],
      ),
      child: const Icon(Symbols.account_circle_rounded),
    );
  }
}

class _LoadingCardsView extends StatelessWidget {
  const _LoadingCardsView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const BonobusBalanceView(balance: null, loading: true),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _CardSection(title: context.l10n.aucorsa),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NoCardsView extends StatelessWidget {
  final VoidCallback onAddCard;

  const _NoCardsView({required this.onAddCard});

  @override
  Widget build(BuildContext context) {
    return BigTip(
      title: Text(context.l10n.aucorsaNoCardsTitle),
      subtitle: Text(context.l10n.aucorsaNoCardsSubtitle),
      action: TextButton(
        style: _actionButtonStyle(context, primary: true),
        onPressed: onAddCard,
        child: Text(context.l10n.aucorsaAddCard),
      ),
      child: const Icon(Symbols.credit_card_off_rounded),
    );
  }
}

class _CardsView extends StatelessWidget {
  final AucorsaCardsState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function(AucorsaCard card) onMovements;

  const _CardsView({
    required this.state,
    required this.onRefresh,
    required this.onMovements,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          for (final card in state.cards.indexed) ...[
            BonobusBalanceView(
              balance: card.$2.balance,
              loading: state.status == AucorsaCardsStatus.loading,
              lastUpdated: state.updatedAt,
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CardSection(
                title: card.$2.title,
                onMovements: () => unawaited(onMovements(card.$2)),
              ),
            ),
            SizedBox(height: card.$1 == state.cards.length - 1 ? 16 : 40),
          ],
          if (state.status == AucorsaCardsStatus.failure)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListViewSection(
                children: [
                  ListViewSectionTile(
                    leading: const Icon(Symbols.error_rounded),
                    title: Text(context.l10n.aucorsaDataError),
                    subtitle: Text(state.error ?? ''),
                    onTap: () => unawaited(onRefresh()),
                    trailing: const Icon(Symbols.refresh_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final VoidCallback? onMovements;

  const _CardSection({
    required this.title,
    this.onMovements,
  });

  @override
  Widget build(BuildContext context) {
    return ListViewSection(
      children: [
        ListViewSectionTile(
          leading: const Icon(Symbols.credit_card_rounded),
          title: Text(title),
          subtitle: Text(context.l10n.aucorsaCardMovementsSubtitle),
          onTap: onMovements,
        ),
        ListViewSectionTile(
          leading: const Icon(Symbols.add_circle_rounded),
          title: Text(context.l10n.topUpBonobusTitle),
          subtitle: Text(context.l10n.topUpBonobusSubtitle),
          onTap: () => launchUrlString(Urls.bonobusHelpAucorsa),
        ),
        ListViewSectionTile(
          leading: const Icon(Symbols.delete_rounded),
          title: Text(context.l10n.deleteBonobusTitle),
          subtitle: Text(context.l10n.deleteBonobusSubtitle),
          onTap: () => showBonobusDeleteDialog(
            context: context,
            onDelete: () {
              unawaited(context.read<AucorsaCardsCubit>().clear());
              context.read<BonobusCubit>().reset();
            },
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return BigTip(
      title: Text(context.l10n.aucorsaDataError),
      subtitle: Text(message),
      action: TextButton(
        style: _actionButtonStyle(context, primary: true),
        onPressed: () => unawaited(onRetry()),
        child: Text(context.l10n.retry),
      ),
      child: const Icon(Symbols.error_rounded),
    );
  }
}

ButtonStyle _actionButtonStyle(
  BuildContext context, {
  bool primary = false,
}) => TextButton.styleFrom(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  minimumSize: const Size.fromHeight(56),
  textStyle: Theme.of(context).textTheme.titleMedium,
  foregroundColor: primary
      ? Theme.of(context).colorScheme.onPrimary
      : Theme.of(context).colorScheme.onSurface,
  backgroundColor: primary
      ? Theme.of(context).colorScheme.primary
      : Theme.of(context).colorScheme.surfaceContainerHighest,
);
