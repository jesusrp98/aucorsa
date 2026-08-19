import 'package:aucorsa/bonobus/cubits/aucorsa_movements_cubit.dart';
import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_api.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_card_parser.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_session.dart';
import 'package:aucorsa/common/utils/http_client.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'bonobus_state.dart';

/// Holds the bonobus the user added, whoever issued it.
///
/// Every provider stores the same details, but they are filled in different
/// ways: AUCORSA cards are looked up on the website by their number, while
/// Consorcio cards are read over NFC by the scan controller.
class BonobusCubit extends HydratedCubit<BonobusState> {
  static const _legacyCardsStorageKey = 'AucorsaCardsCubit';

  final Dio _client;
  CookieManager? _cookieManager;
  WebStorageManager? _webStorageManager;
  String? _nonce;

  BonobusCubit({
    Dio? client,
    CookieManager? cookieManager,
    WebStorageManager? webStorageManager,
  }) : _client = client ?? httpClient,
       _cookieManager = cookieManager,
       _webStorageManager = webStorageManager,
       super(const BonobusState());

  CookieManager get _cookies => _cookieManager ??= CookieManager.instance();
  WebStorageManager get _webStorage =>
      _webStorageManager ??= WebStorageManager.instance();

  /// Stores the bonobus the user just picked, before any details are known.
  void selectProvider(BonobusProvider provider, {String? id}) =>
      emit(state.copyWith(provider: provider, id: id));

  /// Stores the details an NFC read produced, in a single update.
  void scanned({String? id, String? balance}) => emit(
    state.copyWith(
      id: id,
      balance: balance,
      status: BonobusStatus.loaded,
      lastUpdated: DateTime.now(),
    ),
  );

  /// Reloads the details of the stored bonobus from its provider.
  ///
  /// Consorcio cards carry their balance on the card itself, so there is
  /// nothing to fetch for them until the user scans again.
  Future<void> refresh() async {
    final cardNumber = state.id;
    if (cardNumber == null) return;

    switch (state.provider) {
      case BonobusProvider.aucorsa:
        await _refreshAucorsa(cardNumber);
      case BonobusProvider.consorcio:
      case null:
        return;
    }
  }

  /// Replaces the card [id] of the current provider, dropping everything
  /// cached for the previous card, and loads the new one.
  Future<void> updateId(String id) async {
    final provider = state.provider;
    final previousId = state.id;
    emit(BonobusState(provider: provider, id: id));

    // The movements of the previous card are stored under its own key, which
    // nothing reaches once the card number is gone.
    if (provider == BonobusProvider.aucorsa &&
        previousId != null &&
        previousId != id) {
      await HydratedBloc.storage.delete(
        AucorsaMovementsCubit.storageKey(previousId),
      );
    }

    return refresh();
  }

  /// Forgets the stored bonobus, along with any account data it left behind.
  Future<void> delete() async {
    if (state.provider == BonobusProvider.aucorsa) {
      await _clearAucorsaAccountData(state.id);
    }

    emit(const BonobusState());
  }

  /// Drops the last error once the UI has shown it.
  ///
  /// Without this, two identical failures in a row compare equal and the
  /// second one would never reach a listener.
  void clearError() {
    if (state.error == null) return;

    emit(state.copyWith(clearError: true));
  }

  @override
  BonobusState? fromJson(Map<String, dynamic> json) =>
      BonobusState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(BonobusState state) => state.toJson();

  Future<void> _refreshAucorsa(String cardNumber) async {
    emit(state.copyWith(status: BonobusStatus.loading, clearError: true));

    try {
      final nonce = _nonce ??= await AucorsaApi.loadNonce(_client);
      final card = await _requestCard(
        cardNumber: cardNumber,
        nonce: nonce,
        canRefreshNonce: true,
      );
      // The user may have edited or removed the card while it was loading.
      if (isClosed || state.id != cardNumber) return;
      emit(
        state.copyWith(
          status: BonobusStatus.loaded,
          balance: card.balance,
          name: card.title,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (error) {
      if (isClosed || state.id != cardNumber) return;
      // Stay on [BonobusStatus.loaded] so the cached details remain on screen.
      emit(
        state.copyWith(
          status: BonobusStatus.loaded,
          error: error is AucorsaCardApiException ? error.message : '',
        ),
      );
    }
  }

  Future<AucorsaCard> _requestCard({
    required String cardNumber,
    required String nonce,
    required bool canRefreshNonce,
  }) async {
    final response = await _client.get<dynamic>(
      '${AucorsaApi.apiUrl}/ui/forms/recharge/secondary',
      queryParameters: {
        'card_number': cardNumber,
        'token': '1',
        'show_extra_content': '1',
        '_wpnonce': nonce,
      },
      options: Options(
        headers: AucorsaApi.headers(),
        responseType: ResponseType.json,
      ),
    );

    final Map<String, dynamic> body;
    try {
      body = AucorsaApi.jsonObject(response.data);
    } on AucorsaCardApiException {
      // A body that is not JSON at all is the server's own error page, and its
      // status says more about what went wrong than the body does.
      if (response.statusCode != 200) {
        throw AucorsaCardApiException(
          'AUCORSA card request failed (${response.statusCode})',
        );
      }
      rethrow;
    }

    final code = body['code']?.toString() ?? '';
    if (canRefreshNonce && code.contains('nonce')) {
      final freshNonce = await AucorsaApi.loadNonce(_client);
      _nonce = freshNonce;
      return _requestCard(
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
    if (AucorsaApi.hasApiError(body['error'])) {
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

    return AucorsaCardParser.parseCard(content);
  }

  /// Signs the user out of the AUCORSA site and drops everything cached for
  /// the card, so a new one starts from a clean session.
  Future<void> _clearAucorsaAccountData(String? cardNumber) async {
    _nonce = null;

    final storage = HydratedBloc.storage;
    final webStorageCleanup = switch (defaultTargetPlatform) {
      TargetPlatform.android => [
        for (final origin in AucorsaApi.accountOrigins)
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
      _cookies.deleteCookies(url: AucorsaApi.rootUri),
      _cookies.deleteCookies(url: AucorsaApi.wwwRootUri),
    ]);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _cookies.flush();
    }
    if (cookieResults.any((deleted) => !deleted)) {
      throw const AucorsaCardApiException(
        'AUCORSA account data could not be removed',
      );
    }

    await Future.wait([
      ...webStorageCleanup,
      AucorsaSession.clear(storage),
      storage.delete(_legacyCardsStorageKey),
      if (cardNumber != null)
        storage.delete(AucorsaMovementsCubit.storageKey(cardNumber)),
    ]);
  }
}
