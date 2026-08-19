import 'dart:async';

import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:aucorsa/bonobus/pages/aucorsa_movements_page.dart';
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
  @override
  void initState() {
    super.initState();
    unawaited(context.read<BonobusCubit>().refresh());
  }

  Future<void> _openMovements() async {
    final cardNumber = context.read<BonobusCubit>().state.id;
    if (cardNumber == null) return;

    await context.push<void>(AucorsaMovementsPage.path, extra: cardNumber);
  }

  Future<void> _editCard() async {
    final cubit = context.read<BonobusCubit>();
    final currentCardNumber = cubit.state.id;

    final cardNumber = await showBonobusIdDialog(
      context,
      initialValue: currentCardNumber,
    );
    if (cardNumber == null || cardNumber == currentCardNumber) return;

    await cubit.updateId(cardNumber);
  }

  void _showError(BuildContext context, String error) {
    final cubit = context.read<BonobusCubit>();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error.isEmpty ? context.l10n.aucorsaDataError : error),
        ),
      );
    cubit.clearError();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<BonobusCubit, BonobusState>(
        listenWhen: (previous, current) => current.error != null,
        listener: (context, state) => _showError(context, state.error!),
        child: BonobusDetailsView(
          onRefresh: context.read<BonobusCubit>().refresh,
          onViewMovements: () => unawaited(_openMovements()),
          onEdit: () => unawaited(_editCard()),
          onDelete: context.read<BonobusCubit>().delete,
        ),
      );
}
