import 'dart:async';

import 'package:aucorsa/bonobus/cubits/aucorsa_movements_cubit.dart';
import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/repositories/aucorsa_card_repository.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/date_time_format.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class AucorsaMovementsPage extends StatefulWidget {
  static const path = '/aucorsa-movements';

  final AucorsaCard card;
  final AucorsaCardRepository repository;

  const AucorsaMovementsPage({
    required this.card,
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
      cardNumber: widget.card.number,
    );
    unawaited(cubit.loadMore());
  }

  @override
  void dispose() {
    unawaited(cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.l10n.aucorsaCardMovements,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<AucorsaMovementsCubit, AucorsaMovementsState>(
            builder: (context, state) => switch (state.status) {
              AucorsaMovementsStatus.unauthenticated => _MessageView(
                icon: Symbols.lock_rounded,
                title: context.l10n.aucorsaSessionExpiredTitle,
                subtitle: context.l10n.aucorsaSessionExpiredSubtitle,
              ),
              _ => _MovementsView(state: state),
            },
          ),
        ),
      ),
    );
  }
}

class AucorsaMovementsRouteArguments {
  final AucorsaCard card;
  final AucorsaCardRepository repository;

  const AucorsaMovementsRouteArguments({
    required this.card,
    required this.repository,
  });
}

class _MovementsView extends StatefulWidget {
  final AucorsaMovementsState state;

  const _MovementsView({required this.state});

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
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: widget.state.movements.isEmpty
            ? [SliverFillRemaining(child: _emptyState(context, cubit))]
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
                if (widget.state.status == AucorsaMovementsStatus.failure)
                  SliverToBoxAdapter(
                    child: _MessageView(
                      icon: Symbols.error_rounded,
                      title: context.l10n.aucorsaDataError,
                      subtitle: widget.state.error ?? '',
                      onRetry: cubit.loadMore,
                    ),
                  ),
              ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, AucorsaMovementsCubit cubit) {
    return switch (widget.state.status) {
      AucorsaMovementsStatus.initial || AucorsaMovementsStatus.loading =>
        const Center(child: CircularProgressIndicator()),
      AucorsaMovementsStatus.failure => _MessageView(
        icon: Symbols.error_rounded,
        title: context.l10n.aucorsaDataError,
        subtitle: widget.state.error ?? '',
        onRetry: cubit.loadMore,
      ),
      _ => _MessageView(
        icon: Symbols.receipt_long_rounded,
        title: context.l10n.aucorsaNoMovementsTitle,
        subtitle: context.l10n.aucorsaNoMovementsSubtitle,
      ),
    };
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
      leading: Icon(movementIcon, fill: 1),
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
