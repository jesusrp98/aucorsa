import 'dart:convert';

import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_card_parser.dart';
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

class AucorsaCardRepository {
  static const rootUrl = 'https://aucorsa.es/';
  static const cardsUrl = 'https://aucorsa.es/mis-tarjetas/';
  static const signInUrl =
      'https://aucorsa.es/inicia-sesion/?redirect_to=https%3A%2F%2Faucorsa.es%2Fmis-tarjetas%2F';
  static const _apiUrl = 'https://aucorsa.es/wp-json/aucorsa/v1';
  static const _accountOrigins = {
    'https://aucorsa.es',
    'https://www.aucorsa.es',
  };
  static final _nonceRegex = RegExp(r'"ajax_nonce"\s*:\s*"([^"]+)"');
  static final _rootUri = WebUri(rootUrl);
  static final _wwwRootUri = WebUri('https://www.aucorsa.es/');

  final Dio _client;
  CookieManager? _cookieManager;
  WebStorageManager? _webStorageManager;
  String? _nonce;
  String? _publicNonce;

  AucorsaCardRepository({
    Dio? client,
    CookieManager? cookieManager,
    WebStorageManager? webStorageManager,
  }) : _client =
           client ??
           Dio(
             BaseOptions(
               validateStatus: (status) => status != null && status < 500,
             ),
           ),
       _cookieManager = cookieManager,
       _webStorageManager = webStorageManager;

  CookieManager get _cookies => _cookieManager ??= CookieManager.instance();
  WebStorageManager get _webStorage =>
      _webStorageManager ??= WebStorageManager.instance();

  Future<void> clearAccountData() async {
    _nonce = null;
    _publicNonce = null;

    final webStorageCleanup = switch (defaultTargetPlatform) {
      TargetPlatform.android => [
        for (final origin in _accountOrigins)
          _webStorage.deleteOrigin(origin: origin),
      ],
      TargetPlatform.iOS || TargetPlatform.macOS => [
        _webStorage.removeDataModifiedSince(
          dataTypes: WebsiteDataType.ALL,
          date: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ],
      _ => <Future<void>>[],
    };
    final cookieResults = await Future.wait([
      _cookies.deleteCookies(url: _rootUri),
      _cookies.deleteCookies(url: _wwwRootUri),
    ]);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _cookies.flush();
    }
    if (cookieResults.any((deleted) => !deleted)) {
      throw const AucorsaCardApiException(
        'AUCORSA account data could not be removed',
      );
    }
    await Future.wait(webStorageCleanup);
  }

  Future<AucorsaCard> loadPublicCard(String cardNumber) async {
    final nonce = _publicNonce ?? await _loadNonce();
    _publicNonce = nonce;

    return _loadPublicCard(
      cardNumber: cardNumber,
      nonce: nonce,
      canRefreshNonce: true,
    );
  }

  Future<AucorsaCard> _loadPublicCard({
    required String cardNumber,
    required String nonce,
    required bool canRefreshNonce,
  }) async {
    final response = await _client.get<dynamic>(
      '$_apiUrl/ui/forms/recharge/secondary',
      queryParameters: {
        'card_number': cardNumber,
        'token': '1',
        'show_extra_content': '1',
        '_wpnonce': nonce,
      },
      options: Options(
        headers: _headers(),
        responseType: ResponseType.json,
      ),
    );

    final body = _jsonObject(response.data);
    final code = body['code']?.toString() ?? '';
    if (canRefreshNonce && code.contains('nonce')) {
      final freshNonce = await _loadNonce();
      _publicNonce = freshNonce;
      return _loadPublicCard(
        cardNumber: cardNumber,
        nonce: freshNonce,
        canRefreshNonce: false,
      );
    }
    if (response.statusCode != 200) {
      throw AucorsaCardApiException(
        'AUCORSA card request failed (${response.statusCode})',
      );
    }
    if (_hasApiError(body['error'])) {
      final message = body['error_msg']?.toString() ?? '';
      throw AucorsaCardApiException(
        message.isEmpty ? 'AUCORSA could not load the card' : message,
      );
    }

    final content = body['content']?.toString();
    if (content == null || content.isEmpty) {
      throw const AucorsaCardApiException(
        'AUCORSA returned incomplete card details',
      );
    }

    return AucorsaCardParser.parseCard(
      content,
      AucorsaCardReference(number: cardNumber, status: 'anonymous'),
    );
  }

  Future<AucorsaCardMovements> loadMovements({
    required String cardNumber,
    required int page,
  }) async {
    final cookieHeader = await _requireCookieHeader();
    final nonce = _nonce ?? await _loadNonce(cookieHeader);
    _nonce = nonce;

    return _loadMovements(
      cardNumber: cardNumber,
      page: page,
      cookieHeader: cookieHeader,
      nonce: nonce,
      canRefreshNonce: true,
    );
  }

  Future<AucorsaCardMovements> _loadMovements({
    required String cardNumber,
    required int page,
    required String cookieHeader,
    required String nonce,
    required bool canRefreshNonce,
  }) async {
    final response = await _client.get<dynamic>(
      '$_apiUrl/recharges/cardmovements',
      queryParameters: {
        'card_number': cardNumber,
        'page': page,
        '_wpnonce': nonce,
      },
      options: Options(
        headers: _headers(cookieHeader),
        responseType: ResponseType.json,
      ),
    );
    final data = response.data;
    if (data is Map) {
      final body = Map<String, dynamic>.from(data);
      final code = body['code']?.toString() ?? '';
      final message = body['message']?.toString() ?? '';
      if (canRefreshNonce && code.contains('nonce')) {
        final freshNonce = await _loadNonce(cookieHeader);
        _nonce = freshNonce;
        return _loadMovements(
          cardNumber: cardNumber,
          page: page,
          cookieHeader: cookieHeader,
          nonce: freshNonce,
          canRefreshNonce: false,
        );
      }
      if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          _isAuthenticationError(message)) {
        throw const AucorsaSessionExpiredException();
      }
      throw AucorsaCardApiException(
        message.isEmpty ? 'AUCORSA movements request failed' : message,
      );
    }

    final rawHtml = _stringResponse(data);
    if (_isAuthenticationError(rawHtml)) {
      throw const AucorsaSessionExpiredException();
    }
    if (response.statusCode != 200) {
      throw AucorsaCardApiException(
        'AUCORSA movements request failed (${response.statusCode})',
      );
    }

    return AucorsaCardParser.parseMovements(rawHtml);
  }

  Future<String> _loadNonce([String cookieHeader = '']) async {
    final response = await _client.get<String>(
      rootUrl,
      queryParameters: {'_': DateTime.now().millisecondsSinceEpoch},
      options: _plainOptions(cookieHeader),
    );
    final nonce = _nonceRegex.firstMatch(response.data ?? '')?.group(1);
    if (nonce == null) {
      throw const AucorsaSessionExpiredException();
    }
    return nonce;
  }

  Future<String> _requireCookieHeader() async {
    final value = await _cookieHeader();
    if (value.isEmpty) throw const AucorsaSessionExpiredException();
    return value;
  }

  Future<String> _cookieHeader() async {
    final cookies = await _cookies.getCookies(url: _rootUri);
    final values = <String>[];
    for (final cookie in cookies) {
      final value = cookie.value;
      if (cookie.name.isNotEmpty && value is String && value.isNotEmpty) {
        values.add('${cookie.name}=$value');
      }
    }
    return values.join('; ');
  }

  Options _plainOptions([String cookieHeader = '']) => Options(
    headers: _headers(cookieHeader),
    responseType: ResponseType.plain,
    followRedirects: true,
    maxRedirects: 5,
  );

  Map<String, String> _headers([String cookieHeader = '']) => {
    if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
    'Cache-Control': 'no-cache',
  };

  static Map<String, dynamic> _jsonObject(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw const AucorsaCardApiException('AUCORSA returned an invalid response');
  }

  static String _stringResponse(dynamic data) {
    if (data is String) return data;
    throw const AucorsaCardApiException('AUCORSA returned an invalid response');
  }

  static bool _isAuthenticationError(String data) {
    final value = data.toLowerCase();
    return value.contains('usuario no registrado') ||
        value.contains('no tiene permisos') ||
        value.contains('inicia sesi');
  }

  static bool _hasApiError(dynamic error) =>
      error == true ||
      (error is num && error != 0) ||
      (error is String && error.isNotEmpty && error != '0');

  void close() => _client.close(force: true);
}
