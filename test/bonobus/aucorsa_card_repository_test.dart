import 'package:aucorsa/bonobus/repositories/aucorsa_card_repository.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_account_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Storage;
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  test('loads a public card balance without sending account cookies', () async {
    final requests = <RequestOptions>[];
    final client = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            if (options.path == AucorsaCardRepository.rootUrl) {
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
                data: {
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
    final repository = AucorsaCardRepository(client: client);

    final card = await repository.loadPublicCard('1234567890');

    expect(card.number, '1234567890');
    expect(card.title, 'Tarjeta Ordinaria');
    expect(card.balance, '12.34 €');
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

    repository.close();
  });

  test('clears cookies and website storage for every AUCORSA origin', () async {
    final cookies = _FakeCookieManager();
    final webStorage = _FakeWebStorageManager();
    final repository = AucorsaCardRepository(
      client: Dio(),
      cookieManager: cookies,
      webStorageManager: webStorage,
    );
    addTearDown(repository.close);

    await repository.clearAccountData();

    expect(cookies.deletedUrls.map((url) => url.toString()), {
      'https://aucorsa.es/',
      'https://www.aucorsa.es/',
    });
    expect(webStorage.deletedOrigins, {
      'https://aucorsa.es',
      'https://www.aucorsa.es',
    });
  });

  test('uses the supported website-data cleanup API on iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final cookies = _FakeCookieManager();
    final webStorage = _FakeWebStorageManager();
    final repository = AucorsaCardRepository(
      client: Dio(),
      cookieManager: cookies,
      webStorageManager: webStorage,
    );
    addTearDown(repository.close);

    await repository.clearAccountData();

    expect(webStorage.deletedOrigins, isEmpty);
    expect(webStorage.removedDataTypes, WebsiteDataType.ALL);
  });

  test(
    'clears the AUCORSA session and legacy account cache together',
    () async {
      final repository = _ClearingRepository();
      final storage = _MemoryStorage();
      await storage.write('AucorsaCardsCubit', {'cards': <Object>[]});

      await AucorsaAccountData.clear(
        repository: repository,
        storage: storage,
      );

      expect(repository.cleared, isTrue);
      expect(storage.read('AucorsaCardsCubit'), isNull);
    },
  );
}

class _FakeCookieManager implements CookieManager {
  final List<WebUri> deletedUrls = [];

  @override
  Future<bool> deleteCookies({
    required WebUri url,
    String path = '/',
    String? domain,
    InAppWebViewController? iosBelow11WebViewController,
    InAppWebViewController? webViewController,
  }) async {
    deletedUrls.add(url);
    return true;
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

class _ClearingRepository implements AucorsaCardRepository {
  bool cleared = false;

  @override
  Future<void> clearAccountData() async => cleared = true;

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
