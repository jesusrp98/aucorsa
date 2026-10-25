import 'dart:async';

import 'package:aucorsa/common/cubits/bus_service_cubit.dart';
import 'package:aucorsa/common/cubits/bus_stop_cubit.dart';
import 'package:aucorsa/common/models/bus_stop_line_estimation.dart';
import 'package:aucorsa/common/utils/aucorsa_state_status.dart';
import 'package:flutter_test/flutter_test.dart';

class _Service implements BusServiceCubit {
  final requests = <Completer<List<BusStopLineEstimation>>>[];

  @override
  Future<List<BusStopLineEstimation>> requestBusStopData(int stopId) {
    final request = Completer<List<BusStopLineEstimation>>();
    requests.add(request);
    return request.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const estimates = [
    BusStopLineEstimation(lineId: '3', estimations: [Duration(minutes: 5)]),
  ];

  testWidgets('refreshes every 30 seconds without hiding successful data', (
    tester,
  ) async {
    final service = _Service();
    final cubit = BusStopCubit(busServiceCubit: service, stopId: 105);
    final initial = cubit.fetchEstimations();
    service.requests.single.complete(estimates);
    await initial;
    cubit
      ..setAutoRefresh(enabled: true)
      ..setAutoRefresh(enabled: true);
    await tester.pump(const Duration(seconds: 29));
    expect(service.requests, hasLength(1));
    await tester.pump(const Duration(seconds: 1));
    expect(service.requests, hasLength(2));
    expect(cubit.state.status, AucorsaStateStatus.success);
    expect(cubit.state.estimations, estimates);
    service.requests.last.complete(estimates);
    await tester.pump();
    cubit.setAutoRefresh(enabled: false);
    await tester.pump(const Duration(seconds: 60));
    expect(service.requests, hasLength(2));
    await cubit.close();
  });

  test(
    'coalesces requests and safely ignores results after disposal',
    () async {
      final service = _Service();
      final cubit = BusStopCubit(busServiceCubit: service, stopId: 105);
      final first = cubit.fetchEstimations();
      final second = cubit.fetchEstimations();
      expect(identical(first, second), isTrue);
      expect(service.requests, hasLength(1));
      await cubit.close();
      service.requests.single.complete(estimates);
      await first;
      await second;
    },
  );

  test(
    'a failed refresh preserves estimates and their original timestamp',
    () async {
      final service = _Service();
      final cubit = BusStopCubit(busServiceCubit: service, stopId: 105);
      final initial = cubit.fetchEstimations();
      service.requests.single.complete(estimates);
      await initial;
      final timestamp = cubit.state.fetchedAt;
      final refresh = cubit.fetchEstimations(silent: true);
      service.requests.last.completeError(StateError('API unavailable'));
      await refresh;
      expect(cubit.state.status, AucorsaStateStatus.error);
      expect(cubit.state.estimations, estimates);
      expect(cubit.state.fetchedAt, timestamp);
      final recovery = cubit.fetchEstimations(silent: true);
      service.requests.last.complete([]);
      await recovery;
      expect(cubit.state.status, AucorsaStateStatus.success);
      expect(cubit.state.estimations, isEmpty);
      await cubit.close();
    },
  );

  testWidgets('closing the cubit cancels its polling timer', (tester) async {
    final service = _Service();
    final cubit = BusStopCubit(busServiceCubit: service, stopId: 105)
      ..setAutoRefresh(enabled: true);
    await cubit.close();
    await tester.pump(const Duration(minutes: 1));
    expect(service.requests, isEmpty);
  });
}
