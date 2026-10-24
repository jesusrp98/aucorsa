import 'dart:async';

import 'package:aucorsa/bonobus/cubits/aucorsa_movements_cubit.dart';
import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/pages/aucorsa_movements_help_page.dart';
import 'package:aucorsa/bonobus/pages/aucorsa_movements_page.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_api.dart';
import 'package:aucorsa/common/widgets/big_tip.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:aucorsa/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Storage;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

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
    final site = _FakeAucorsaSite(
      loadMovements: ({required cardNumber, required page}) async {
        throw const AucorsaSessionExpiredException();
      },
    );

    await tester.pumpWidget(_app(site));
    await tester.pumpAndSettle();

    expect(find.byType(BigTip), findsOneWidget);
    expect(find.text('Connect your account'), findsOneWidget);
    expect(find.text('Sign in or create account'), findsOneWidget);
  });

  testWidgets('loads the movements of the current card on its own', (
    tester,
  ) async {
    final site = _FakeAucorsaSite(
      loadMovements: ({required cardNumber, required page}) async {
        return const AucorsaCardMovements(
          movements: [movement],
          hasNextPage: false,
        );
      },
    );

    await tester.pumpWidget(_app(site));
    await tester.pumpAndSettle();

    expect(site.movementRequests, [(cardNumber, 1)]);
    expect(find.text('Bus journey'), findsOneWidget);
  });

  testWidgets('asks for the next page once the first one is on screen', (
    tester,
  ) async {
    final site = _FakeAucorsaSite(
      loadMovements: ({required cardNumber, required page}) async {
        return AucorsaCardMovements(
          movements: const [movement],
          hasNextPage: page < 2,
        );
      },
    );

    await tester.pumpWidget(_app(site, now: DateTime(2026, 10, 24)));
    await tester.pumpAndSettle();

    expect(site.movementRequests, [(cardNumber, 1), (cardNumber, 2)]);
    expect(find.text('Bus journey'), findsNWidgets(2));
    expect(find.text('August'), findsOneWidget);
  });

  testWidgets('points to the help button when AUCORSA returns no movements', (
    tester,
  ) async {
    final site = _FakeAucorsaSite(
      loadMovements: ({required cardNumber, required page}) async {
        return const AucorsaCardMovements(movements: [], hasNextPage: false);
      },
    );

    await tester.pumpWidget(_app(site));
    await tester.pumpAndSettle();

    expect(find.text('No movements'), findsOneWidget);
    expect(find.textContaining('Check the help button'), findsOneWidget);
  });

  testWidgets('opens the step by step guide from the help button', (
    tester,
  ) async {
    final site = _FakeAucorsaSite(
      loadMovements: ({required cardNumber, required page}) async {
        throw const AucorsaSessionExpiredException();
      },
    );

    await tester.pumpWidget(_app(site));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Help'));
    await tester.pumpAndSettle();

    expect(find.byType(AucorsaMovementsHelpPage), findsOneWidget);
    // The medium app bar paints its title both collapsed and expanded.
    expect(find.text('Help'), findsWidgets);
    expect(find.text('Create an AUCORSA account'), findsOneWidget);
    expect(find.text('Activate the account from your email'), findsOneWidget);
    expect(find.text('Add this card to your account'), findsOneWidget);
  });

  testWidgets('shows a card-specific error when history cannot be loaded', (
    tester,
  ) async {
    final site = _FakeAucorsaSite(
      loadMovements: ({required cardNumber, required page}) async {
        throw const AucorsaCardApiException('Movements are unavailable');
      },
    );

    await tester.pumpWidget(_app(site));
    await tester.pumpAndSettle();

    expect(find.byType(BigTip), findsOneWidget);
    expect(find.text('Movement history unavailable'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('shows stored movements while fresh ones are downloaded', (
    tester,
  ) async {
    const storedMovement = AucorsaCardMovement(
      date: '16/08/2026',
      time: '12:00',
      operation: 'Validación',
      amount: '-0.72 €',
    );
    await storage.write(AucorsaMovementsCubit.storageKey(cardNumber), {
      'movements': [
        storedMovement.toJson(),
        const AucorsaCardMovement(
          date: '31/07/2026',
          time: '12:00',
          operation: 'Transbordo',
          amount: '0.00 €',
        ).toJson(),
      ],
      'nextPage': 2,
      'hasReachedMax': true,
    });

    final downloaded = Completer<AucorsaCardMovements>();
    final site = _FakeAucorsaSite(
      loadMovements: ({required cardNumber, required page}) =>
          downloaded.future,
    );

    await tester.pumpWidget(_app(site, now: DateTime(2026, 10, 24)));
    await tester.pump();

    expect(find.text('Bus journey'), findsOneWidget);
    expect(find.text('July'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    final spinner = find.byType(CircularProgressIndicator);
    expect(spinner, findsOneWidget);
    final headingCenter = tester.getCenter(find.text('August'));
    final spinnerCenter = tester.getCenter(spinner);
    expect(spinnerCenter.dx, greaterThan(headingCenter.dx));
    expect(spinnerCenter.dy, closeTo(headingCenter.dy, 0.1));
    final firstTilePosition = tester.getTopLeft(find.text('Bus journey'));

    downloaded.complete(
      const AucorsaCardMovements(
        movements: [storedMovement],
        hasNextPage: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(spinner, findsNothing);
    expect(tester.getTopLeft(find.text('Bus journey')), firstTilePosition);
  });

  group('date sections', () {
    testWidgets('groups recent dates, earlier months, and previous years', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sections = {
        'Today': ['24/10/2026', '24-10-2026'],
        'Yesterday': ['23/10/2026'],
        'This week': ['19/10/2026'],
        'This month': ['18/10/2026'],
        'September': ['30/09/2026'],
        'August': ['17/08/2026'],
        '2025': ['31/12/2025', '01/01/2025'],
        '2024': ['31/12/2024'],
      };
      await _pumpMovements(tester, [
        for (final dates in sections.values)
          for (final date in dates) _movement(operation: date, date: date),
      ], now: DateTime(2026, 10, 24, 0, 1));

      var previousY = 0.0;
      for (final section in sections.entries) {
        expect(find.text(section.key), findsOneWidget);
        final headingY = tester.getTopLeft(find.text(section.key)).dy;
        expect(headingY, greaterThan(previousY));
        previousY = headingY;
        for (final date in section.value) {
          final tileY = tester.getTopLeft(find.text(date)).dy;
          expect(tileY, greaterThan(previousY));
          previousY = tileY;
        }
      }

      BorderRadius borderFor(String title) {
        final section = find.ancestor(
          of: find.text(title),
          matching: find.byType(ListViewSectionItem),
        );
        final material = tester.widget<Material>(
          find.descendant(of: section, matching: find.byType(Material)).first,
        );
        return material.borderRadius! as BorderRadius;
      }

      expect(
        borderFor('24/10/2026'),
        const BorderRadius.vertical(
          top: Radius.circular(24),
          bottom: Radius.circular(4),
        ),
      );
      expect(
        borderFor('24-10-2026'),
        const BorderRadius.vertical(
          top: Radius.circular(4),
          bottom: Radius.circular(24),
        ),
      );
      expect(borderFor('23/10/2026'), BorderRadius.circular(24));
    });

    for (final scenario in [
      (
        name: 'Monday starts a new week',
        now: DateTime(2026, 11, 2),
        dates: ['01/11/2026', '31/10/2026'],
        headings: ['Yesterday', 'October'],
        absent: ['Today', 'This week', 'This month'],
      ),
      (
        name: 'recent days take precedence across a month boundary',
        now: DateTime(2026, 10),
        dates: ['30/09/2026', '28/09/2026', '27/09/2026'],
        headings: ['Yesterday', 'This week', 'September'],
        absent: ['Today', 'This month'],
      ),
      (
        name: 'recent days take precedence across a year boundary',
        now: DateTime(2027),
        dates: ['31/12/2026', '28/12/2026', '27/12/2026'],
        headings: ['Yesterday', 'This week', '2026'],
        absent: ['Today', 'This month', 'December'],
      ),
    ]) {
      testWidgets(scenario.name, (tester) async {
        await _pumpMovements(tester, [
          for (final date in scenario.dates)
            _movement(operation: date, date: date),
        ], now: scenario.now);

        for (final heading in scenario.headings) {
          expect(find.text(heading), findsOneWidget);
        }
        for (final heading in scenario.absent) {
          expect(find.text(heading), findsNothing);
        }
      });
    }

    testWidgets('localizes relative headings and month names in Spanish', (
      tester,
    ) async {
      await _pumpMovements(
        tester,
        [
          for (final date in [
            '24/10/2026',
            '23/10/2026',
            '19/10/2026',
            '18/10/2026',
            '30/09/2026',
          ])
            _movement(operation: date, date: date),
        ],
        now: DateTime(2026, 10, 24),
        locale: const Locale('es'),
      );

      for (final heading in [
        'Hoy',
        'Ayer',
        'Esta semana',
        'Este mes',
        'septiembre',
      ]) {
        expect(find.text(heading), findsOneWidget);
      }
    });
  });

  group('movement tile', () {
    testWidgets('names a top-up and credits its amount', (tester) async {
      await _pumpMovements(tester, [
        _movement(
          operation: 'Recarga online',
          amount: '10,00 €',
          activation: AucorsaRechargeActivation.activated,
        ),
      ]);

      expect(find.text('Online top-up'), findsOneWidget);
      expect(find.text('+10,00 €'), findsOneWidget);
      expect(find.byIcon(Symbols.add_card_rounded), findsOneWidget);
    });

    testWidgets('flags a top-up the site has not activated yet', (
      tester,
    ) async {
      await _pumpMovements(tester, [
        _movement(
          operation: 'Recarga online',
          amount: '10,00 €',
          activation: AucorsaRechargeActivation.pending,
        ),
      ]);

      expect(find.text('Pending online top-up'), findsOneWidget);
      expect(find.text('Online top-up'), findsNothing);
    });

    testWidgets('names a journey and debits its amount', (tester) async {
      await _pumpMovements(tester, [
        _movement(operation: 'Validación bus', amount: '-0,72 €'),
      ]);

      expect(find.text('Bus journey'), findsOneWidget);
      // The typographic minus the tile renders, not the site's hyphen.
      expect(find.text('−0,72 €'), findsOneWidget);
      expect(find.byIcon(Symbols.contactless_rounded), findsOneWidget);
    });

    testWidgets('names a transfer and leaves its amount unsigned', (
      tester,
    ) async {
      await _pumpMovements(tester, [
        _movement(operation: 'Transbordo', amount: '0,00 €'),
      ]);

      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('0,00 €'), findsOneWidget);
      expect(find.byIcon(Symbols.conversion_path_rounded), findsOneWidget);
    });

    testWidgets("shows an unknown operation in the site's own words", (
      tester,
    ) async {
      await _pumpMovements(tester, [
        _movement(operation: 'Anulación manual', amount: '1,00 €'),
      ]);

      expect(find.text('Anulación manual'), findsOneWidget);
      expect(find.text('−1,00 €'), findsOneWidget);
      expect(find.byIcon(Symbols.directions_bus_rounded), findsOneWidget);
    });

    testWidgets('reads the date whichever way the site separates it', (
      tester,
    ) async {
      await _pumpMovements(tester, [
        _movement(operation: 'Validación bus', date: '17-08-2026'),
      ]);

      expect(find.text('17-08-2026 · 12:00'), findsNothing);
    });

    testWidgets('falls back to the raw date it could not read', (tester) async {
      await _pumpMovements(tester, [
        _movement(operation: 'Validación bus', date: '17.08.2026'),
      ]);

      expect(find.text('17.08.2026 · 12:00'), findsOneWidget);
      expect(find.text('Other movements'), findsOneWidget);
    });
  });
}

Future<void> _pumpMovements(
  WidgetTester tester,
  List<AucorsaCardMovement> movements, {
  DateTime? now,
  Locale locale = const Locale('en'),
}) async {
  final site = _FakeAucorsaSite(
    loadMovements: ({required cardNumber, required page}) async =>
        AucorsaCardMovements(movements: movements, hasNextPage: false),
  );

  await tester.pumpWidget(_app(site, now: now, locale: locale));
  await tester.pumpAndSettle();
}

AucorsaCardMovement _movement({
  required String operation,
  String amount = '0,72 €',
  String date = '17/08/2026',
  String time = '12:00',
  AucorsaRechargeActivation? activation,
}) => AucorsaCardMovement(
  date: date,
  time: time,
  operation: operation,
  amount: amount,
  activation: activation,
);

Widget _app(
  _FakeAucorsaSite site, {
  DateTime? now,
  Locale locale = const Locale('en'),
}) {
  // The help button leaves the page through the router, so the test drives the
  // same two routes the app registers.
  return MaterialApp.router(
    locale: locale,
    localizationsDelegates: const [
      ...AppLocalizations.localizationsDelegates,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: GoRouter(
      initialLocation: AucorsaMovementsPage.path,
      routes: [
        GoRoute(
          path: AucorsaMovementsPage.path,
          // Mirrors what AucorsaMovementsPage does, on a cubit wired to the
          // fake site instead of the real one.
          builder: (_, _) => BlocProvider(
            create: (_) {
              unawaited(site.cubit.refresh());

              return site.cubit;
            },
            child: AucorsaMovementsView(now: now),
          ),
        ),
        GoRoute(
          path: AucorsaMovementsHelpPage.path,
          builder: (_, _) => const AucorsaMovementsHelpPage(),
        ),
      ],
    ),
  );
}

/// Stands in for the AUCORSA website, turning whatever the test returns into
/// the response the real endpoint would send back.
class _FakeAucorsaSite {
  final Future<AucorsaCardMovements> Function({
    required String cardNumber,
    required int page,
  })
  _loadMovements;

  final List<(String, int)> movementRequests = [];

  new({required this._loadMovements});

  late final Dio _client = Dio()
    ..interceptors.add(InterceptorsWrapper(onRequest: _onRequest));

  late final AucorsaMovementsCubit cubit = AucorsaMovementsCubit(
    cardNumber: '1234567890',
    client: _client,
    cookieManager: _FakeCookieManager(),
  );

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path == AucorsaApi.rootUrl) {
      handler.resolve(
        Response<String>(
          requestOptions: options,
          statusCode: 200,
          data: 'var ajax_vars = {"ajax_nonce":"session-nonce"};',
        ),
      );
      return;
    }

    final cardNumber = options.queryParameters['card_number'] as String;
    final page = options.queryParameters['page'] as int;
    movementRequests.add((cardNumber, page));

    try {
      final result = await _loadMovements(cardNumber: cardNumber, page: page);
      handler.resolve(
        Response<String>(
          requestOptions: options,
          statusCode: 200,
          data: _html(result),
        ),
      );
    } on AucorsaSessionExpiredException {
      handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 401,
          data: const {'message': 'Usuario no registrado'},
        ),
      );
    } on AucorsaCardApiException catch (error) {
      handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: {'message': error.message},
        ),
      );
    }
  }
}

/// Renders a page of movements as the grid markup the parser reads.
String _html(AucorsaCardMovements page) {
  final buffer = StringBuffer();
  for (final movement in page.movements) {
    for (final cell in [
      movement.date,
      movement.time,
      _operationCell(movement),
      movement.amount,
    ]) {
      buffer.write('<div class="grid-movements-movement">$cell</div>');
    }
  }
  if (page.hasNextPage) {
    buffer.write('<a class="card-movements-next-page"></a>');
  }

  return buffer.toString();
}

/// The operation cell, carrying the coloured marker the site puts in front of
/// a top-up so its activation state survives the trip through the markup.
String _operationCell(AucorsaCardMovement movement) =>
    switch (movement.activation) {
      null => movement.operation,
      AucorsaRechargeActivation.activated =>
        '<span title="Activada" style="color: green">\u25cf</span> '
            '${movement.operation}',
      AucorsaRechargeActivation.pending =>
        '<span title="Pendiente" style="color: red">\u25cf</span> '
            '${movement.operation}',
    };

class _FakeCookieManager implements CookieManager {
  @override
  Future<List<Cookie>> getCookies({
    required WebUri url,
    InAppWebViewController? iosBelow11WebViewController,
    InAppWebViewController? webViewController,
  }) async => [Cookie(name: 'wordpress_logged_in', value: 'token')];

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
