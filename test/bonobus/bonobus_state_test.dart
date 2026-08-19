import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores a locally stored AUCORSA card and balance', () {
    final state = BonobusState.fromJson({
      'status': BonobusStatus.loaded.index,
      'provider': BonobusProvider.aucorsa.index,
      'id': '1234567890',
      'balance': '12.34 €',
      'name': 'Tarjeta Ordinaria',
      'lastUpdated': '2026-08-12T09:30:00.000',
    });

    expect(state.status, BonobusStatus.loaded);
    expect(state.provider, BonobusProvider.aucorsa);
    expect(state.id, '1234567890');
    expect(state.balance, '12.34 €');
    expect(state.name, 'Tarjeta Ordinaria');
    expect(state.lastUpdated, DateTime(2026, 8, 12, 9, 30));
  });

  test('survives a round trip through storage unchanged', () {
    final state = BonobusState(
      status: BonobusStatus.loaded,
      provider: BonobusProvider.consorcio,
      id: '1234567890',
      balance: '8.87 €',
      name: 'Tarjeta Ordinaria',
      lastUpdated: DateTime(2026, 8, 12, 9, 30),
    );

    expect(BonobusState.fromJson(state.toJson()), state);
  });

  test('never carries an error over to the next session', () {
    const state = BonobusState(
      status: BonobusStatus.loaded,
      provider: BonobusProvider.aucorsa,
      id: '1234567890',
      error: 'Tarjeta no encontrada',
    );

    expect(state.toJson().containsKey('error'), isFalse);
    expect(BonobusState.fromJson(state.toJson()).error, isNull);
  });

  test('restores a bonobus that was never loaded', () {
    final state = BonobusState.fromJson(const BonobusState().toJson());

    expect(state, const BonobusState());
    expect(state.provider, isNull);
    expect(state.lastUpdated, isNull);
  });

  test('copyWith keeps everything it was not asked to change', () {
    final state = BonobusState(
      status: BonobusStatus.loaded,
      provider: BonobusProvider.aucorsa,
      id: '1234567890',
      balance: '8.87 €',
      name: 'Tarjeta Ordinaria',
      lastUpdated: DateTime(2026, 8, 12, 9, 30),
    );

    expect(state.copyWith(balance: '9.99 €').name, 'Tarjeta Ordinaria');
    expect(state.copyWith(balance: '9.99 €').balance, '9.99 €');
  });

  test('copyWith drops the error only when told to', () {
    const state = BonobusState(error: 'Tarjeta no encontrada');

    expect(state.copyWith(status: BonobusStatus.loading).error, isNotNull);
    expect(state.copyWith(clearError: true).error, isNull);
  });
}
