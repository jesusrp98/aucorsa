import 'dart:async';

import 'package:aucorsa/bonobus/cubits/aucorsa_movements_cubit.dart';
import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/pages/aucorsa_account_webview_page.dart';
import 'package:aucorsa/bonobus/pages/aucorsa_movements_help_page.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/date_time_extension.dart';
import 'package:aucorsa/common/widgets/big_tip.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

class AucorsaMovementsPage extends StatelessWidget {
  static const path = '/aucorsa-movements';

  final String cardNumber;

  const AucorsaMovementsPage({required this.cardNumber, super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = AucorsaMovementsCubit(cardNumber: cardNumber);
      unawaited(cubit.refresh());

      return cubit;
    },
    child: const AucorsaMovementsView(),
  );
}

/// The movements page itself, reading its cubit from the tree.
@visibleForTesting
class AucorsaMovementsView extends StatelessWidget {
  const AucorsaMovementsView({super.key});

  Future<void> _signIn(BuildContext context) async {
    final cubit = context.read<AucorsaMovementsCubit>();
    final authenticated = await context.push<bool>(
      AucorsaAccountWebViewPage.path,
    );
    if (authenticated != true) return;

    await cubit.refresh();
  }

  /// Opens the step by step guide on what AUCORSA asks for.
  void _showHelp(BuildContext context) => unawaited(
    context.push<void>(AucorsaMovementsHelpPage.path),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AucorsaMovementsCubit, AucorsaMovementsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              context.l10n.aucorsaCardMovements,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            actions: [
              IconButton(
                tooltip: context.l10n.aucorsaMovementsHelpTitle,
                icon: const Icon(Symbols.help_rounded),
                onPressed: () => _showHelp(context),
              ),
            ],
          ),
          // The progress bar floats over the list instead of living in the
          // app bar, so showing it never shifts the content down.
          body: Stack(
            children: [
              _buildBody(context, state),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  // A switcher rather than an opacity, so the indeterminate
                  // bar leaves the tree once faded out and stops animating.
                  child: AnimatedSwitcher(
                    duration: kThemeAnimationDuration,
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    child: state.movements.isNotEmpty && state.refreshing
                        ? const LinearProgressIndicator()
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AucorsaMovementsState state) {
    if (state.status == AucorsaMovementsStatus.unauthenticated) {
      return SafeArea(
        child: _AccountAccessView(
          onContinue: () => unawaited(_signIn(context)),
        ),
      );
    }

    return _MovementsView(
      state: state,
      onRefresh: context.read<AucorsaMovementsCubit>().refresh,
    );
  }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

class _MovementsView extends StatelessWidget {
  final AucorsaMovementsState state;
  final Future<void> Function() onRefresh;

  const _MovementsView({required this.state, required this.onRefresh});

  /// Whether the spinner belongs on screen, either alone or below the history.
  bool get _loading => switch (state.status) {
    AucorsaMovementsStatus.initial || AucorsaMovementsStatus.loading => true,
    _ => state.refreshing && state.movements.isEmpty,
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AucorsaMovementsCubit>();
    final movements = state.movements;
    final isEmpty = movements.isEmpty;
    // The list scrolls under the system insets, and only its padding grows to
    // clear them, so the last movement is never cut off.
    final insets = MediaQuery.paddingOf(context);
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16 + insets.left,
              8,
              16 + insets.right,
              16 + insets.bottom,
            ),
            sliver: SliverInfiniteList(
              itemCount: movements.length,
              isLoading: _loading,
              hasError: state.status == AucorsaMovementsStatus.failure,
              // A refresh blocks pagination, and flipping this back when it
              // ends is what asks for the next page again.
              hasReachedMax: state.hasReachedMax || state.refreshing,
              onFetchData: () => unawaited(cubit.loadMore()),
              centerLoading: true,
              centerEmpty: true,
              centerError: isEmpty,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) => ListViewSectionItem(
                index: index,
                itemCount: movements.length,
                child: _MovementTile(movements[index]),
              ),
              loadingBuilder: (_) => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
              errorBuilder: (_) => isEmpty
                  ? _MovementsErrorView(onRetry: onRefresh)
                  : _MovementLoadMoreError(
                      onRetry: state.hasReachedMax ? onRefresh : cubit.loadMore,
                    ),
              emptyBuilder: (context) => _MessageView(
                icon: Symbols.receipt_long_rounded,
                title: context.l10n.aucorsaNoMovementsTitle,
                subtitle: context.l10n.aucorsaNoMovementsSubtitle,
              ),
            ),
          ),
        ],
      ),
    );
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
    // Only top-ups carry an activation state, and a pending one is what the
    // amount and the title flag in amber.
    final isPending =
        isRecharge && movement.activation == AucorsaRechargeActivation.pending;
    final unsignedAmount = movement.amount.replaceFirst(
      RegExp(r'^[+\-−]\s*'),
      '',
    );
    final amountColor = isPending
        ? _pendingColor(Theme.of(context).brightness)
        : isRecharge
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;
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
    final movementTitle = isPending
        ? context.l10n.aucorsaMovementOnlineTopUpPending
        : isRecharge
        ? context.l10n.aucorsaMovementOnlineTopUp
        : isTransfer
        ? context.l10n.aucorsaMovementTransfer
        : isValidation
        ? context.l10n.aucorsaMovementBusJourney
        : movement.operation;
    final movementDateTime = _parseMovementDateTime(movement);
    final movementDateLabel = movementDateTime == null
        ? '${movement.date} · ${movement.time}'
        : movementDateTime.shortDateTimeLabel;
    return ListViewSectionTile(
      leading: Icon(movementIcon),
      title: Text(movementTitle),
      subtitle: Text(movementDateLabel),
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

final _lightPendingColor = ColorScheme.fromSeed(
  seedColor: Colors.amber,
).primary;

final _darkPendingColor = ColorScheme.fromSeed(
  seedColor: Colors.amber,
  brightness: Brightness.dark,
).primary;

/// Amber that flags pending states, built from the same tonal machinery as
/// the rest of the palette so it sits well on the app surfaces.
Color _pendingColor(Brightness brightness) =>
    brightness == Brightness.dark ? _darkPendingColor : _lightPendingColor;

DateTime? _parseMovementDateTime(AucorsaCardMovement movement) {
  final value = '${movement.date} ${movement.time}';
  return DateFormat('dd-MM-yyyy HH:mm').tryParseStrict(value) ??
      DateFormat('dd/MM/yyyy HH:mm').tryParseStrict(value);
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
