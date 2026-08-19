import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:aucorsa/bonobus/widgets/empty_bonobus_view.dart';
import 'package:aucorsa/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  testWidgets('tapping AUCORSA opens the card number field directly', (
    tester,
  ) async {
    HydratedBloc.storage = _MemoryStorage();
    final cubit = BonobusCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: const EmptyBonobusView(),
        ),
      ),
    );

    await tester.tap(find.text('Aucorsa'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Card number'), findsOneWidget);
    expect(find.text('Sign in or create account'), findsNothing);

    await tester.enterText(find.byType(TextField), '1234567890');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(cubit.state.provider, BonobusProvider.aucorsa);
    expect(cubit.state.id, '1234567890');
  });
}

class _MemoryStorage implements Storage {
  final Map<String, dynamic> _values = {};

  @override
  dynamic read(String key) => _values[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async => _values.clear();

  @override
  Future<void> close() async {}
}
