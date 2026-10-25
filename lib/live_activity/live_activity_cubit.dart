import 'dart:async';

import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LiveActivityState {
  const new({
    this.supported = false,
    this.enabled = false,
    this.busy = false,
    this.stopID,
    this.lineID,
    this.stopName,
  });

  factory fromMap(Map<dynamic, dynamic> value) => LiveActivityState(
    supported: value['supported'] == true,
    enabled: value['enabled'] == true,
    stopID: value['stopID'] as int?,
    lineID: value['lineID'] as String?,
    stopName: value['stopName'] as String?,
  );

  final bool supported;
  final bool enabled;
  final bool busy;
  final int? stopID;
  final String? lineID;
  final String? stopName;

  bool get isFollowing => stopID != null && lineID != null;

  LiveActivityState withBusy(bool value) => LiveActivityState(
    supported: supported,
    enabled: enabled,
    busy: value,
    stopID: stopID,
    lineID: lineID,
    stopName: stopName,
  );
}

enum LiveActivityFailure { disabled, failed }

/// Native ActivityKit owns the session and polling, even when its Flutter
/// screen is gone. This cubit only synchronizes controls with native state.
class LiveActivityCubit extends Cubit<LiveActivityState>
    with WidgetsBindingObserver {
  new({MethodChannel? channel, BusStopCustomDataCubit? customData})
    : _customData = customData,
      _channel =
          channel ?? const MethodChannel('com.chechu.aucorsa/live_activity'),
      super(const LiveActivityState()) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    _connected = true;
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed' && !isClosed) {
        emit(
          LiveActivityState.fromMap(call.arguments as Map<dynamic, dynamic>)
              .withBusy(state.busy),
        );
        unawaited(_synchronizeStopName());
      }
    });
    _customDataSubscription = customData?.stream.listen(
      (_) => unawaited(_synchronizeStopName()),
    );
    unawaited(refreshStatus());
  }

  final MethodChannel _channel;
  final BusStopCustomDataCubit? _customData;
  StreamSubscription<BusStopCustomNameState>? _customDataSubscription;
  var _connected = false;
  var _syncingName = false;
  var _operationVersion = 0;

  Future<void> refreshStatus() async {
    if (!_connected || isClosed || state.busy) return;
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>('status');
      if (!isClosed && !state.busy && result != null) {
        emit(LiveActivityState.fromMap(result));
        await _synchronizeStopName();
      }
    } on MissingPluginException {
      // Other platforms and older iOS versions do not show the controls.
    } on PlatformException {
      // Preserve a known active session if the bridge is temporarily busy.
    }
  }

  String _displayName(int stopID) {
    final name = _customData?.get(stopID)?.name;
    return (name == null || name.isEmpty
            ? BusStopUtils.resolveName(stopID)
            : name)
        .characters
        .take(80)
        .toString();
  }

  Future<void> _synchronizeStopName() async {
    if (!_connected || _customData == null || _syncingName || isClosed) return;
    _syncingName = true;
    try {
      while (!isClosed && !state.busy && state.isFollowing) {
        final stopID = state.stopID!;
        final lineID = state.lineID!;
        final name = _displayName(stopID);
        if (state.stopName == name) break;
        final version = _operationVersion;
        final result = await _channel.invokeMapMethod<dynamic, dynamic>(
          'updateStopName',
          {'stopID': stopID, 'lineID': lineID, 'stopName': name},
        );
        if (isClosed || state.busy) break;
        if (version != _operationVersion) continue;
        if (state.stopID != stopID || state.lineID != lineID) continue;
        if (result == null) break;
        emit(LiveActivityState.fromMap(result));
        // A second edit made during the native update is applied next.
        // Do not retry an unchanged name indefinitely if native rejects it.
        if (_displayName(stopID) == name) break;
      }
    } on MissingPluginException {
      // An older native build may not support live renaming yet.
    } on PlatformException {
      // Retry on the next edit or app resume, preserving the active session.
    } finally {
      _syncingName = false;
    }
  }

  Future<LiveActivityFailure?> start({
    required int stopID,
    required String lineID,
    required String stopName,
    required String language,
  }) => _perform('start', {
    'stopID': stopID,
    'lineID': lineID,
    'stopName': stopName,
    'language': language,
  });

  Future<LiveActivityFailure?> stop() => _perform('stop');

  Future<LiveActivityFailure?> _perform(
    String method, [
    Map<String, Object>? arguments,
  ]) async {
    if (!_connected || isClosed || state.busy) {
      return LiveActivityFailure.failed;
    }
    _operationVersion++;
    emit(state.withBusy(true));
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(
        method,
        arguments,
      );
      if (!isClosed && result != null) emit(LiveActivityState.fromMap(result));
      return null;
    } on PlatformException catch (error) {
      return error.code == 'disabled'
          ? LiveActivityFailure.disabled
          : LiveActivityFailure.failed;
    } on MissingPluginException {
      return LiveActivityFailure.failed;
    } finally {
      if (!isClosed) {
        emit(state.withBusy(false));
        unawaited(_synchronizeStopName());
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refreshStatus());
  }

  @override
  Future<void> close() async {
    await _customDataSubscription?.cancel();
    if (_connected) {
      WidgetsBinding.instance.removeObserver(this);
      _channel.setMethodCallHandler(null);
    }
    await super.close();
  }
}
