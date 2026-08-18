import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/repositories/aucorsa_card_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

typedef AucorsaMovementsLoader =
    Future<AucorsaCardMovements> Function({
      required String cardNumber,
      required int page,
    });

enum AucorsaMovementsStatus {
  initial,
  loading,
  loaded,
  unauthenticated,
  failure,
}

class AucorsaMovementsState extends Equatable {
  final AucorsaMovementsStatus status;
  final List<AucorsaCardMovement> movements;
  final int nextPage;
  final bool hasReachedMax;
  final bool refreshing;
  final String? error;

  const AucorsaMovementsState({
    this.status = AucorsaMovementsStatus.initial,
    this.movements = const [],
    this.nextPage = 1,
    this.hasReachedMax = false,
    this.refreshing = false,
    this.error,
  });

  factory AucorsaMovementsState.fromJson(Map<String, dynamic> json) {
    final movements = [
      for (final movement in json['movements'] as List<dynamic>? ?? [])
        AucorsaCardMovement.fromJson(
          Map<String, dynamic>.from(movement as Map),
        ),
    ];

    return AucorsaMovementsState(
      status: movements.isEmpty
          ? AucorsaMovementsStatus.initial
          : AucorsaMovementsStatus.loaded,
      movements: movements,
      nextPage: json['nextPage'] as int? ?? 1,
      hasReachedMax: json['hasReachedMax'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movements': [for (final movement in movements) movement.toJson()],
      'nextPage': nextPage,
      'hasReachedMax': hasReachedMax,
    };
  }

  @override
  List<Object?> get props => [
    status,
    movements,
    nextPage,
    hasReachedMax,
    refreshing,
    error,
  ];
}

class AucorsaMovementsCubit extends HydratedCubit<AucorsaMovementsState> {
  final AucorsaMovementsLoader loadMovements;
  final String cardNumber;

  AucorsaMovementsCubit({
    required this.loadMovements,
    required this.cardNumber,
  }) : super(const AucorsaMovementsState());

  static String storageKey(String cardNumber) =>
      'AucorsaMovementsCubit$cardNumber';

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
      final result = await loadMovements(
        cardNumber: cardNumber,
        page: page,
      );
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
    } catch (error) {
      if (isClosed) return;
      emit(
        AucorsaMovementsState(
          status: AucorsaMovementsStatus.failure,
          movements: state.movements,
          nextPage: page,
          hasReachedMax: state.hasReachedMax,
          error: error.toString(),
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
      final result = await loadMovements(cardNumber: cardNumber, page: 1);
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
    } catch (error) {
      if (isClosed) return;
      emit(
        AucorsaMovementsState(
          status: AucorsaMovementsStatus.failure,
          movements: cached,
          nextPage: state.nextPage,
          hasReachedMax: state.hasReachedMax,
          error: error.toString(),
        ),
      );
    }
  }

  @override
  AucorsaMovementsState? fromJson(Map<String, dynamic> json) =>
      AucorsaMovementsState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(AucorsaMovementsState state) => state.toJson();

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
