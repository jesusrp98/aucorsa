import 'dart:async';

import 'package:aucorsa/bonobus/cubits/aucorsa_movements_cubit.dart';
import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/pages/aucorsa_movements_help_page.dart';
import 'package:aucorsa/bonobus/pages/aucorsa_movements_page.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_api.dart';
import 'package:aucorsa/common/widgets/big_tip.dart';
import 'package:aucorsa/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Storage;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
    final site = _FakeAucorsaSite(
      loadMovements: ({required cardNumber, required page}) async {
        throw const AucorsaSessionExpiredException();
      },
    );

    await tester.pumpWidget(_app(site));
    await tester.pumpAndSettle();

    expect(find.byType(BigTip), findsOneWidget);
    expect(find.text('Connect your AUCORSA account'), findsOneWidget);
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

    await tester.pumpWidget(_app(site));
    await tester.pumpAndSettle();

    expect(site.movementRequests, [(cardNumber, 1), (cardNumber, 2)]);
    expect(find.text('Bus journey'), findsNWidgets(2));
  });

  testWidgets('points to the help button when AUCORSA returns no movements', (
    tester,
  ) async {
    final site = _FakeAucorsaSite(
      loadMovements: ({required cardNumber, required page}) async {
        return const AucorsaCardMovements(
          movements: [],
          hasNextPage: false,
        );
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
    expect(
      find.text('Activate the account from your email'),
      findsOneWidget,
    );
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
    final site = _FakeAucorsaSite(
      loadMovements: ({required cardNumber, required page}) =>
          downloaded.future,
    );

    await tester.pumpWidget(_app(site));
    await tester.pump();

    expect(find.text('Bus journey'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    downloaded.complete(
      const AucorsaCardMovements(
        movements: [],
        hasNextPage: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}

Widget _app(_FakeAucorsaSite site) {
  // The help button leaves the page through the router, so the test drives the
  // same two routes the app registers.
  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
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
            child: const AucorsaMovementsView(),
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

  _FakeAucorsaSite({
    required Future<AucorsaCardMovements> Function({
      required String cardNumber,
      required int page,
    })
    loadMovements,
  }) : _loadMovements = loadMovements;

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
      movement.operation,
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
