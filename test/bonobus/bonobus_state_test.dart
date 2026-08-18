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
}
