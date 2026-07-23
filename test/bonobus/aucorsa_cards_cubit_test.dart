import 'dart:async';

import 'package:aucorsa/bonobus/cubits/aucorsa_cards_cubit.dart';
import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/repositories/aucorsa_card_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  const card = AucorsaCard(
    number: '12345678',
    status: 'registered',
    title: 'Tarjeta Estudiante',
    description: 'Bonobús estudiante',
    balance: '8.87 €',
    canRecharge: true,
  );
  final updatedAt = DateTime(2026, 7, 19, 21, 31);

  test(
    'restores the last card balance and update time while reloading',
    () async {
      final storage = _MemoryStorage();
      final loadedCubit = AucorsaCardsCubit(
        _FakeRepository(
          loadCards: () async => AucorsaCardsSnapshot(
            cards: const [card],
            updatedAt: updatedAt,
          ),
        ),
        storage: storage,
      );

      await loadedCubit.load();
      await loadedCubit.close();

      final nextLoad = Completer<AucorsaCardsSnapshot>();
      final restoredCubit = AucorsaCardsCubit(
        _FakeRepository(loadCards: () => nextLoad.future),
        storage: storage,
      );

      expect(restoredCubit.state.cards, const [card]);
      expect(restoredCubit.state.updatedAt, updatedAt);

      final load = restoredCubit.load();

      expect(restoredCubit.state.status, AucorsaCardsStatus.loading);
      expect(restoredCubit.state.cards.single.balance, '8.87 €');
      expect(restoredCubit.state.updatedAt, updatedAt);

      nextLoad.complete(
        AucorsaCardsSnapshot(cards: const [card], updatedAt: updatedAt),
      );
      await load;
      await restoredCubit.close();
    },
  );
}

class _FakeRepository implements AucorsaCardRepository {
  final Future<AucorsaCardsSnapshot> Function() _loadCards;

  const _FakeRepository({
    required Future<AucorsaCardsSnapshot> Function() loadCards,
  }) : _loadCards = loadCards;

  @override
  Future<AucorsaCardsSnapshot> loadCards() => _loadCards();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryStorage implements Storage {
  final Map<String, dynamic> _values = {};

  @override
  dynamic read(String key) => _values[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async => _values.clear();

  @override
  Future<void> close() async {}
}
