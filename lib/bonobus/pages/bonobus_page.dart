import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:aucorsa/bonobus/widgets/aucorsa_bonobus_view.dart';
import 'package:aucorsa/bonobus/widgets/consorcio_bonobus_view.dart';
import 'package:aucorsa/bonobus/widgets/empty_bonobus_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BonobusPage extends StatelessWidget {
  static const path = '/bonobus';

  const BonobusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BonobusCubit>().state;

    return switch (state.provider) {
      BonobusProvider.aucorsa => const AucorsaBonobusView(),
      BonobusProvider.consorcio => const ConsorcioBonobusView(),
      null => const EmptyBonobusView(),
    };
  }
}
