import 'dart:async';

import 'package:aucorsa/bonobus/cubits/aucorsa_movements_cubit.dart';
import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  late _MemoryStorage storage;

  setUp(() {
    storage = _MemoryStorage();
    HydratedBloc.storage = storage;
  });

  group('AucorsaMovementsCubit', () {
    test('appends pages and stops after reaching the last page', () async {
      final repository = _FakeAucorsaCardRepository((page) async {
        return switch (page) {
          1 => _page([_movement('First')], hasNextPage: true),
          2 => _page([_movement('Second')]),
          _ => throw StateError('Unexpected page $page'),
        };
      });
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadMore();
      await cubit.loadMore();
      await cubit.loadMore();

      expect(repository.requestedPages, [1, 2]);
      expect(
        cubit.state.movements.map((movement) => movement.operation),
        ['First', 'Second'],
      );
      expect(cubit.state.hasReachedMax, isTrue);
      expect(cubit.state.nextPage, 3);
    });

    test('does not start concurrent page requests', () async {
      final response = Completer<AucorsaCardMovements>();
      final repository = _FakeAucorsaCardRepository((_) => response.future);
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      final firstRequest = cubit.loadMore();
      await cubit.loadMore();

      expect(repository.requestedPages, [1]);

      response.complete(_page([_movement('First')]));
      await firstRequest;
    });

    test('keeps loaded movements and retries the same failed page', () async {
      var pageTwoAttempts = 0;
      final repository = _FakeAucorsaCardRepository((page) async {
        if (page == 1) {
          return _page([_movement('First')], hasNextPage: true);
        }
        pageTwoAttempts++;
        if (pageTwoAttempts == 1) throw StateError('Temporary failure');
        return _page([_movement('Second')]);
      });
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadMore();
      await cubit.loadMore();

      expect(cubit.state.status, AucorsaMovementsStatus.failure);
      expect(cubit.state.nextPage, 2);
      expect(cubit.state.movements, [_movement('First')]);

      await cubit.loadMore();

      expect(repository.requestedPages, [1, 2, 2]);
      expect(cubit.state.status, AucorsaMovementsStatus.loaded);
      expect(cubit.state.movements, [
        _movement('First'),
        _movement('Second'),
      ]);
    });

    test('refresh replaces the history when pages no longer overlap', () async {
      var pageOneLoads = 0;
      final repository = _FakeAucorsaCardRepository((page) async {
        if (page == 1) {
          pageOneLoads++;
          return _page(
            [_movement(pageOneLoads == 1 ? 'Old first' : 'Fresh first')],
            hasNextPage: true,
          );
        }
        return _page([_movement('Old second')]);
      });
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadMore();
      await cubit.loadMore();
      await cubit.refresh();

      expect(repository.requestedPages, [1, 2, 1]);
      expect(cubit.state.movements, [_movement('Fresh first')]);
      expect(cubit.state.nextPage, 2);
      expect(cubit.state.hasReachedMax, isFalse);
    });

    test(
      'refresh keeps the stored history and prepends new movements',
      () async {
        var pageOneLoads = 0;
        final repository = _FakeAucorsaCardRepository((page) async {
          if (page == 1) {
            pageOneLoads++;
            return _page(
              [
                if (pageOneLoads > 1) _movement('Brand new'),
                _movement('First'),
              ],
              hasNextPage: true,
            );
          }
          return _page([_movement('Second')]);
        });
        final cubit = _buildCubit(repository);
        addTearDown(cubit.close);

        await cubit.loadMore();
        await cubit.loadMore();
        await cubit.refresh();

        expect(
          cubit.state.movements.map((movement) => movement.operation),
          ['Brand new', 'First', 'Second'],
        );
        expect(cubit.state.nextPage, 3);
        expect(cubit.state.hasReachedMax, isTrue);
      },
    );

    test('refresh keeps the stored movements visible while loading', () async {
      final response = Completer<AucorsaCardMovements>();
      var pageOneLoads = 0;
      final repository = _FakeAucorsaCardRepository((_) {
        pageOneLoads++;
        if (pageOneLoads == 1) return Future.value(_page([_movement('First')]));
        return response.future;
      });
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadMore();
      final refreshing = cubit.refresh();

      expect(cubit.state.refreshing, isTrue);
      expect(cubit.state.movements, [_movement('First')]);

      response.complete(_page([_movement('First')]));
      await refreshing;

      expect(cubit.state.refreshing, isFalse);
      expect(cubit.state.movements, [_movement('First')]);
    });

    test('refresh keeps the stored movements when it fails', () async {
      var pageOneLoads = 0;
      final repository = _FakeAucorsaCardRepository((_) async {
        pageOneLoads++;
        if (pageOneLoads == 1) return _page([_movement('First')]);
        throw StateError('Temporary failure');
      });
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadMore();
      await cubit.refresh();

      expect(cubit.state.status, AucorsaMovementsStatus.failure);
      expect(cubit.state.refreshing, isFalse);
      expect(cubit.state.movements, [_movement('First')]);
    });

    test('stores downloaded movements and restores them on creation', () async {
      final repository = _FakeAucorsaCardRepository((page) async {
        return switch (page) {
          1 => _page([_movement('First')], hasNextPage: true),
          _ => _page([_movement('Second')]),
        };
      });
      final cubit = _buildCubit(repository);
      await cubit.loadMore();
      await cubit.loadMore();
      await cubit.close();

      final restored = _buildCubit(repository);
      addTearDown(restored.close);

      expect(storage.read(AucorsaMovementsCubit.storageKey('123')), isNotNull);
      expect(restored.state.status, AucorsaMovementsStatus.loaded);
      expect(restored.state.movements, [
        _movement('First'),
        _movement('Second'),
      ]);
      expect(restored.state.nextPage, 3);
      expect(restored.state.hasReachedMax, isTrue);
    });
  });
}

AucorsaMovementsCubit _buildCubit(_FakeAucorsaCardRepository repository) {
  return AucorsaMovementsCubit(
    loadMovements: repository.loadMovements,
    cardNumber: '123',
  );
}

AucorsaCardMovements _page(
  List<AucorsaCardMovement> movements, {
  bool hasNextPage = false,
}) {
  return AucorsaCardMovements(
    movements: movements,
    hasPreviousPage: false,
    hasNextPage: hasNextPage,
  );
}

AucorsaCardMovement _movement(String operation) {
  return AucorsaCardMovement(
    date: '19/07/2026',
    time: '12:00',
    operation: operation,
    amount: '-0.72 €',
  );
}

class _FakeAucorsaCardRepository {
  final Future<AucorsaCardMovements> Function(int page) onLoad;
  final List<int> requestedPages = [];

  _FakeAucorsaCardRepository(this.onLoad);

  Future<AucorsaCardMovements> loadMovements({
    required String cardNumber,
    required int page,
  }) {
    requestedPages.add(page);
    return onLoad(page);
  }
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
