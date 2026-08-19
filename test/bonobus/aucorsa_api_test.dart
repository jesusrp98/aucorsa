import 'package:aucorsa/bonobus/utils/aucorsa_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('loadNonce', () {
    test('reads the nonce the index page publishes', () async {
      final requests = <RequestOptions>[];

      final nonce = await AucorsaApi.loadNonce(
        _indexClient(requests, 'var ajax_vars = {"ajax_nonce":"abc123"};'),
      );

      expect(nonce, 'abc123');
      expect(requests.single.path, AucorsaApi.rootUrl);
    });

    test('tolerates the whitespace the site puts around the value', () async {
      final nonce = await AucorsaApi.loadNonce(
        _indexClient([], '{ "ajax_nonce"  :   "spaced-out" }'),
      );

      expect(nonce, 'spaced-out');
    });

    test('sends the session cookies when it is given some', () async {
      final requests = <RequestOptions>[];

      await AucorsaApi.loadNonce(
        _indexClient(requests, '{"ajax_nonce":"abc123"}'),
        'wordpress_logged_in=token',
      );

      expect(requests.single.headers['Cookie'], 'wordpress_logged_in=token');
    });

    test('asks anonymously when there are no cookies to send', () async {
      final requests = <RequestOptions>[];

      await AucorsaApi.loadNonce(_indexClient(requests, '{"ajax_nonce":"a"}'));

      expect(requests.single.headers.containsKey('Cookie'), isFalse);
    });

    test('busts any cache sitting between the app and the site', () async {
      final requests = <RequestOptions>[];

      await AucorsaApi.loadNonce(_indexClient(requests, '{"ajax_nonce":"a"}'));

      expect(requests.single.queryParameters['_'], isA<int>());
    });

    test('reports an expired session when the page has no nonce', () async {
      expect(
        () => AucorsaApi.loadNonce(
          _indexClient([], '<html>Inicia sesión</html>'),
        ),
        throwsA(isA<AucorsaSessionExpiredException>()),
      );
    });

    test('reports an expired session when the page comes back empty', () async {
      expect(
        () => AucorsaApi.loadNonce(_indexClient([], null)),
        throwsA(isA<AucorsaSessionExpiredException>()),
      );
    });
  });

  group('cookieHeader', () {
    test('joins every stored cookie into one header value', () async {
      final cookies = _FakeCookieManager([
        Cookie(name: 'wordpress_logged_in_abc', value: 'token'),
        Cookie(name: 'wordpress_sec_abc', value: 'secure'),
      ]);

      expect(
        await AucorsaApi.cookieHeader(cookies),
        'wordpress_logged_in_abc=token; wordpress_sec_abc=secure',
      );
    });

    test('is empty when the user has not signed in yet', () async {
      expect(await AucorsaApi.cookieHeader(_FakeCookieManager([])), isEmpty);
    });

    test('skips cookies the platform handed back unusable', () async {
      final cookies = _FakeCookieManager([
        Cookie(name: 'kept', value: 'value'),
        Cookie(name: '', value: 'nameless'),
        Cookie(name: 'valueless', value: ''),
        Cookie(name: 'not_a_string', value: 42),
      ]);

      expect(await AucorsaApi.cookieHeader(cookies), 'kept=value');
    });
  });

  group('headers', () {
    test('always asks for a fresh response', () {
      expect(AucorsaApi.headers()['Cache-Control'], 'no-cache');
    });

    test('carries the session only when there is one', () {
      expect(AucorsaApi.headers().containsKey('Cookie'), isFalse);
      expect(AucorsaApi.headers('a=b')['Cookie'], 'a=b');
    });
  });

  group('jsonObject', () {
    test('passes a decoded object straight through', () {
      expect(AucorsaApi.jsonObject({'error': 0}), {'error': 0});
    });

    test('widens a map the client typed loosely', () {
      expect(AucorsaApi.jsonObject(<dynamic, dynamic>{'error': 0}), {
        'error': 0,
      });
    });

    test('decodes an object the client left as text', () {
      expect(AucorsaApi.jsonObject('{"error":0}'), {'error': 0});
    });

    test('rejects the error page the site serves instead of JSON', () {
      expect(
        () => AucorsaApi.jsonObject('<html><body>500</body></html>'),
        throwsA(isA<AucorsaCardApiException>()),
      );
    });

    test('rejects JSON that is not an object', () {
      expect(
        () => AucorsaApi.jsonObject('[1, 2, 3]'),
        throwsA(isA<AucorsaCardApiException>()),
      );
    });

    test('rejects a body of any other shape', () {
      expect(
        () => AucorsaApi.jsonObject(42),
        throwsA(isA<AucorsaCardApiException>()),
      );
    });
  });

  group('stringResponse', () {
    test('passes the markup fragment through', () {
      expect(AucorsaApi.stringResponse('<div></div>'), '<div></div>');
    });

    test('rejects a body that is not markup at all', () {
      expect(
        () => AucorsaApi.stringResponse({'error': 1}),
        throwsA(isA<AucorsaCardApiException>()),
      );
    });
  });

  group('isAuthenticationError', () {
    test('recognises every rejection the site words differently', () {
      expect(AucorsaApi.isAuthenticationError('Usuario no registrado'), isTrue);
      expect(AucorsaApi.isAuthenticationError('No tiene permisos'), isTrue);
      expect(AucorsaApi.isAuthenticationError('Inicia sesión'), isTrue);
    });

    test('ignores the casing the site happens to use', () {
      expect(AucorsaApi.isAuthenticationError('USUARIO NO REGISTRADO'), isTrue);
    });

    test('leaves an unrelated failure alone', () {
      expect(
        AucorsaApi.isAuthenticationError('Tarjeta no encontrada'),
        isFalse,
      );
    });
  });

  group('hasApiError', () {
    test('reads every flag the site uses for a failure', () {
      expect(AucorsaApi.hasApiError(true), isTrue);
      expect(AucorsaApi.hasApiError(1), isTrue);
      expect(AucorsaApi.hasApiError('1'), isTrue);
    });

    test('reads every flag the site uses for a success', () {
      expect(AucorsaApi.hasApiError(false), isFalse);
      expect(AucorsaApi.hasApiError(0), isFalse);
      expect(AucorsaApi.hasApiError('0'), isFalse);
      expect(AucorsaApi.hasApiError(''), isFalse);
      expect(AucorsaApi.hasApiError(null), isFalse);
    });
  });

  group('persistSession', () {
    test('gives the WordPress session cookies an expiry date', () async {
      final cookies = _FakeCookieManager([
        Cookie(name: 'wordpress_logged_in_abc', value: 'token'),
        Cookie(name: 'wordpress_sec_abc', value: 'secure-token'),
      ]);

      await AucorsaApi.persistSession(cookies);

      // Once for aucorsa.es and once for www.aucorsa.es.
      expect(cookies.stored, hasLength(4));
      expect(
        cookies.stored.map((cookie) => cookie.name).toSet(),
        {'wordpress_logged_in_abc', 'wordpress_sec_abc'},
      );
      expect(
        cookies.stored.every((cookie) => cookie.expiresDate != null),
        isTrue,
      );
      expect(
        cookies.stored.every((cookie) => cookie.isHttpOnly ?? false),
        isTrue,
      );
    });

    test('stores cookies the platform reports as session only', () async {
      final cookies = _FakeCookieManager([
        Cookie(name: 'aucorsa_session', value: 'token', isSessionOnly: true),
      ]);

      await AucorsaApi.persistSession(cookies);

      expect(cookies.stored.map((cookie) => cookie.name), [
        'aucorsa_session',
        'aucorsa_session',
      ]);
    });

    test('leaves cookies that already outlive the app alone', () async {
      final cookies = _FakeCookieManager([
        Cookie(
          name: 'wordpress_logged_in_abc',
          value: 'token',
          expiresDate: 1893456000000,
        ),
      ]);

      await AucorsaApi.persistSession(cookies);

      expect(cookies.stored, isEmpty);
    });

    test('stores cookies whose expiry the platform cannot report', () async {
      // Android only exposes the expiry on newer system web views, so an
      // unknown one has to be treated as session bound.
      final cookies = _FakeCookieManager([
        Cookie(name: 'aucorsa_custom_session', value: 'token'),
      ]);

      await AucorsaApi.persistSession(cookies);

      expect(cookies.stored, hasLength(2));
      expect(cookies.stored.first.expiresDate, isNotNull);
      // Only the WordPress pair is assumed HTTP only when unknown, so the
      // site's own scripts keep reading the cookies they own.
      expect(cookies.stored.first.isHttpOnly, isFalse);
    });

    test('keeps the flags the platform reported back', () async {
      final cookies = _FakeCookieManager([
        Cookie(
          name: 'aucorsa_session',
          value: 'token',
          isSessionOnly: true,
          path: '/mi-cuenta',
          domain: '.aucorsa.es',
          isSecure: true,
          isHttpOnly: false,
        ),
      ]);

      await AucorsaApi.persistSession(cookies);

      final stored = cookies.stored.first;
      expect(stored.path, '/mi-cuenta');
      expect(stored.domain, '.aucorsa.es');
      expect(stored.isSecure, isTrue);
      expect(stored.isHttpOnly, isFalse);
    });

    test('writes the jar to disk on the platform that needs it', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final cookies = _FakeCookieManager([
        Cookie(name: 'wordpress_logged_in_abc', value: 'token'),
      ]);

      await AucorsaApi.persistSession(cookies);

      expect(cookies.flushes, 1);
    });

    test('leaves the jar alone on a platform that persists it', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final cookies = _FakeCookieManager([
        Cookie(name: 'wordpress_logged_in_abc', value: 'token'),
      ]);

      await AucorsaApi.persistSession(cookies);

      expect(cookies.flushes, 0);
    });

    test('skips cookies that lost their value', () async {
      final cookies = _FakeCookieManager([
        Cookie(name: 'wordpress_logged_in_abc', value: ''),
        Cookie(name: 'wordpress_sec_abc'),
      ]);

      await AucorsaApi.persistSession(cookies);

      expect(cookies.stored, isEmpty);
    });
  });
}

/// Answers the index page with [body], recording every call made to it.
Dio _indexClient(List<RequestOptions> requests, String? body) =>
    Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<String>(
                requestOptions: options,
                statusCode: 200,
                data: body,
              ),
            );
          },
        ),
      );

class _FakeCookieManager implements CookieManager {
  final List<Cookie> _cookies;
  final List<Cookie> stored = [];
  int flushes = 0;

  _FakeCookieManager(this._cookies);

  @override
  Future<List<Cookie>> getCookies({
    required WebUri url,
    InAppWebViewController? iosBelow11WebViewController,
    InAppWebViewController? webViewController,
  }) async => _cookies;

  @override
  Future<bool> setCookie({
    required WebUri url,
    required String name,
    required String value,
    String path = '/',
    String? domain,
    int? expiresDate,
    int? maxAge,
    bool? isSecure,
    bool? isHttpOnly,
    HTTPCookieSameSitePolicy? sameSite,
    InAppWebViewController? iosBelow11WebViewController,
    InAppWebViewController? webViewController,
  }) async {
    stored.add(
      Cookie(
        name: name,
        value: value,
        path: path,
        domain: domain,
        expiresDate: expiresDate,
        isSecure: isSecure,
        isHttpOnly: isHttpOnly,
        sameSite: sameSite,
      ),
    );
    return true;
  }

  @override
  Future<void> flush() async => flushes++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
