import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  test('updateId keeps the provider and drops the previous card data', () {
    HydratedBloc.storage = _MemoryStorage();

    final cubit = BonobusCubit()
      ..set(provider: BonobusProvider.aucorsa, id: '0546174400')
      ..loaded(balance: '8.87 €', name: 'Tarjeta Estudiante');
    addTearDown(cubit.close);

    cubit.updateId('1234567890');

    expect(cubit.state.provider, BonobusProvider.aucorsa);
    expect(cubit.state.id, '1234567890');
    expect(cubit.state.status, BonobusStatus.initial);
    expect(cubit.state.balance, isNull);
    expect(cubit.state.name, isNull);
    expect(cubit.state.lastUpdated, isNull);
  });
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
