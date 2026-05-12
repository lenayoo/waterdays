import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterdays/app_localizations.dart';
import 'package:waterdays/water_state.dart';

abstract class WaterStateStore {
  Future<WaterTrackerState> load();

  Future<void> save(WaterTrackerState state);

  Future<String?> consumeLaunchAction();
}

class SharedPrefsWaterStateStore implements WaterStateStore {
  SharedPrefsWaterStateStore({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(AppConfig.channelName);

  final MethodChannel _channel;

  @override
  Future<WaterTrackerState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return WaterTrackerState.fromStorageMap({
      'hasStartedTracking': prefs.getBool(_Keys.hasStartedTracking),
      'goalCups': prefs.getInt(_Keys.goalCups),
      'drankCups': prefs.getInt(_Keys.drankCups),
      'filledCupIndicesJson': prefs.getString(_Keys.filledCupIndicesJson),
      'currentDateKey': prefs.getString(_Keys.currentDateKey),
      'historyJson': prefs.getString(_Keys.historyJson),
    });
  }

  @override
  Future<void> save(WaterTrackerState state) async {
    final prefs = await SharedPreferences.getInstance();
    final data = state.toStorageMap();

    await prefs.setBool(
      _Keys.hasStartedTracking,
      data['hasStartedTracking']! as bool,
    );
    await prefs.setInt(_Keys.goalCups, data['goalCups']! as int);
    await prefs.setInt(_Keys.drankCups, data['drankCups']! as int);
    await prefs.setString(
      _Keys.filledCupIndicesJson,
      data['filledCupIndicesJson']! as String,
    );
    await prefs.setString(
      _Keys.currentDateKey,
      data['currentDateKey']! as String,
    );
    await prefs.setString(_Keys.historyJson, data['historyJson']! as String);

    try {
      await _channel.invokeMethod<void>('updateWaterProgress', {
        'drankCups': state.drankCups,
        'goalCups': state.goalCups,
        'currentDateKey': state.currentDateKey,
      });
    } on PlatformException {
      // Widget sync is optional on unsupported platforms.
    } on MissingPluginException {
      // Widget sync is optional in tests and desktop builds.
    }
  }

  @override
  Future<String?> consumeLaunchAction() async {
    try {
      return await _channel.invokeMethod<String>('consumeLaunchAction');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

class MemoryWaterStateStore implements WaterStateStore {
  MemoryWaterStateStore([WaterTrackerState? initialState])
    : _state = initialState ?? WaterTrackerState.initial();

  WaterTrackerState _state;
  String? pendingLaunchAction;

  @override
  Future<WaterTrackerState> load() async {
    return _state;
  }

  @override
  Future<void> save(WaterTrackerState state) async {
    _state = state;
  }

  @override
  Future<String?> consumeLaunchAction() async {
    final action = pendingLaunchAction;
    pendingLaunchAction = null;
    return action;
  }
}

class LaunchActions {
  const LaunchActions._();

  static const quickAdd = 'quick_add';
}

class _Keys {
  const _Keys._();

  static const hasStartedTracking = 'waterdays.hasStartedTracking';
  static const goalCups = 'waterdays.goalCups';
  static const drankCups = 'waterdays.drankCups';
  static const filledCupIndicesJson = 'waterdays.filledCupIndicesJson';
  static const currentDateKey = 'waterdays.currentDateKey';
  static const historyJson = 'waterdays.historyJson';
}
