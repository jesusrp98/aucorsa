import 'dart:async';

import 'package:aucorsa/bonobus/cubits/aucorsa_movements_cubit.dart';
import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Storage;
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  late _MemoryStorage storage;

  setUp(() {
    storage = _MemoryStorage();
    HydratedBloc.storage = storage;
  });

  test(
    'updateId keeps the provider and drops the previous card data',
    () async {
      final cubit = BonobusCubit(client: _failingClient())
        ..selectProvider(BonobusProvider.aucorsa, id: '0546174400')
        ..scanned(balance: '8.87 €');
      addTearDown(cubit.close);

      await cubit.updateId('1234567890');

      expect(cubit.state.provider, BonobusProvider.aucorsa);
      expect(cubit.state.id, '1234567890');
      expect(cubit.state.balance, isNull);
      expect(cubit.state.name, isNull);
    },
  );

  test('updateId drops the movements stored for the previous card', () async {
    await storage.write(
      AucorsaMovementsCubit.storageKey('0546174400'),
      {'movements': <Object>[]},
    );
    final cubit = BonobusCubit(client: _failingClient())
      ..selectProvider(BonobusProvider.aucorsa, id: '0546174400');
    addTearDown(cubit.close);

    await cubit.updateId('1234567890');

    expect(
      storage.read(AucorsaMovementsCubit.storageKey('0546174400')),
      isNull,
    );
  });

  test('updateId keeps the movements of an unchanged card number', () async {
    await storage.write(
      AucorsaMovementsCubit.storageKey('0546174400'),
      {'movements': <Object>[]},
    );
    final cubit = BonobusCubit(client: _failingClient())
      ..selectProvider(BonobusProvider.aucorsa, id: '0546174400');
    addTearDown(cubit.close);

    await cubit.updateId('0546174400');

    expect(
      storage.read(AucorsaMovementsCubit.storageKey('0546174400')),
      isNotNull,
    );
  });

  test('loads a public card balance without sending account cookies', () async {
    final requests = <RequestOptions>[];
    final cubit = BonobusCubit(client: _cardClient(requests))
      ..selectProvider(BonobusProvider.aucorsa, id: '1234567890');
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(cubit.state.status, BonobusStatus.loaded);
    expect(cubit.state.name, 'Tarjeta Ordinaria');
    expect(cubit.state.balance, '12.34 €');
    expect(cubit.state.error, isNull);
    expect(cubit.state.lastUpdated, isNotNull);

    expect(requests, hasLength(2));
    expect(
      requests.last.uri.path,
      '/wp-json/aucorsa/v1/ui/forms/recharge/secondary',
    );
    expect(requests.last.queryParameters, {
      'card_number': '1234567890',
      'token': '1',
      'show_extra_content': '1',
      '_wpnonce': 'public-nonce',
    });
    expect(
      requests.every((request) => !request.headers.containsKey('Cookie')),
      isTrue,
    );
  });

  test('keeps the cached details and reports the message on failure', () async {
    final cubit = BonobusCubit(client: _cardClient([]))
      ..selectProvider(BonobusProvider.aucorsa, id: '1234567890');
    addTearDown(cubit.close);

    await cubit.refresh();
    expect(cubit.state.balance, '12.34 €');

    final failing = BonobusCubit(
      client: _cardClient([], error: 'Tarjeta no encontrada'),
    )..selectProvider(BonobusProvider.aucorsa, id: '1234567890');
    addTearDown(failing.close);

    await failing.refresh();

    expect(failing.state.status, BonobusStatus.loaded);
    expect(failing.state.error, 'Tarjeta no encontrada');

    failing.clearError();
    expect(failing.state.error, isNull);
  });

  test('does not reach the network for a Consorcio bonobus', () async {
    final requests = <RequestOptions>[];
    final cubit = BonobusCubit(client: _cardClient(requests))
      ..selectProvider(BonobusProvider.consorcio, id: '1234567890');
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(requests, isEmpty);
    expect(cubit.state.status, BonobusStatus.initial);
  });

  test('delete clears cookies and website storage for every origin', () async {
    final cookies = _FakeCookieManager();
    final webStorage = _FakeWebStorageManager();
    final cubit = _deletingCubit(cookies, webStorage);
    addTearDown(cubit.close);

    await cubit.delete();

    expect(cookies.deletedUrls.map((url) => url.toString()), {
      'https://aucorsa.es/',
      'https://www.aucorsa.es/',
    });
    expect(webStorage.deletedOrigins, {
      'https://aucorsa.es',
      'https://www.aucorsa.es',
    });
    expect(cubit.state, const BonobusState());
  });

  test('delete uses the supported website-data cleanup API on iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final cookies = _FakeCookieManager();
    final webStorage = _FakeWebStorageManager();
    final cubit = _deletingCubit(cookies, webStorage);
    addTearDown(cubit.close);

    await cubit.delete();

    expect(webStorage.deletedOrigins, isEmpty);
    expect(webStorage.removedDataTypes, WebsiteDataType.ALL);
  });

  test('delete drops the legacy and movements caches together', () async {
    await storage.write('AucorsaCardsCubit', {'cards': <Object>[]});
    await storage.write(
      AucorsaMovementsCubit.storageKey('1234567890'),
      {'movements': <Object>[]},
    );
    final cubit = _deletingCubit(
      _FakeCookieManager(),
      _FakeWebStorageManager(),
    );
    addTearDown(cubit.close);

    await cubit.delete();

    expect(storage.read('AucorsaCardsCubit'), isNull);
    expect(
      storage.read(AucorsaMovementsCubit.storageKey('1234567890')),
      isNull,
    );
  });

  test('refreshes a rejected nonce and asks for the card again', () async {
    final site = _RawCardSite(
      nonces: ['stale-nonce', 'fresh-nonce'],
      onCard: (options, attempt) async => attempt == 0
          ? _json(options, 403, {'code': 'rest_cookie_invalid_nonce'})
          : _json(options, 200, {'error': 0, 'content': _cardMarkup}),
    );
    final cubit = BonobusCubit(client: site.client)
      ..selectProvider(BonobusProvider.aucorsa, id: '1234567890');
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(cubit.state.balance, '12.34 €');
    expect(cubit.state.error, isNull);
    expect(site.sentNonces, ['stale-nonce', 'fresh-nonce']);
  });

  test('stops after one nonce retry instead of looping', () async {
    final site = _RawCardSite(
      nonces: ['stale-nonce', 'also-stale'],
      onCard: (options, _) async =>
          _json(options, 403, {'code': 'rest_cookie_invalid_nonce'}),
    );
    final cubit = BonobusCubit(client: site.client)
      ..selectProvider(BonobusProvider.aucorsa, id: '1234567890');
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(site.sentNonces, hasLength(2));
    expect(cubit.state.error, contains('403'));
  });

  test('reports the status behind an error page the site served', () async {
    final site = _RawCardSite(
      onCard: (options, _) async => _markup(options, 500, '<html>Oops</html>'),
    );
    final cubit = BonobusCubit(client: site.client)
      ..selectProvider(BonobusProvider.aucorsa, id: '1234567890');
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(cubit.state.error, 'AUCORSA card request failed (500)');
  });

  test('reports a readable failure for an unreadable body', () async {
    final site = _RawCardSite(
      onCard: (options, _) async => _markup(options, 200, 'not json at all'),
    );
    final cubit = BonobusCubit(client: site.client)
      ..selectProvider(BonobusProvider.aucorsa, id: '1234567890');
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(cubit.state.error, 'AUCORSA returned an invalid response');
  });

  test('reports a flagged error the site left unworded', () async {
    final site = _RawCardSite(
      onCard: (options, _) async => _json(options, 200, {'error': true}),
    );
    final cubit = BonobusCubit(client: site.client)
      ..selectProvider(BonobusProvider.aucorsa, id: '1234567890');
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(cubit.state.error, 'AUCORSA could not load the card');
  });

  test('reports a response that carries no card at all', () async {
    final site = _RawCardSite(
      onCard: (options, _) async => _json(options, 200, {'error': 0}),
    );
    final cubit = BonobusCubit(client: site.client)
      ..selectProvider(BonobusProvider.aucorsa, id: '1234567890');
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(cubit.state.error, 'AUCORSA returned incomplete card details');
  });

  test('leaves the wording to the app when the markup changed', () async {
    // A parse failure says nothing a user could act on, so the UI is left to
    // fall back to its own generic message.
    final site = _RawCardSite(
      onCard: (options, _) async =>
          _json(options, 200, {'error': 0, 'content': '<div></div>'}),
    );
    final cubit = BonobusCubit(client: site.client)
      ..selectProvider(BonobusProvider.aucorsa, id: '1234567890');
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(cubit.state.error, isEmpty);
  });

  test('leaves the wording to the app when the nonce is gone', () async {
    final site = _RawCardSite(
      nonces: const [],
      onCard: (options, _) async =>
          _json(options, 200, {'error': 0, 'content': _cardMarkup}),
    );
    final cubit = BonobusCubit(client: site.client)
      ..selectProvider(BonobusProvider.aucorsa, id: '1234567890');
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(cubit.state.error, isEmpty);
    expect(site.sentNonces, isEmpty);
  });

  test('drops a response for a card the user already replaced', () async {
    final answer = Completer<void>();
    final site = _RawCardSite(
      onCard: (options, _) async {
        await answer.future;
        return _json(options, 200, {'error': 0, 'content': _cardMarkup});
      },
    );
    final cubit = BonobusCubit(client: site.client)
      ..selectProvider(BonobusProvider.aucorsa, id: '1234567890');
    addTearDown(cubit.close);

    final refreshing = cubit.refresh();
    cubit.selectProvider(BonobusProvider.aucorsa, id: '9999999999');
    answer.complete();
    await refreshing;

    expect(cubit.state.id, '9999999999');
    expect(cubit.state.balance, isNull);
    expect(cubit.state.name, isNull);
  });

  test('does not reach the network without a card to load', () async {
    final site = _RawCardSite(
      onCard: (options, _) async => _json(options, 200, {'error': 0}),
    );
    final cubit = BonobusCubit(client: site.client);
    addTearDown(cubit.close);

    await cubit.refresh();

    expect(site.nonceRequests, 0);
    expect(cubit.state, const BonobusState());
  });

  test('scanned records the balance and when it was read', () {
    final cubit = BonobusCubit(client: _failingClient())
      ..selectProvider(BonobusProvider.consorcio)
      ..scanned(id: '1234567890', balance: '8.87 €');
    addTearDown(cubit.close);

    expect(cubit.state.status, BonobusStatus.loaded);
    expect(cubit.state.id, '1234567890');
    expect(cubit.state.balance, '8.87 €');
    expect(cubit.state.lastUpdated, isNotNull);
  });

  test('clearError leaves an untouched state alone', () {
    final cubit = BonobusCubit(client: _failingClient());
    addTearDown(cubit.close);

    cubit.clearError();

    expect(cubit.state, const BonobusState());
  });

  test('delete reports when the cookies could not be removed', () async {
    final cookies = _FakeCookieManager(canDelete: false);
    final cubit = _deletingCubit(cookies, _FakeWebStorageManager());
    addTearDown(cubit.close);

    await expectLater(cubit.delete(), throwsA(isA<AucorsaCardApiException>()));

    // The bonobus stays put, so the user can try removing it again.
    expect(cubit.state.id, '1234567890');
  });

  test('delete leaves a Consorcio bonobus account data alone', () async {
    final cookies = _FakeCookieManager();
    final cubit = BonobusCubit(
      client: _failingClient(),
      cookieManager: cookies,
      webStorageManager: _FakeWebStorageManager(),
    )..selectProvider(BonobusProvider.consorcio, id: '1234567890');
    addTearDown(cubit.close);

    await cubit.delete();

    expect(cookies.deletedUrls, isEmpty);
    expect(cubit.state, const BonobusState());
  });
}

BonobusCubit _deletingCubit(
  _FakeCookieManager cookies,
  _FakeWebStorageManager webStorage,
) => BonobusCubit(
  client: _failingClient(),
  cookieManager: cookies,
  webStorageManager: webStorage,
)..selectProvider(BonobusProvider.aucorsa, id: '1234567890');

/// A client that fails any request, for the cases that must not reach out.
Dio _failingClient() => Dio()
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) =>
          handler.reject(DioException(requestOptions: options)),
    ),
  );

/// Answers the nonce page and the public card endpoint, recording every call.
Dio _cardClient(List<RequestOptions> requests, {String? error}) =>
    Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            if (options.path == AucorsaApi.rootUrl) {
              handler.resolve(
                Response<String>(
                  requestOptions: options,
                  statusCode: 200,
                  data: 'var ajax_vars = {"ajax_nonce":"public-nonce"};',
                ),
              );
              return;
            }

            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: error != null
                    ? {'error': 1, 'error_msg': error}
                    : {
                        'error': 0,
                        'content': '''
                      <div class="card-number-content">TARJETA ORDINARIA</div>
                      <div class="card-number-title">1234567890</div>
                      <div class="card-real-balance">12.34 &euro;</div>
                    ''',
                      },
              ),
            );
          },
        ),
      );

const _cardMarkup =
    '<div class="card-number-content">TARJETA ORDINARIA</div> '
    '<div class="card-real-balance">12.34 &euro;</div>';

Response<dynamic> _markup(RequestOptions options, int status, String body) =>
    Response<String>(
      requestOptions: options,
      statusCode: status,
      data: body,
    );

Response<dynamic> _json(
  RequestOptions options,
  int status,
  Map<String, dynamic> body,
) => Response<Map<String, dynamic>>(
  requestOptions: options,
  statusCode: status,
  data: body,
);

/// Answers at the HTTP level, so the responses the cubit has to tell apart —
/// a stale nonce, an error page, a flagged failure — can be handed to it
/// exactly as the endpoint would.
class _RawCardSite {
  final List<String> nonces;
  final Future<Response<dynamic>> Function(RequestOptions options, int attempt)
  onCard;

  final List<String> sentNonces = [];
  int nonceRequests = 0;
  int _attempts = 0;

  late final Dio client = Dio()
    ..interceptors.add(InterceptorsWrapper(onRequest: _onRequest));

  _RawCardSite({required this.onCard, this.nonces = const ['first-nonce']});

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path == AucorsaApi.rootUrl) {
      // Running past the end stands for a site that stopped publishing one.
      final nonce = nonceRequests < nonces.length
          ? nonces[nonceRequests]
          : null;
      nonceRequests++;
      handler.resolve(
        Response<String>(
          requestOptions: options,
          statusCode: 200,
          data: nonce == null ? '<html></html>' : '{"ajax_nonce":"$nonce"}',
        ),
      );
      return;
    }

    sentNonces.add(options.queryParameters['_wpnonce'] as String);
    handler.resolve(await onCard(options, _attempts++));
  }
}

class _FakeCookieManager implements CookieManager {
  final List<WebUri> deletedUrls = [];
  final bool canDelete;

  _FakeCookieManager({this.canDelete = true});

  @override
  Future<bool> deleteCookies({
    required WebUri url,
    String path = '/',
    String? domain,
    InAppWebViewController? iosBelow11WebViewController,
    InAppWebViewController? webViewController,
  }) async {
    deletedUrls.add(url);
    return canDelete;
  }

  @override
  Future<void> flush() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWebStorageManager implements WebStorageManager {
  final Set<String> deletedOrigins = {};
  Set<WebsiteDataType>? removedDataTypes;

  @override
  Future<void> deleteOrigin({required String origin}) async {
    deletedOrigins.add(origin);
  }

  @override
  Future<void> removeDataModifiedSince({
    required Set<WebsiteDataType> dataTypes,
    required DateTime date,
  }) async {
    removedDataTypes = dataTypes;
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
