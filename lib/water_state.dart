import 'dart:convert';
import 'dart:math';

import 'package:waterdays/app_localizations.dart';

class WaterHistoryRecord {
  const WaterHistoryRecord({required this.goalCups, required this.drankCups});

  final int goalCups;
  final int drankCups;

  bool get metGoal => drankCups >= goalCups;

  Map<String, dynamic> toJson() {
    return {'goalCups': goalCups, 'drankCups': drankCups};
  }

  factory WaterHistoryRecord.fromJson(Map<String, dynamic> json) {
    return WaterHistoryRecord(
      goalCups:
          (json['goalCups'] as num?)?.toInt() ?? AppConfig.defaultGoalCups,
      drankCups: (json['drankCups'] as num?)?.toInt() ?? 0,
    );
  }
}

class WaterTrackerState {
  const WaterTrackerState({
    required this.hasStartedTracking,
    required this.goalCups,
    required this.filledCupIndices,
    required this.currentDateKey,
    required this.history,
  });

  final bool hasStartedTracking;
  final int goalCups;
  final List<int> filledCupIndices;
  final String currentDateKey;
  final Map<String, WaterHistoryRecord> history;

  static WaterTrackerState initial([DateTime? now]) {
    final today = dateKeyFromDate(now ?? DateTime.now());
    return WaterTrackerState(
      hasStartedTracking: false,
      goalCups: AppConfig.defaultGoalCups,
      filledCupIndices: const [],
      currentDateKey: today,
      history: const {},
    );
  }

  int get drankCups => filledCupIndices.length;

  bool get isGoalComplete => drankCups >= goalCups;

  int get remainingCups => max(goalCups - drankCups, 0);

  List<bool> get cupStates {
    final filledSet = filledCupIndices.toSet();
    return List<bool>.generate(goalCups, filledSet.contains);
  }

  double get progress {
    if (goalCups <= 0) {
      return 0;
    }
    return drankCups / goalCups;
  }

  WaterTrackerState copyWith({
    bool? hasStartedTracking,
    int? goalCups,
    List<int>? filledCupIndices,
    String? currentDateKey,
    Map<String, WaterHistoryRecord>? history,
  }) {
    final nextGoalCups = goalCups ?? this.goalCups;
    return WaterTrackerState(
      hasStartedTracking: hasStartedTracking ?? this.hasStartedTracking,
      goalCups: nextGoalCups,
      filledCupIndices: _normalizeFilledCupIndices(
        filledCupIndices ?? this.filledCupIndices,
        nextGoalCups,
      ),
      currentDateKey: currentDateKey ?? this.currentDateKey,
      history: history ?? this.history,
    );
  }

  WaterTrackerState startTracking(int nextGoalCups, {DateTime? now}) {
    return copyWith(
      hasStartedTracking: true,
      goalCups: nextGoalCups.clamp(1, AppConfig.maxGoalCups),
      filledCupIndices: const [],
      currentDateKey: dateKeyFromDate(now ?? DateTime.now()),
    );
  }

  WaterTrackerState updateGoal(int nextGoalCups, {DateTime? now}) {
    final clampedGoal = nextGoalCups.clamp(1, AppConfig.maxGoalCups);
    return copyWith(
      hasStartedTracking: true,
      goalCups: clampedGoal,
      filledCupIndices: _resizeFilledCupIndices(
        filledCupIndices,
        clampedGoal,
        drankCups.clamp(0, clampedGoal),
      ),
      currentDateKey: dateKeyFromDate(now ?? DateTime.now()),
    );
  }

  WaterTrackerState incrementCup() {
    if (drankCups >= goalCups) {
      return this;
    }

    final filledSet = filledCupIndices.toSet();
    for (var index = 0; index < goalCups; index++) {
      if (!filledSet.contains(index)) {
        final nextFilledCupIndices = [...filledCupIndices, index]..sort();
        return copyWith(filledCupIndices: nextFilledCupIndices);
      }
    }

    return this;
  }

  WaterTrackerState decrementCup() {
    if (filledCupIndices.isEmpty) {
      return this;
    }

    final lastFilledIndex = filledCupIndices.last;
    final nextFilledCupIndices =
        filledCupIndices.where((index) => index != lastFilledIndex).toList();
    return copyWith(filledCupIndices: nextFilledCupIndices);
  }

  WaterTrackerState toggleCup(int index) {
    if (index < 0 || index >= goalCups) {
      return this;
    }

    final filledSet = filledCupIndices.toSet();
    if (filledSet.remove(index)) {
      return copyWith(filledCupIndices: filledSet.toList()..sort());
    }

    filledSet.add(index);
    return copyWith(filledCupIndices: filledSet.toList()..sort());
  }

  WaterTrackerState normalizeForDate(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = dateKeyFromDate(today);

    if (!hasStartedTracking) {
      return copyWith(currentDateKey: todayKey);
    }

    final storedDate = dateFromKey(currentDateKey);
    if (storedDate == null) {
      return copyWith(currentDateKey: todayKey);
    }

    final normalizedStoredDate = DateTime(
      storedDate.year,
      storedDate.month,
      storedDate.day,
    );

    if (normalizedStoredDate.isAtSameMomentAs(today)) {
      return copyWith(currentDateKey: todayKey);
    }

    if (normalizedStoredDate.isAfter(today)) {
      return copyWith(currentDateKey: todayKey);
    }

    final nextHistory = Map<String, WaterHistoryRecord>.from(history);
    var cursor = normalizedStoredDate;
    var isFirstArchivedDay = true;

    while (cursor.isBefore(today)) {
      final key = dateKeyFromDate(cursor);
      nextHistory[key] = WaterHistoryRecord(
        goalCups: goalCups,
        drankCups: isFirstArchivedDay ? drankCups : 0,
      );
      cursor = cursor.add(const Duration(days: 1));
      isFirstArchivedDay = false;
    }

    return copyWith(
      currentDateKey: todayKey,
      filledCupIndices: const [],
      history: nextHistory,
    );
  }

  WaterHistoryRecord? recordForDate(DateTime date) {
    final key = dateKeyFromDate(date);
    if (hasStartedTracking && key == currentDateKey) {
      return WaterHistoryRecord(goalCups: goalCups, drankCups: drankCups);
    }
    return history[key];
  }

  Map<String, Object> toStorageMap() {
    final sortedEntries =
        history.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final encodedHistory = <String, dynamic>{};
    for (final entry in sortedEntries) {
      encodedHistory[entry.key] = entry.value.toJson();
    }
    final historyJson = jsonEncode(encodedHistory);

    return {
      'hasStartedTracking': hasStartedTracking,
      'goalCups': goalCups,
      'drankCups': drankCups,
      'filledCupIndicesJson': jsonEncode(filledCupIndices),
      'currentDateKey': currentDateKey,
      'historyJson': historyJson,
    };
  }

  factory WaterTrackerState.fromStorageMap(Map<String, Object?> map) {
    final rawHistoryJson = map['historyJson'] as String?;
    final history = <String, WaterHistoryRecord>{};

    if (rawHistoryJson != null && rawHistoryJson.isNotEmpty) {
      final decoded = jsonDecode(rawHistoryJson);
      if (decoded is Map<String, dynamic>) {
        for (final entry in decoded.entries) {
          if (entry.value is Map<String, dynamic>) {
            history[entry.key] = WaterHistoryRecord.fromJson(
              entry.value as Map<String, dynamic>,
            );
          } else if (entry.value is Map) {
            history[entry.key] = WaterHistoryRecord.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            );
          }
        }
      }
    }

    final initial = WaterTrackerState.initial();
    final goalCups = ((map['goalCups'] as num?)?.toInt() ?? initial.goalCups)
        .clamp(1, AppConfig.maxGoalCups);
    final drankCups = ((map['drankCups'] as num?)?.toInt() ?? initial.drankCups)
        .clamp(0, goalCups);
    final filledCupIndices = _filledCupIndicesFromStorage(
      map['filledCupIndicesJson'] as String?,
      goalCups,
      drankCups,
    );
    return WaterTrackerState(
      hasStartedTracking:
          map['hasStartedTracking'] as bool? ?? initial.hasStartedTracking,
      goalCups: goalCups,
      filledCupIndices: filledCupIndices,
      currentDateKey:
          map['currentDateKey'] as String? ?? initial.currentDateKey,
      history: history,
    );
  }
}

List<int> _normalizeFilledCupIndices(Iterable<int> indices, int goalCups) {
  final normalized =
      indices.where((index) => index >= 0 && index < goalCups).toSet().toList()
        ..sort();
  return normalized;
}

List<int> _resizeFilledCupIndices(
  Iterable<int> currentIndices,
  int goalCups,
  int targetFilledCount,
) {
  final normalized = _normalizeFilledCupIndices(currentIndices, goalCups);
  final resized = normalized.take(targetFilledCount).toList(growable: true);
  final filledSet = resized.toSet();

  for (
    var index = 0;
    index < goalCups && resized.length < targetFilledCount;
    index++
  ) {
    if (filledSet.add(index)) {
      resized.add(index);
    }
  }

  resized.sort();
  return resized;
}

List<int> _filledCupIndicesFromStorage(
  String? rawFilledCupIndicesJson,
  int goalCups,
  int fallbackDrankCups,
) {
  if (rawFilledCupIndicesJson == null || rawFilledCupIndicesJson.isEmpty) {
    return List<int>.generate(fallbackDrankCups, (index) => index);
  }

  try {
    final decoded = jsonDecode(rawFilledCupIndicesJson);
    if (decoded is List) {
      return _normalizeFilledCupIndices(
        decoded.whereType<num>().map((value) => value.toInt()),
        goalCups,
      );
    }
  } on FormatException {
    // Fall back to the old contiguous cup model for corrupted data.
  }

  return List<int>.generate(fallbackDrankCups, (index) => index);
}

String dateKeyFromDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime? dateFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) {
    return null;
  }

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }

  return DateTime(year, month, day);
}
