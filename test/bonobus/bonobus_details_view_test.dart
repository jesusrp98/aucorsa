import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:aucorsa/bonobus/widgets/bonobus_details_view.dart';
import 'package:aucorsa/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  late BonobusCubit cubit;

  setUp(() {
    HydratedBloc.storage = _MemoryStorage();
    cubit = BonobusCubit()
      ..set(provider: BonobusProvider.aucorsa, id: '0546174400')
      ..loaded(balance: '8.87 €', name: 'Tarjeta Estudiante');
  });

  tearDown(() => cubit.close());

  testWidgets('shows the movements tile for an AUCORSA bonobus', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        child: BonobusDetailsView(
          onViewMovements: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Movement history'), findsOneWidget);
    expect(find.text('View recent movements'), findsOneWidget);

    await tester.tap(find.text('Movement history'));
    expect(tapped, isTrue);
  });

  testWidgets('uses the provided cleanup when removal is confirmed', (
    tester,
  ) async {
    var deleted = false;

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        child: BonobusDetailsView(
          onDelete: () async => deleted = true,
        ),
      ),
    );

    await tester.tap(find.text('Tarjeta Estudiante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });

  testWidgets('opens the card options when the card tile is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        child: BonobusDetailsView(onEdit: () {}),
      ),
    );

    expect(find.text('Edit card number'), findsNothing);

    await tester.tap(find.text('Tarjeta Estudiante'));
    await tester.pumpAndSettle();

    expect(find.text('Edit card number'), findsOneWidget);
    expect(find.text('Remove details'), findsOneWidget);
  });

  testWidgets('runs the provided edit callback', (tester) async {
    var edited = false;

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        child: BonobusDetailsView(onEdit: () => edited = true),
      ),
    );

    await tester.tap(find.text('Tarjeta Estudiante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit card number'));
    await tester.pumpAndSettle();

    expect(edited, isTrue);
  });

  testWidgets('hides the edit option when editing is not supported', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(cubit: cubit, child: const BonobusDetailsView()),
    );

    await tester.tap(find.text('Tarjeta Estudiante'));
    await tester.pumpAndSettle();

    expect(find.text('Edit card number'), findsNothing);
    expect(find.text('Remove details'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  final BonobusCubit cubit;
  final Widget child;

  const _TestApp({required this.cubit, required this.child});

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider.value(value: cubit, child: child),
  );
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
