import 'dart:async';

import 'package:aucorsa/bonobus/cubits/aucorsa_movements_cubit.dart';
import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/pages/aucorsa_account_webview_page.dart';
import 'package:aucorsa/bonobus/repositories/aucorsa_card_repository.dart';
import 'package:aucorsa/bonobus/widgets/aucorsa_movements_help_dialog.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/date_time_format.dart';
import 'package:aucorsa/common/widgets/big_tip.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class AucorsaMovementsPage extends StatefulWidget {
  static const path = '/aucorsa-movements';

  final String cardNumber;
  final AucorsaCardRepository repository;

  const AucorsaMovementsPage({
    required this.cardNumber,
    required this.repository,
    super.key,
  });

  @override
  State<AucorsaMovementsPage> createState() => _AucorsaMovementsPageState();
}

class _AucorsaMovementsPageState extends State<AucorsaMovementsPage> {
  late final AucorsaMovementsCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = AucorsaMovementsCubit(
      loadMovements: widget.repository.loadMovements,
      cardNumber: widget.cardNumber,
    );
    unawaited(cubit.refresh());
  }

  @override
  void dispose() {
    unawaited(cubit.close());
    super.dispose();
  }

  Future<void> _signIn() async {
    final authenticated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AucorsaAccountWebViewPage(),
      ),
    );
    if (!mounted || authenticated != true) return;
    await cubit.refresh();
  }

  /// Opens the AUCORSA card list, where the user links this card themselves.
  Future<void> _openCards() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AucorsaAccountWebViewPage.cards(),
      ),
    );
    if (!mounted) return;
    await cubit.refresh();
  }

  Future<void> _showHelp() => showAucorsaMovementsHelpDialog(
    context: context,
    onOpenCards: () => unawaited(_openCards()),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<AucorsaMovementsCubit, AucorsaMovementsState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                context.l10n.aucorsaCardMovements,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              actions: [
                IconButton(
                  tooltip: context.l10n.aucorsaMovementsHelpTooltip,
                  icon: const Icon(Symbols.help_rounded),
                  onPressed: () => unawaited(_showHelp()),
                ),
              ],
              bottom: state.movements.isNotEmpty && state.refreshing
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(4),
                      child: LinearProgressIndicator(minHeight: 4),
                    )
                  : null,
            ),
            body: SafeArea(child: _buildBody(state)),
          );
        },
      ),
    );
  }

  Widget _buildBody(AucorsaMovementsState state) {
    if (state.status == AucorsaMovementsStatus.unauthenticated) {
      return _AccountAccessView(onContinue: () => unawaited(_signIn()));
    }

    return _MovementsView(state: state, onRefresh: cubit.refresh);
  }
}

class AucorsaMovementsRouteArguments {
  final String cardNumber;
  final AucorsaCardRepository repository;

  const AucorsaMovementsRouteArguments({
    required this.cardNumber,
    required this.repository,
  });
}

class _AccountAccessView extends StatelessWidget {
  final VoidCallback onContinue;

  const _AccountAccessView({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return BigTip(
      title: Text(context.l10n.aucorsaAccountTitle),
      subtitle: Text(context.l10n.aucorsaMovementsAccountSubtitle),
      action: TextButton(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(56),
          textStyle: Theme.of(context).textTheme.titleMedium,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        onPressed: onContinue,
        child: Text(context.l10n.aucorsaUseAccount),
      ),
      child: const Icon(Symbols.account_circle_rounded),
    );
  }
}

class _MovementsView extends StatefulWidget {
  final AucorsaMovementsState state;
  final Future<void> Function() onRefresh;

  const _MovementsView({required this.state, required this.onRefresh});

  @override
  State<_MovementsView> createState() => _MovementsViewState();
}

class _MovementsViewState extends State<_MovementsView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreIfNeeded);
  }

  @override
  void didUpdateWidget(covariant _MovementsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMoreIfNeeded());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreIfNeeded)
      ..dispose();
    super.dispose();
  }

  void _loadMoreIfNeeded() {
    if (!mounted || !_scrollController.hasClients) return;
    if (widget.state.status != AucorsaMovementsStatus.loaded ||
        widget.state.refreshing ||
        widget.state.hasReachedMax) {
      return;
    }
    if (_scrollController.position.extentAfter < 200) {
      unawaited(context.read<AucorsaMovementsCubit>().loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AucorsaMovementsCubit>();
    final failed = widget.state.status == AucorsaMovementsStatus.failure;
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: widget.state.movements.isEmpty
            ? [SliverFillRemaining(child: _emptyState(context))]
            : [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: ListViewSection(
                      children: [
                        for (final movement in widget.state.movements)
                          _MovementTile(movement),
                      ],
                    ),
                  ),
                ),
                if (widget.state.status == AucorsaMovementsStatus.loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                if (failed)
                  SliverToBoxAdapter(
                    child: _MovementLoadMoreError(
                      onRetry: widget.state.hasReachedMax
                          ? widget.onRefresh
                          : cubit.loadMore,
                    ),
                  ),
              ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    if (widget.state.refreshing) {
      return const Center(child: CircularProgressIndicator());
    }
    return switch (widget.state.status) {
      AucorsaMovementsStatus.initial || AucorsaMovementsStatus.loading =>
        const Center(child: CircularProgressIndicator()),
      AucorsaMovementsStatus.failure => _MovementsErrorView(
        onRetry: widget.onRefresh,
      ),
      _ => _MessageView(
        icon: Symbols.receipt_long_rounded,
        title: context.l10n.aucorsaNoMovementsTitle,
        subtitle: context.l10n.aucorsaNoMovementsSubtitle,
      ),
    };
  }
}

class _MovementsErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _MovementsErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return BigTip(
      title: Text(context.l10n.aucorsaMovementsUnavailableTitle),
      subtitle: Text(context.l10n.aucorsaMovementsUnavailableSubtitle),
      action: TextButton(
        onPressed: () => unawaited(onRetry()),
        child: Text(context.l10n.retry),
      ),
      child: const Icon(Symbols.error_rounded),
    );
  }
}

class _MovementLoadMoreError extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _MovementLoadMoreError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _MessageView(
      icon: Symbols.error_rounded,
      title: context.l10n.aucorsaMovementsUnavailableTitle,
      subtitle: context.l10n.aucorsaMovementsUnavailableSubtitle,
      onRetry: () => unawaited(onRetry()),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final AucorsaCardMovement movement;

  const _MovementTile(this.movement);

  @override
  Widget build(BuildContext context) {
    final normalizedOperation = movement.operation.toLowerCase();
    final isRecharge = normalizedOperation.contains('recarga');
    final isTransfer = normalizedOperation.contains('transbordo');
    final isValidation = normalizedOperation.contains('validaci');
    final unsignedAmount = movement.amount.replaceFirst(
      RegExp(r'^[+\-−]\s*'),
      '',
    );
    final amountColor = isRecharge
        ? Theme.of(context).colorScheme.primary
        : isTransfer
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.error;
    final amountPrefix = isRecharge
        ? '+'
        : isTransfer
        ? ''
        : '−';
    final movementIcon = isRecharge
        ? Symbols.add_card_rounded
        : isTransfer
        ? Symbols.conversion_path_rounded
        : isValidation
        ? Symbols.contactless_rounded
        : Symbols.directions_bus_rounded;
    final movementTitle = isRecharge
        ? context.l10n.aucorsaMovementOnlineTopUp
        : isTransfer
        ? context.l10n.aucorsaMovementTransfer
        : isValidation
        ? context.l10n.aucorsaMovementBusJourney
        : movement.operation;
    final movementDateTime = _parseMovementDateTime(movement);
    final movementDateLabel = movementDateTime == null
        ? '${movement.date} · ${movement.time}'
        : formatShortDateTime(movementDateTime);
    return ListViewSectionTile(
      leading: Icon(movementIcon),
      title: Text(movementTitle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(movementDateLabel),
          if (movement.activation != null) ...[
            const SizedBox(height: 8),
            _ActivationStatus(movement),
          ],
        ],
      ),
      trailing: Text(
        '$amountPrefix$unsignedAmount',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

DateTime? _parseMovementDateTime(AucorsaCardMovement movement) {
  final value = '${movement.date} ${movement.time}';
  return DateFormat('dd-MM-yyyy HH:mm').tryParseStrict(value) ??
      DateFormat('dd/MM/yyyy HH:mm').tryParseStrict(value);
}

class _ActivationStatus extends StatelessWidget {
  final AucorsaCardMovement movement;

  const _ActivationStatus(this.movement);

  @override
  Widget build(BuildContext context) {
    final activated =
        movement.activation == AucorsaRechargeActivation.activated;
    final color = activated
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            activated ? Symbols.check_circle_rounded : Symbols.pending_rounded,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            activated
                ? context.l10n.aucorsaRechargeActivated
                : context.l10n.aucorsaRechargePending,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  const _MessageView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(context.l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
