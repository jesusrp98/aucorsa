import 'package:aucorsa/bonobus/cubits/aucorsa_movements_cubit.dart';
import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores the history and where it left off', () {
    final state = AucorsaMovementsState.fromJson(const {
      'movements': [
        {
          'date': '19/07/2026',
          'time': '12:00',
          'operation': 'Validación bus',
          'amount': '-0.72 €',
          'activation': null,
        },
      ],
      'nextPage': 3,
      'hasReachedMax': true,
    });

    expect(state.status, AucorsaMovementsStatus.loaded);
    expect(state.movements.single.operation, 'Validación bus');
    expect(state.nextPage, 3);
    expect(state.hasReachedMax, isTrue);
  });

  test('survives a round trip through storage unchanged', () {
    const state = AucorsaMovementsState(
      status: AucorsaMovementsStatus.loaded,
      movements: [
        AucorsaCardMovement(
          date: '19/07/2026',
          time: '12:00',
          operation: 'Recarga online',
          amount: '10,00 €',
          activation: AucorsaRechargeActivation.pending,
        ),
      ],
      nextPage: 2,
      hasReachedMax: true,
    );

    expect(AucorsaMovementsState.fromJson(state.toJson()), state);
  });

  test('comes back ready to load when nothing was stored', () {
    final state = AucorsaMovementsState.fromJson(const {});

    expect(state.status, AucorsaMovementsStatus.initial);
    expect(state.movements, isEmpty);
    expect(state.nextPage, 1);
    expect(state.hasReachedMax, isFalse);
  });

  test('never carries a transient flag over to the next session', () {
    const state = AucorsaMovementsState(
      status: AucorsaMovementsStatus.failure,
      refreshing: true,
    );

    final json = state.toJson();

    expect(json.containsKey('refreshing'), isFalse);
    expect(json.containsKey('status'), isFalse);
    expect(AucorsaMovementsState.fromJson(json).refreshing, isFalse);
  });

  test('reads back the activation state of a stored top-up', () {
    const movement = AucorsaCardMovement(
      date: '19/07/2026',
      time: '12:00',
      operation: 'Recarga online',
      amount: '10,00 €',
      activation: AucorsaRechargeActivation.activated,
    );

    expect(AucorsaCardMovement.fromJson(movement.toJson()), movement);
  });
}
