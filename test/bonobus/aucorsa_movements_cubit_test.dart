import 'dart:async';

import 'package:aucorsa/bonobus/cubits/aucorsa_movements_cubit.dart';
import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_api.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Storage;
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  late _MemoryStorage storage;

  setUp(() {
    storage = _MemoryStorage();
    HydratedBloc.storage = storage;
  });

  group('AucorsaMovementsCubit', () {
    test('appends pages and stops after reaching the last page', () async {
      final site = _FakeAucorsaSite((page) async {
        return switch (page) {
          1 => _page([_movement('First')], hasNextPage: true),
          2 => _page([_movement('Second')]),
          _ => throw StateError('Unexpected page $page'),
        };
      });
      final cubit = _buildCubit(site);
      addTearDown(cubit.close);

      await cubit.loadMore();
      await cubit.loadMore();
      await cubit.loadMore();

      expect(site.requestedPages, [1, 2]);
      expect(
        cubit.state.movements.map((movement) => movement.operation),
        ['First', 'Second'],
      );
      expect(cubit.state.hasReachedMax, isTrue);
      expect(cubit.state.nextPage, 3);
    });

    test('does not start concurrent page requests', () async {
      final response = Completer<AucorsaCardMovements>();
      final site = _FakeAucorsaSite((_) => response.future);
      final cubit = _buildCubit(site);
      addTearDown(cubit.close);

      final firstRequest = cubit.loadMore();
      await cubit.loadMore();
      // Let the first request travel through the client before counting it.
      await pumpEventQueue();

      expect(site.requestedPages, [1]);

      response.complete(_page([_movement('First')]));
      await firstRequest;
    });

    test('keeps loaded movements and retries the same failed page', () async {
      var pageTwoAttempts = 0;
      final site = _FakeAucorsaSite((page) async {
        if (page == 1) {
          return _page([_movement('First')], hasNextPage: true);
        }
        pageTwoAttempts++;
        if (pageTwoAttempts == 1) throw StateError('Temporary failure');
        return _page([_movement('Second')]);
      });
      final cubit = _buildCubit(site);
      addTearDown(cubit.close);

      await cubit.loadMore();
      await cubit.loadMore();

      expect(cubit.state.status, AucorsaMovementsStatus.failure);
      expect(cubit.state.nextPage, 2);
      expect(cubit.state.movements, [_movement('First')]);

      await cubit.loadMore();

      expect(site.requestedPages, [1, 2, 2]);
      expect(cubit.state.status, AucorsaMovementsStatus.loaded);
      expect(cubit.state.movements, [
        _movement('First'),
        _movement('Second'),
      ]);
    });

    test('refresh replaces the history when pages no longer overlap', () async {
      var pageOneLoads = 0;
      final site = _FakeAucorsaSite((page) async {
        if (page == 1) {
          pageOneLoads++;
          return _page(
            [_movement(pageOneLoads == 1 ? 'Old first' : 'Fresh first')],
            hasNextPage: true,
          );
        }
        return _page([_movement('Old second')]);
      });
      final cubit = _buildCubit(site);
      addTearDown(cubit.close);

      await cubit.loadMore();
      await cubit.loadMore();
      await cubit.refresh();

      expect(site.requestedPages, [1, 2, 1]);
      expect(cubit.state.movements, [_movement('Fresh first')]);
      expect(cubit.state.nextPage, 2);
      expect(cubit.state.hasReachedMax, isFalse);
    });

    test(
      'refresh keeps the stored history and prepends new movements',
      () async {
        var pageOneLoads = 0;
        final site = _FakeAucorsaSite((page) async {
          if (page == 1) {
            pageOneLoads++;
            return _page(
              [
                if (pageOneLoads > 1) _movement('Brand new'),
                _movement('First'),
              ],
              hasNextPage: true,
            );
          }
          return _page([_movement('Second')]);
        });
        final cubit = _buildCubit(site);
        addTearDown(cubit.close);

        await cubit.loadMore();
        await cubit.loadMore();
        await cubit.refresh();

        expect(
          cubit.state.movements.map((movement) => movement.operation),
          ['Brand new', 'First', 'Second'],
        );
        expect(cubit.state.nextPage, 3);
        expect(cubit.state.hasReachedMax, isTrue);
      },
    );

    test('refresh keeps the stored movements visible while loading', () async {
      final response = Completer<AucorsaCardMovements>();
      var pageOneLoads = 0;
      final site = _FakeAucorsaSite((_) {
        pageOneLoads++;
        if (pageOneLoads == 1) return Future.value(_page([_movement('First')]));
        return response.future;
      });
      final cubit = _buildCubit(site);
      addTearDown(cubit.close);

      await cubit.loadMore();
      final refreshing = cubit.refresh();

      expect(cubit.state.refreshing, isTrue);
      expect(cubit.state.movements, [_movement('First')]);

      response.complete(_page([_movement('First')]));
      await refreshing;

      expect(cubit.state.refreshing, isFalse);
      expect(cubit.state.movements, [_movement('First')]);
    });

    test('refresh keeps the stored movements when it fails', () async {
      var pageOneLoads = 0;
      final site = _FakeAucorsaSite((_) async {
        pageOneLoads++;
        if (pageOneLoads == 1) return _page([_movement('First')]);
        throw StateError('Temporary failure');
      });
      final cubit = _buildCubit(site);
      addTearDown(cubit.close);

      await cubit.loadMore();
      await cubit.refresh();

      expect(cubit.state.status, AucorsaMovementsStatus.failure);
      expect(cubit.state.refreshing, isFalse);
      expect(cubit.state.movements, [_movement('First')]);
    });

    test('keeps a copy of the session the web view handed out', () async {
      final site = _FakeAucorsaSite((_) async => _page([_movement('First')]));
      final cubit = _buildCubit(site);
      addTearDown(cubit.close);

      await cubit.loadMore();

      expect(AucorsaSession.read(storage), 'wordpress_logged_in=token');
    });

    test('loads movements after a restart emptied the cookie jar', () async {
      // What the previous run stored, with a jar that came back empty.
      await AucorsaSession.save('wordpress_logged_in=token', storage);
      final site = _FakeAucorsaSite(
        (_) async => _page([_movement('First')]),
        signedIn: false,
      );
      final cubit = _buildCubit(site);
      addTearDown(cubit.close);

      await cubit.loadMore();

      expect(cubit.state.status, AucorsaMovementsStatus.loaded);
      expect(cubit.state.movements, [_movement('First')]);
      expect(site.sentCookieHeaders, everyElement('wordpress_logged_in=token'));
    });

    test('asks for a sign in when nothing is stored either', () async {
      final site = _FakeAucorsaSite(
        (_) async => _page([_movement('First')]),
        signedIn: false,
      );
      final cubit = _buildCubit(site);
      addTearDown(cubit.close);

      await cubit.loadMore();

      expect(cubit.state.status, AucorsaMovementsStatus.unauthenticated);
    });

    test('drops the stored session once the site rejects it', () async {
      await AucorsaSession.save('wordpress_logged_in=stale', storage);
      final site = _FakeAucorsaSite(
        (_) async => throw const AucorsaSessionExpiredException(),
        signedIn: false,
      );
      final cubit = _buildCubit(site);
      addTearDown(cubit.close);

      await cubit.loadMore();

      expect(cubit.state.status, AucorsaMovementsStatus.unauthenticated);
      expect(AucorsaSession.read(storage), isEmpty);
    });

    test('stores downloaded movements and restores them on creation', () async {
      final site = _FakeAucorsaSite((page) async {
        return switch (page) {
          1 => _page([_movement('First')], hasNextPage: true),
          _ => _page([_movement('Second')]),
        };
      });
      final cubit = _buildCubit(site);
      await cubit.loadMore();
      await cubit.loadMore();
      await cubit.close();

      final restored = _buildCubit(site);
      addTearDown(restored.close);

      expect(storage.read(AucorsaMovementsCubit.storageKey('123')), isNotNull);
      expect(restored.state.status, AucorsaMovementsStatus.loaded);
      expect(restored.state.movements, [
        _movement('First'),
        _movement('Second'),
      ]);
      expect(restored.state.nextPage, 3);
      expect(restored.state.hasReachedMax, isTrue);
    });
  });
}

AucorsaMovementsCubit _buildCubit(_FakeAucorsaSite site) {
  return AucorsaMovementsCubit(
    cardNumber: '123',
    client: site.client,
    cookieManager: site.cookies,
  );
}

AucorsaCardMovements _page(
  List<AucorsaCardMovement> movements, {
  bool hasNextPage = false,
}) {
  return AucorsaCardMovements(
    movements: movements,
    hasPreviousPage: false,
    hasNextPage: hasNextPage,
  );
}

AucorsaCardMovement _movement(String operation) {
  return AucorsaCardMovement(
    date: '19/07/2026',
    time: '12:00',
    operation: operation,
    amount: '-0.72 €',
  );
}

/// Stands in for the AUCORSA website: it hands out a nonce, keeps the user
/// signed in, and renders whatever [onLoad] returns as the movements markup
/// the real endpoint would send back.
class _FakeAucorsaSite {
  final Future<AucorsaCardMovements> Function(int page) onLoad;
  final List<int> requestedPages = [];
  final List<String> sentCookieHeaders = [];
  final _FakeCookieManager cookies;

  late final Dio client = Dio()
    ..interceptors.add(InterceptorsWrapper(onRequest: _onRequest));

  /// [signedIn] mirrors whether the web view jar still holds the session,
  /// which it does not after the app is restarted.
  _FakeAucorsaSite(this.onLoad, {bool signedIn = true})
    : cookies = _FakeCookieManager(signedIn: signedIn);

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

    final page = options.queryParameters['page'] as int;
    requestedPages.add(page);
    sentCookieHeaders.add(options.headers['Cookie']?.toString() ?? '');
    try {
      handler.resolve(
        Response<String>(
          requestOptions: options,
          statusCode: 200,
          data: _html(await onLoad(page)),
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
    } catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
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
  if (page.hasPreviousPage) {
    buffer.write('<a class="card-movements-prev-page"></a>');
  }
  if (page.hasNextPage) {
    buffer.write('<a class="card-movements-next-page"></a>');
  }

  return buffer.toString();
}

class _FakeCookieManager implements CookieManager {
  final bool signedIn;

  _FakeCookieManager({required this.signedIn});

  @override
  Future<List<Cookie>> getCookies({
    required WebUri url,
    InAppWebViewController? iosBelow11WebViewController,
    InAppWebViewController? webViewController,
  }) async => [
    if (signedIn) Cookie(name: 'wordpress_logged_in', value: 'token'),
  ];

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
