import 'dart:async';

import 'package:aucorsa/bonobus/cubits/aucorsa_movements_cubit.dart';
import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

    test('refresh replaces previously loaded pages with page one', () async {
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
