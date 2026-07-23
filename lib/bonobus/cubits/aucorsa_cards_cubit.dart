import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/repositories/aucorsa_card_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

enum AucorsaCardsStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

class AucorsaCardsState extends Equatable {
  final AucorsaCardsStatus status;
  final List<AucorsaCard> cards;
  final DateTime? updatedAt;
  final String? error;

  const AucorsaCardsState({
    this.status = AucorsaCardsStatus.initial,
    this.cards = const [],
    this.updatedAt,
    this.error,
  });

  factory AucorsaCardsState.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'];
    if (rawCards is! List) return const AucorsaCardsState();

    return AucorsaCardsState(
      status: AucorsaCardsStatus.authenticated,
      cards: rawCards
          .map(
            (card) => AucorsaCard.fromJson(
              Map<String, dynamic>.from(card as Map),
            ),
          )
          .toList(growable: false),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'cards': cards.map((card) => card.toJson()).toList(growable: false),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [status, cards, updatedAt, error];
}

class AucorsaCardsCubit extends HydratedCubit<AucorsaCardsState> {
  final AucorsaCardRepository repository;

  AucorsaCardsCubit(this.repository, {Storage? storage})
    : super(const AucorsaCardsState(), storage: storage);

  @override
  String get storagePrefix => 'AucorsaCardsCubit';

  Future<void> load() async {
    emit(
      AucorsaCardsState(
        status: AucorsaCardsStatus.loading,
        cards: state.cards,
        updatedAt: state.updatedAt,
      ),
    );

    try {
      final snapshot = await repository.loadCards();
      if (isClosed) return;
      emit(
        AucorsaCardsState(
          status: AucorsaCardsStatus.authenticated,
          cards: snapshot.cards,
          updatedAt: snapshot.updatedAt,
        ),
      );
    } on AucorsaSessionExpiredException {
      if (isClosed) return;
      emit(
        const AucorsaCardsState(
          status: AucorsaCardsStatus.unauthenticated,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        AucorsaCardsState(
          status: AucorsaCardsStatus.failure,
          cards: state.cards,
          updatedAt: state.updatedAt,
          error: error.toString(),
        ),
      );
    }
  }

  Future<bool> addCard(String cardNumber) async {
    emit(
      AucorsaCardsState(
        status: AucorsaCardsStatus.loading,
        cards: state.cards,
        updatedAt: state.updatedAt,
      ),
    );

    try {
      await repository.addCard(cardNumber);
      if (isClosed) return false;
      await load();
      return state.status == AucorsaCardsStatus.authenticated;
    } on AucorsaSessionExpiredException {
      if (isClosed) return false;
      emit(
        const AucorsaCardsState(
          status: AucorsaCardsStatus.unauthenticated,
        ),
      );
      return false;
    } catch (error) {
      if (isClosed) return false;
      emit(
        AucorsaCardsState(
          status: AucorsaCardsStatus.failure,
          cards: state.cards,
          updatedAt: state.updatedAt,
          error: error.toString(),
        ),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await repository.logout();
    if (isClosed) return;
    emit(
      const AucorsaCardsState(status: AucorsaCardsStatus.unauthenticated),
    );
  }

  @override
  AucorsaCardsState? fromJson(Map<String, dynamic> json) {
    try {
      return AucorsaCardsState.fromJson(json);
    } on Object {
      return null;
    }
  }

  @override
  Map<String, dynamic> toJson(AucorsaCardsState state) => state.toJson();
}
