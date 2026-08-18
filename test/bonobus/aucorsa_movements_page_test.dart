import 'dart:async';

import 'package:aucorsa/bonobus/cubits/aucorsa_movements_cubit.dart';
import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/pages/aucorsa_movements_page.dart';
import 'package:aucorsa/bonobus/repositories/aucorsa_card_repository.dart';
import 'package:aucorsa/common/widgets/big_tip.dart';
import 'package:aucorsa/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  const cardNumber = '1234567890';
  const movement = AucorsaCardMovement(
    date: '17/08/2026',
    time: '12:00',
    operation: 'Validación',
    amount: '-0.72 €',
  );
  late _MemoryStorage storage;

  setUp(() {
    storage = _MemoryStorage();
    HydratedBloc.storage = storage;
  });

  testWidgets('asks an unauthenticated user to sign in or create an account', (
    tester,
  ) async {
    final repository = _FakeRepository(
      loadMovements: ({required cardNumber, required page}) async {
        throw const AucorsaSessionExpiredException();
      },
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.byType(BigTip), findsOneWidget);
    expect(find.text('Connect your AUCORSA account'), findsOneWidget);
    expect(find.text('Sign in or create account'), findsOneWidget);
  });

  testWidgets('loads the movements of the current card on its own', (
    tester,
  ) async {
    final repository = _FakeRepository(
      loadMovements: ({required cardNumber, required page}) async {
        return const AucorsaCardMovements(
          movements: [movement],
          hasPreviousPage: false,
          hasNextPage: false,
        );
      },
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(repository.movementRequests, [(cardNumber, 1)]);
    expect(find.text('Bus journey'), findsOneWidget);
  });

  testWidgets('points to the help button when AUCORSA returns no movements', (
    tester,
  ) async {
    final repository = _FakeRepository(
      loadMovements: ({required cardNumber, required page}) async {
        return const AucorsaCardMovements(
          movements: [],
          hasPreviousPage: false,
          hasNextPage: false,
        );
      },
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('No movements'), findsOneWidget);
    expect(find.textContaining('Check the help button'), findsOneWidget);
  });

  testWidgets('explains how the history works from the help button', (
    tester,
  ) async {
    final repository = _FakeRepository(
      loadMovements: ({required cardNumber, required page}) async {
        throw const AucorsaSessionExpiredException();
      },
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Help'));
    await tester.pumpAndSettle();

    expect(find.text('How the movement history works'), findsOneWidget);
    expect(find.text('Open my AUCORSA cards'), findsOneWidget);
  });

  testWidgets('shows a card-specific error when history cannot be loaded', (
    tester,
  ) async {
    final repository = _FakeRepository(
      loadMovements: ({required cardNumber, required page}) async {
        throw const AucorsaCardApiException('Movements are unavailable');
      },
    );

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.byType(BigTip), findsOneWidget);
    expect(find.text('Movement history unavailable'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('shows stored movements while fresh ones are downloaded', (
    tester,
  ) async {
    await storage.write(AucorsaMovementsCubit.storageKey(cardNumber), {
      'movements': [
        const AucorsaCardMovement(
          date: '16/08/2026',
          time: '12:00',
          operation: 'Validación',
          amount: '-0.72 €',
        ).toJson(),
      ],
      'nextPage': 2,
      'hasReachedMax': true,
    });

    final downloaded = Completer<AucorsaCardMovements>();
    final repository = _FakeRepository(
      loadMovements: ({required cardNumber, required page}) =>
          downloaded.future,
    );

    await tester.pumpWidget(_app(repository));
    await tester.pump();

    expect(find.text('Bus journey'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    downloaded.complete(
      const AucorsaCardMovements(
        movements: [],
        hasPreviousPage: false,
        hasNextPage: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}

Widget _app(AucorsaCardRepository repository) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AucorsaMovementsPage(
      cardNumber: '1234567890',
      repository: repository,
    ),
  );
}

class _FakeRepository implements AucorsaCardRepository {
  final Future<AucorsaCardMovements> Function({
    required String cardNumber,
    required int page,
  })
  _loadMovements;
  final List<(String, int)> movementRequests = [];

  _FakeRepository({
    required Future<AucorsaCardMovements> Function({
      required String cardNumber,
      required int page,
    })
    loadMovements,
  }) : _loadMovements = loadMovements;

  @override
  Future<AucorsaCardMovements> loadMovements({
    required String cardNumber,
    required int page,
  }) {
    movementRequests.add((cardNumber, page));
    return _loadMovements(cardNumber: cardNumber, page: page);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
