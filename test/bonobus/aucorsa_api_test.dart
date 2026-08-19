import 'package:aucorsa/bonobus/utils/aucorsa_api.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

class _FakeCookieManager implements CookieManager {
  final List<Cookie> _cookies;
  final List<Cookie> stored = [];

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
  Future<void> flush() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
