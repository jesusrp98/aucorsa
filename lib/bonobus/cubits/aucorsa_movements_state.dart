part of 'aucorsa_movements_cubit.dart';

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
