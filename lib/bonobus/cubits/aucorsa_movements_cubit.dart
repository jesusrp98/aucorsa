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

part 'aucorsa_movements_state.dart';

/// Downloads and stores the movement history of a single AUCORSA card.
///
/// The endpoint is only reachable with the cookies the user got by signing in
/// on the AUCORSA site, so every request starts by collecting them.
class AucorsaMovementsCubit extends HydratedCubit<AucorsaMovementsState> {
  final String cardNumber;

  final Dio _client;
  CookieManager? _cookieManager;
  String? _nonce;

  AucorsaMovementsCubit({
    required this.cardNumber,
    Dio? client,
    CookieManager? cookieManager,
  }) : _client = client ?? httpClient,
       _cookieManager = cookieManager,
       super(const AucorsaMovementsState());

  static String storageKey(String cardNumber) =>
      'AucorsaMovementsCubit$cardNumber';

  CookieManager get _cookies => _cookieManager ??= CookieManager.instance();

  @override
  String get id => cardNumber;

  Future<void> loadMore() async {
    if (state.status == AucorsaMovementsStatus.loading ||
        state.refreshing ||
        state.hasReachedMax) {
      return;
    }

    final page = state.nextPage;
    emit(
      AucorsaMovementsState(
        status: AucorsaMovementsStatus.loading,
        movements: state.movements,
        nextPage: page,
        hasReachedMax: state.hasReachedMax,
      ),
    );

    try {
      final result = await _loadMovements(page);
      if (isClosed) return;
      emit(
        AucorsaMovementsState(
          status: AucorsaMovementsStatus.loaded,
          movements: [...state.movements, ...result.movements],
          nextPage: page + 1,
          hasReachedMax: !result.hasNextPage,
        ),
      );
    } on AucorsaSessionExpiredException {
      if (isClosed) return;
      emit(
        AucorsaMovementsState(
          status: AucorsaMovementsStatus.unauthenticated,
          movements: state.movements,
          nextPage: page,
          hasReachedMax: state.hasReachedMax,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        AucorsaMovementsState(
          status: AucorsaMovementsStatus.failure,
          movements: state.movements,
          nextPage: page,
          hasReachedMax: state.hasReachedMax,
        ),
      );
    }
  }

  /// Loads the first page again while keeping the stored movements visible.
  ///
  /// New movements are prepended to the ones already downloaded, so the
  /// history the user scrolled through survives a refresh.
  Future<void> refresh() async {
    if (state.status == AucorsaMovementsStatus.loading || state.refreshing) {
      return;
    }

    final cached = state.movements;
    emit(
      AucorsaMovementsState(
        status: cached.isEmpty
            ? AucorsaMovementsStatus.initial
            : AucorsaMovementsStatus.loaded,
        movements: cached,
        nextPage: state.nextPage,
        hasReachedMax: state.hasReachedMax,
        refreshing: true,
      ),
    );

    try {
      final result = await _loadMovements(1);
      if (isClosed) return;
      final merged = _mergeWithCache(result.movements, cached);
      emit(
        merged == null
            ? AucorsaMovementsState(
                status: AucorsaMovementsStatus.loaded,
                movements: result.movements,
                nextPage: 2,
                hasReachedMax: !result.hasNextPage,
              )
            : AucorsaMovementsState(
                status: AucorsaMovementsStatus.loaded,
                movements: merged,
                nextPage: state.nextPage > 1 ? state.nextPage : 2,
                hasReachedMax: state.hasReachedMax,
              ),
      );
    } on AucorsaSessionExpiredException {
      if (isClosed) return;
      emit(
        AucorsaMovementsState(
          status: AucorsaMovementsStatus.unauthenticated,
          movements: cached,
          nextPage: state.nextPage,
          hasReachedMax: state.hasReachedMax,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        AucorsaMovementsState(
          status: AucorsaMovementsStatus.failure,
          movements: cached,
          nextPage: state.nextPage,
          hasReachedMax: state.hasReachedMax,
        ),
      );
    }
  }

  @override
  AucorsaMovementsState? fromJson(Map<String, dynamic> json) =>
      AucorsaMovementsState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(AucorsaMovementsState state) => state.toJson();

  Future<AucorsaCardMovements> _loadMovements(int page) async {
    try {
      final cookieHeader = await _sessionCookies();
      final nonce = _nonce ??= await AucorsaApi.loadNonce(
        _client,
        cookieHeader,
      );

      return await _requestMovements(
        page: page,
        cookieHeader: cookieHeader,
        nonce: nonce,
        canRefreshNonce: true,
      );
    } on AucorsaSessionExpiredException {
      // Whatever we were holding is no longer worth offering back.
      await AucorsaSession.clear();
      rethrow;
    }
  }

  /// The cookies that prove the user is signed in.
  ///
  /// The web view jar wins while it still holds them, and every time it does
  /// the header is copied to [AucorsaSession]. That copy is what answers here
  /// after a restart, when the jar comes back empty.
  Future<String> _sessionCookies() async {
    final live = await AucorsaApi.cookieHeader(_cookies);
    if (live.isNotEmpty) {
      await AucorsaSession.save(live);
      _log('using the web view cookies', live);

      return live;
    }

    final stored = AucorsaSession.read();
    _log('web view jar empty, falling back to the stored session', stored);
    if (stored.isEmpty) throw const AucorsaSessionExpiredException();

    return stored;
  }

  /// Names the cookies at hand, so a failing sign-in can be told apart from a
  /// rejected one. Never logs the values, which are the credentials.
  void _log(String message, String cookieHeader) {
    if (!kDebugMode) return;

    final names = cookieHeader.isEmpty
        ? const <String>[]
        : [
            for (final cookie in cookieHeader.split('; '))
              cookie.split('=').first,
          ];
    debugPrint('[aucorsa] $message: $names');
  }

  Future<AucorsaCardMovements> _requestMovements({
    required int page,
    required String cookieHeader,
    required String nonce,
    required bool canRefreshNonce,
  }) async {
    final response = await _client.get<dynamic>(
      '${AucorsaApi.apiUrl}/recharges/cardmovements',
      queryParameters: {
        'card_number': cardNumber,
        'page': page,
        '_wpnonce': nonce,
      },
      options: Options(
        headers: AucorsaApi.headers(cookieHeader),
        responseType: ResponseType.json,
      ),
    );

    // A JSON object always means a rejected request: the successful response is
    // the HTML fragment holding the movements table.
    final data = response.data;
    if (data is Map) {
      final body = Map<String, dynamic>.from(data);
      final code = body['code']?.toString() ?? '';
      final message = body['message']?.toString() ?? '';
      if (canRefreshNonce && code.contains('nonce')) {
        final freshNonce = await AucorsaApi.loadNonce(_client, cookieHeader);
        _nonce = freshNonce;
        return _requestMovements(
          page: page,
          cookieHeader: cookieHeader,
          nonce: freshNonce,
          canRefreshNonce: false,
        );
      }
      if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          AucorsaApi.isAuthenticationError(message)) {
        throw const AucorsaSessionExpiredException();
      }
      throw AucorsaCardApiException(
        message.isEmpty ? 'AUCORSA movements request failed' : message,
      );
    }

    final rawHtml = AucorsaApi.stringResponse(data);
    if (AucorsaApi.isAuthenticationError(rawHtml)) {
      throw const AucorsaSessionExpiredException();
    }
    if (response.statusCode != 200) {
      throw AucorsaCardApiException(
        'AUCORSA movements request failed (${response.statusCode})',
      );
    }

    return AucorsaCardParser.parseMovements(rawHtml);
  }

  /// Prepends the movements of [fresh] that the [cached] history is missing.
  ///
  /// Returns `null` when both lists do not overlap, meaning the stored history
  /// cannot be joined with the fresh page without leaving a gap in between.
  static List<AucorsaCardMovement>? _mergeWithCache(
    List<AucorsaCardMovement> fresh,
    List<AucorsaCardMovement> cached,
  ) {
    if (cached.isEmpty) return null;

    for (var newCount = 0; newCount < fresh.length; newCount++) {
      final overlap = fresh.length - newCount;
      if (overlap > cached.length) continue;
      var matches = true;
      for (var index = 0; index < overlap && matches; index++) {
        matches = fresh[newCount + index] == cached[index];
      }
      if (matches) return [...fresh.take(newCount), ...cached];
    }

    return null;
  }
}
