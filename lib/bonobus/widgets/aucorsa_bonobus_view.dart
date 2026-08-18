import 'dart:async';

import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:aucorsa/bonobus/pages/aucorsa_movements_page.dart';
import 'package:aucorsa/bonobus/repositories/aucorsa_card_repository.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_account_data.dart';
import 'package:aucorsa/bonobus/widgets/bonobus_details_view.dart';
import 'package:aucorsa/bonobus/widgets/bonobus_id_dialog.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AucorsaBonobusView extends StatefulWidget {
  const AucorsaBonobusView({super.key});

  @override
  State<AucorsaBonobusView> createState() => _AucorsaBonobusViewState();
}

class _AucorsaBonobusViewState extends State<AucorsaBonobusView> {
  late final AucorsaCardRepository repository;

  @override
  void initState() {
    super.initState();
    repository = AucorsaCardRepository();
    unawaited(_refresh());
  }

  @override
  void dispose() {
    repository.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    final bonobusCubit = context.read<BonobusCubit>();
    final cardNumber = bonobusCubit.state.id;
    if (cardNumber == null) return;

    bonobusCubit.loading();
    try {
      final card = await repository.loadPublicCard(cardNumber);
      if (!mounted || bonobusCubit.state.id != cardNumber) return;
      bonobusCubit.loaded(balance: card.balance, name: card.title);
    } catch (error) {
      if (!mounted || bonobusCubit.state.id != cardNumber) return;
      bonobusCubit.loadFailed();
      _showError(error);
    }
  }

  Future<void> _openMovements() async {
    final cardNumber = context.read<BonobusCubit>().state.id;
    if (cardNumber == null) return;

    await context.push<void>(
      AucorsaMovementsPage.path,
      extra: AucorsaMovementsRouteArguments(
        cardNumber: cardNumber,
        repository: repository,
      ),
    );
  }

  Future<void> _editCard() async {
    final bonobusCubit = context.read<BonobusCubit>();
    final currentCardNumber = bonobusCubit.state.id;

    final cardNumber = await showBonobusIdDialog(
      context,
      initialValue: currentCardNumber,
    );
    if (!mounted || cardNumber == null || cardNumber == currentCardNumber) {
      return;
    }

    bonobusCubit.updateId(cardNumber);

    await _refresh();
  }

  Future<void> _removeDetails() async {
    final bonobusCubit = context.read<BonobusCubit>();
    try {
      await AucorsaAccountData.clear(
        repository: repository,
        cardNumber: bonobusCubit.state.id,
      );
    } catch (error) {
      if (mounted) _showError(error);
      return;
    }

    if (!bonobusCubit.isClosed) bonobusCubit.reset();
  }

  void _showError(Object error) {
    final message = error is AucorsaCardApiException
        ? error.message
        : context.l10n.aucorsaDataError;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => BonobusDetailsView(
    onRefresh: _refresh,
    onViewMovements: () => unawaited(_openMovements()),
    onEdit: () => unawaited(_editCard()),
    onDelete: _removeDetails,
  );
}
