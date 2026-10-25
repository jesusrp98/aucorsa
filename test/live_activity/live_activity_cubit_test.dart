import 'dart:async';

import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/live_activity/live_activity_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class _MemoryStorage implements Storage {
  final _values = <String, dynamic>{};
  @override
  dynamic read(String key) => _values[key];
  @override
  Future<void> write(String key, dynamic value) async => _values[key] = value;
  @override
  Future<void> delete(String key) async => _values.remove(key);
  @override
  Future<void> clear() async => _values.clear();
  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.chechu.aucorsa/live_activity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    HydratedBloc.storage = _MemoryStorage();
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'restored sessions use custom names and follow edits and resets',
    () async {
      final customData = BusStopCustomDataCubit()
        ..set(stopId: 105, name: 'Casa');
      final updates = <String>[];
      var name = BusStopUtils.resolveName(105);
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'updateStopName') {
          final arguments = call.arguments as Map;
          expect(arguments['stopID'], 105);
          expect(arguments['lineID'], '2');
          name = arguments['stopName'] as String;
          updates.add(name);
        } else {
          expect(call.method, 'status');
        }
        return {
          'supported': true,
          'enabled': true,
          'stopID': 105,
          'lineID': '2',
          'stopName': name,
        };
      });
      final cubit = LiveActivityCubit(customData: customData);
      await pumpEventQueue();
      expect(cubit.state.stopName, 'Casa');

      customData.set(stopId: 141, name: 'Other stop');
      await pumpEventQueue();
      expect(updates, ['Casa']);
      customData.set(stopId: 105, name: 'Trabajo 🚌');
      await pumpEventQueue();
      expect(cubit.state.stopName, 'Trabajo 🚌');
      customData.set(stopId: 105, name: '');
      await pumpEventQueue();
      expect(cubit.state.stopName, BusStopUtils.resolveName(105));
      expect(updates, ['Casa', 'Trabajo 🚌', BusStopUtils.resolveName(105)]);
      await cubit.close();
      await customData.close();
    },
  );

  test('edits during a pending name update apply the latest name', () async {
    final customData = BusStopCustomDataCubit()..set(stopId: 105, name: 'Casa');
    final pending = Completer<void>();
    final updates = <String>[];
    var name = 'Casa';
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'updateStopName') {
        name = (call.arguments as Map)['stopName'] as String;
        updates.add(name);
        if (updates.length == 1) await pending.future;
      }
      return {
        'supported': true,
        'enabled': true,
        'stopID': 105,
        'lineID': '2',
        'stopName': name,
      };
    });
    final cubit = LiveActivityCubit(customData: customData);
    await pumpEventQueue();
    customData.set(stopId: 105, name: 'Trabajo');
    await pumpEventQueue();
    customData.set(stopId: 105, name: 'Gimnasio');
    await pumpEventQueue();
    pending.complete();
    await pumpEventQueue();
    expect(updates, ['Trabajo', 'Gimnasio']);
    expect(cubit.state.stopName, 'Gimnasio');
    await cubit.close();
    await customData.close();
  });

  test('a late name response cannot restore a stopped session', () async {
    final customData = BusStopCustomDataCubit()..set(stopId: 105, name: 'Casa');
    final pending = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'stop') return {'supported': true, 'enabled': true};
      if (call.method == 'updateStopName') await pending.future;
      return {
        'supported': true,
        'enabled': true,
        'stopID': 105,
        'lineID': '2',
        'stopName': call.method == 'status' ? 'Casa' : 'Trabajo',
      };
    });
    final cubit = LiveActivityCubit(customData: customData);
    await pumpEventQueue();
    customData.set(stopId: 105, name: 'Trabajo');
    await pumpEventQueue();
    await cubit.stop();
    pending.complete();
    await pumpEventQueue();
    expect(cubit.state.isFollowing, isFalse);
    await cubit.close();
    await customData.close();
  });

  test(
    'restores native tracking and sends complete start parameters',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return {
          'supported': true,
          'enabled': true,
          if (call.method != 'stop') 'stopID': 105,
          if (call.method != 'stop') 'lineID': '2',
          if (call.method != 'stop') 'stopName': 'Casa',
        };
      });
      final cubit = LiveActivityCubit();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.stopID, 105);
      expect(cubit.state.stopName, 'Casa');
      expect(cubit.state.isFollowing, isTrue);
      expect(
        await cubit.start(
          stopID: 105,
          lineID: '2',
          stopName: 'Casa',
          language: 'es',
        ),
        isNull,
      );
      expect(calls.last.arguments, {
        'stopID': 105,
        'lineID': '2',
        'stopName': 'Casa',
        'language': 'es',
      });
      expect(cubit.state.busy, isFalse);
      expect(await cubit.stop(), isNull);
      expect(cubit.state.stopID, isNull);
      expect(cubit.state.stopName, isNull);
      expect(cubit.state.isFollowing, isFalse);
      await cubit.close();
    },
  );

  test('disabled permissions are reported and busy state is cleared', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'start') throw PlatformException(code: 'disabled');
      return {'supported': true, 'enabled': false};
    });
    final cubit = LiveActivityCubit();
    await Future<void>.delayed(Duration.zero);
    expect(
      await cubit.start(
        stopID: 105,
        lineID: '2',
        stopName: 'Casa',
        language: 'es',
      ),
      LiveActivityFailure.disabled,
    );
    expect(cubit.state.busy, isFalse);
    await cubit.close();
  });

  test('duplicate starts cannot race native activity creation', () async {
    final pending = Completer<Map<String, Object>>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'start') return await pending.future;
      return {'supported': true, 'enabled': true};
    });
    final cubit = LiveActivityCubit();
    await Future<void>.delayed(Duration.zero);
    final first = cubit.start(
      stopID: 105,
      lineID: '2',
      stopName: 'Casa',
      language: 'es',
    );
    expect(
      await cubit.start(
        stopID: 105,
        lineID: '1',
        stopName: 'Casa',
        language: 'es',
      ),
      LiveActivityFailure.failed,
    );
    pending.complete({
      'supported': true,
      'enabled': true,
      'stopID': 105,
      'lineID': '2',
    });
    await first;
    expect(cubit.state.lineID, '2');
    await cubit.close();
  });

  test('Android never calls the iOS bridge', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      return null;
    });
    final cubit = LiveActivityCubit();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.supported, isFalse);
    expect(calls, 0);
    await cubit.close();
  });

  test(
    'missing native support stays hidden without breaking the app',
    () async {
      final cubit = LiveActivityCubit();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.supported, isFalse);
      await cubit.close();
    },
  );
}
