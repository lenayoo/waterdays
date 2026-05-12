import 'package:flutter_test/flutter_test.dart';
import 'package:waterdays/water_state.dart';

void main() {
  test('daily reset archives the previous day and clears today count', () {
    final state = WaterTrackerState.initial(DateTime(2026, 5, 12)).copyWith(
      hasStartedTracking: true,
      goalCups: 8,
      drankCups: 5,
      currentDateKey: '2026-05-12',
    );

    final nextState = state.normalizeForDate(DateTime(2026, 5, 13, 8));

    expect(nextState.currentDateKey, '2026-05-13');
    expect(nextState.drankCups, 0);
    expect(nextState.history['2026-05-12']?.drankCups, 5);
    expect(nextState.history['2026-05-12']?.goalCups, 8);
  });

  test('daily reset fills skipped days as incomplete history', () {
    final state = WaterTrackerState.initial(DateTime(2026, 5, 12)).copyWith(
      hasStartedTracking: true,
      goalCups: 8,
      drankCups: 6,
      currentDateKey: '2026-05-12',
    );

    final nextState = state.normalizeForDate(DateTime(2026, 5, 15, 9));

    expect(nextState.currentDateKey, '2026-05-15');
    expect(nextState.history['2026-05-12']?.drankCups, 6);
    expect(nextState.history['2026-05-13']?.drankCups, 0);
    expect(nextState.history['2026-05-14']?.drankCups, 0);
  });
}
