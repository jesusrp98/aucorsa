import 'dart:convert';

import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_card_parser.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart';

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
  static const registerUrl = 'https://aucorsa.es/registro/';

  static const _apiUrl = 'https://aucorsa.es/wp-json/aucorsa/v1';
  static final _nonceRegex = RegExp(r'"ajax_nonce"\s*:\s*"([^"]+)"');
  static final _rootUri = WebUri(rootUrl);

  final Dio _client;
  final CookieManager _cookieManager;
  String? _nonce;

  AucorsaCardRepository({Dio? client, CookieManager? cookieManager})
    : _client =
          client ??
          Dio(
            BaseOptions(
              validateStatus: (status) => status != null && status < 500,
            ),
          ),
      _cookieManager = cookieManager ?? CookieManager.instance();

  Future<AucorsaCardsSnapshot> loadCards() async {
    final cookieHeader = await _requireCookieHeader();
    final pageResponse = await _client.get<String>(
      cardsUrl,
      options: _plainOptions(cookieHeader),
    );
    final pageHtml = pageResponse.data ?? '';
    final document = parse(pageHtml);
    final finalPath = pageResponse.realUri.path;

    if (finalPath.contains('/inicia-sesion') ||
        document.querySelector('a[href*="user_action=logout"]') == null) {
      throw const AucorsaSessionExpiredException();
    }

    _nonce = await _loadNonce(cookieHeader);
    final references = AucorsaCardParser.parseCardReferences(pageHtml);
    final cards = await Future.wait([
      for (final reference in references)
        _loadCard(reference, cookieHeader, _nonce!),
    ]);

    return AucorsaCardsSnapshot(cards: cards, updatedAt: DateTime.now());
  }

  Future<void> addCard(String cardNumber) async {
    final cookieHeader = await _requireCookieHeader();
    final nonce = await _loadNonce(cookieHeader);
    _nonce = nonce;
    final response = await _client.post<dynamic>(
      '$_apiUrl/endusers/registercard',
      data: Uri(
        queryParameters: {
          'card_number': cardNumber,
          'token': '1',
          '_wpnonce': nonce,
        },
      ).query,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: _headers(cookieHeader),
      ),
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AucorsaSessionExpiredException();
    }
    if (response.statusCode != 200) {
      throw AucorsaCardApiException(
        'AUCORSA add card request failed (${response.statusCode})',
      );
    }

    final body = _jsonObject(response.data);
    if (_hasApiError(body['error'])) {
      final message = body['error_msg']?.toString() ?? '';
      if (_isAuthenticationError(message)) {
        throw const AucorsaSessionExpiredException();
      }
      throw AucorsaCardApiException(
        message.isEmpty ? 'AUCORSA could not add the card' : message,
      );
    }
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

  Future<void> logout() async {
    final cookieHeader = await _cookieHeader();
    try {
      if (cookieHeader.isNotEmpty) {
        await _client.get<void>(
          '$rootUrl?user_action=logout',
          options: Options(headers: _headers(cookieHeader)),
        );
      }
    } finally {
      _nonce = null;
      await _cookieManager.deleteCookies(url: _rootUri);
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _cookieManager.flush();
      }
    }
  }

  Future<AucorsaCard> _loadCard(
    AucorsaCardReference reference,
    String cookieHeader,
    String nonce,
  ) async {
    final response = await _client.post<dynamic>(
      '$_apiUrl/ui/forms/card/showtitle',
      data: Uri(
        queryParameters: {
          'card_number': reference.number,
          'card_status': reference.status,
          '_wpnonce': nonce,
        },
      ).query,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: _headers(cookieHeader),
      ),
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AucorsaSessionExpiredException();
    }
    if (response.statusCode != 200) {
      throw AucorsaCardApiException(
        'AUCORSA card request failed (${response.statusCode})',
      );
    }
    final body = _jsonObject(response.data);
    if (_hasApiError(body['error'])) {
      final message = body['error_msg']?.toString() ?? '';
      if (_isAuthenticationError(message)) {
        throw const AucorsaSessionExpiredException();
      }
      throw AucorsaCardApiException(
        message.isEmpty ? 'AUCORSA error' : message,
      );
    }

    final content = body['content']?.toString();
    if (content == null || content.isEmpty) {
      throw const AucorsaCardApiException(
        'AUCORSA returned incomplete card details',
      );
    }
    return AucorsaCardParser.parseCard(content, reference);
  }

  Future<String> _loadNonce(String cookieHeader) async {
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
    final cookies = await _cookieManager.getCookies(url: _rootUri);
    final values = <String>[];
    for (final cookie in cookies) {
      final value = cookie.value;
      if (cookie.name.isNotEmpty && value is String && value.isNotEmpty) {
        values.add('${cookie.name}=$value');
      }
    }
    return values.join('; ');
  }

  Options _plainOptions(String cookieHeader) => Options(
    headers: _headers(cookieHeader),
    responseType: ResponseType.plain,
    followRedirects: true,
    maxRedirects: 5,
  );

  Map<String, String> _headers(String cookieHeader) => {
    'Cookie': cookieHeader,
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
