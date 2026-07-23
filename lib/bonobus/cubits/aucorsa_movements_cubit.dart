import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/repositories/aucorsa_card_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final String? error;

  const AucorsaMovementsState({
    this.status = AucorsaMovementsStatus.initial,
    this.movements = const [],
    this.nextPage = 1,
    this.hasReachedMax = false,
    this.error,
  });

  @override
  List<Object?> get props => [
    status,
    movements,
    nextPage,
    hasReachedMax,
    error,
  ];
}

class AucorsaMovementsCubit extends Cubit<AucorsaMovementsState> {
  final AucorsaMovementsLoader loadMovements;
  final String cardNumber;

  AucorsaMovementsCubit({
    required this.loadMovements,
    required this.cardNumber,
  }) : super(const AucorsaMovementsState());

  Future<void> loadMore() async {
    if (state.status == AucorsaMovementsStatus.loading || state.hasReachedMax) {
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

  Future<void> refresh() async {
    if (state.status == AucorsaMovementsStatus.loading) return;
    emit(const AucorsaMovementsState());
    await loadMore();
  }
}
