import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AucorsaSessionExpiredException implements Exception {
  const AucorsaSessionExpiredException();
}

class AucorsaCardApiException implements Exception {
  final String message;

  const AucorsaCardApiException(this.message);

  @override
  String toString() => message;
}

/// Endpoints and stateless helpers shared by the AUCORSA account requests.
///
/// The cubits own the requests themselves, their nonce caches and their error
/// handling; this only holds the pieces both of them need to talk to the site.
class AucorsaApi {
  static const rootUrl = 'https://aucorsa.es/';
  static const signInUrl =
      'https://aucorsa.es/inicia-sesion/?redirect_to=https%3A%2F%2Faucorsa.es%2Fmis-tarjetas%2F';
  static const apiUrl = 'https://aucorsa.es/wp-json/aucorsa/v1';
  static const accountOrigins = {
    'https://aucorsa.es',
    'https://www.aucorsa.es',
  };

  /// How long a stored session is kept, matching the WordPress "remember me"
  /// window the site does not offer on its form.
  static const sessionLifetime = Duration(days: 14);

  static final nonceRegex = RegExp(r'"ajax_nonce"\s*:\s*"([^"]+)"');
  static final rootUri = WebUri(rootUrl);
  static final wwwRootUri = WebUri('https://www.aucorsa.es/');

  const AucorsaApi._();

  /// Reads the nonce the site publishes in plain text on its index page.
  ///
  /// Passing a [cookieHeader] returns the nonce bound to that session, which is
  /// the one the authenticated endpoints expect.
  static Future<String> loadNonce(
    Dio client, [
    String cookieHeader = '',
  ]) async {
    final response = await client.get<String>(
      rootUrl,
      queryParameters: {'_': DateTime.now().millisecondsSinceEpoch},
      options: Options(
        headers: headers(cookieHeader),
        responseType: ResponseType.plain,
        followRedirects: true,
        maxRedirects: 5,
      ),
    );
    final nonce = nonceRegex.firstMatch(response.data ?? '')?.group(1);
    if (nonce == null) throw const AucorsaSessionExpiredException();

    return nonce;
  }

  /// Joins the stored account cookies into a single `Cookie` header value.
  ///
  /// Returns an empty string when the user has not signed in yet.
  static Future<String> cookieHeader(CookieManager cookies) async {
    final stored = await cookies.getCookies(url: rootUri);
    final values = <String>[];
    for (final cookie in stored) {
      final value = cookie.value;
      if (cookie.name.isNotEmpty && value is String && value.isNotEmpty) {
        values.add('${cookie.name}=$value');
      }
    }

    return values.join('; ');
  }

  /// Keeps the signed-in session across app restarts.
  ///
  /// The AUCORSA form has no "remember me" box, so WordPress hands out session
  /// cookies, which every platform drops once the app process ends. Storing
  /// them again with an explicit expiry moves them to disk, so a returning
  /// user reaches their movements without signing in again.
  ///
  /// The site still decides how long it honours the session: once it rejects
  /// the stored cookies the request fails with an
  /// [AucorsaSessionExpiredException] and the user is asked to sign in again.
  static Future<void> persistSession(CookieManager cookies) async {
    final expiresDate = DateTime.now()
        .add(sessionLifetime)
        .millisecondsSinceEpoch;

    for (final uri in [rootUri, wwwRootUri]) {
      for (final cookie in await cookies.getCookies(url: uri)) {
        final value = cookie.value;
        if (value is! String || value.isEmpty) continue;
        if (!_isSessionOnly(cookie)) continue;

        await cookies.setCookie(
          url: uri,
          name: cookie.name,
          value: value,
          path: cookie.path ?? '/',
          domain: cookie.domain,
          expiresDate: expiresDate,
          isSecure: cookie.isSecure,
          // Android cannot always read the flag back, and WordPress always
          // marks its authentication cookies as HTTP only, so keep them so.
          isHttpOnly: cookie.isHttpOnly ?? _isWordPressAuth(cookie.name),
          sameSite: cookie.sameSite,
        );
      }
    }

    // Android only writes its cookie store to disk when asked to.
    if (defaultTargetPlatform == TargetPlatform.android) await cookies.flush();
  }

  /// Whether [cookie] would be lost when the app closes.
  ///
  /// Android only reports an expiry when the system web view supports it, so
  /// an unknown one is treated as session bound rather than assumed safe.
  static bool _isSessionOnly(Cookie cookie) =>
      (cookie.isSessionOnly ?? false) || cookie.expiresDate == null;

  /// The cookies WordPress uses to keep a user signed in, which it always
  /// marks HTTP only. Used when the platform cannot report the flag back.
  static bool _isWordPressAuth(String name) => name.startsWith('wordpress_');

  static Map<String, String> headers([String cookieHeader = '']) => {
    if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
    'Cache-Control': 'no-cache',
  };

  static Map<String, dynamic> jsonObject(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw const AucorsaCardApiException('AUCORSA returned an invalid response');
  }

  static String stringResponse(dynamic data) {
    if (data is String) return data;
    throw const AucorsaCardApiException('AUCORSA returned an invalid response');
  }

  static bool isAuthenticationError(String data) {
    final value = data.toLowerCase();
    return value.contains('usuario no registrado') ||
        value.contains('no tiene permisos') ||
        value.contains('inicia sesi');
  }

  static bool hasApiError(dynamic error) =>
      error == true ||
      (error is num && error != 0) ||
      (error is String && error.isNotEmpty && error != '0');
}
