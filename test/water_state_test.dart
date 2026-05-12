import 'package:flutter_test/flutter_test.dart';
import 'package:waterdays/water_state.dart';

void main() {
  test('daily reset archives the previous day and clears today count', () {
    final state = WaterTrackerState.initial(DateTime(2026, 5, 12)).copyWith(
      hasStartedTracking: true,
      goalCups: 8,
      filledCupIndices: const [0, 1, 2, 3, 4],
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
      filledCupIndices: const [0, 1, 2, 3, 4, 5],
      currentDateKey: '2026-05-12',
    );

    final nextState = state.normalizeForDate(DateTime(2026, 5, 15, 9));

    expect(nextState.currentDateKey, '2026-05-15');
    expect(nextState.history['2026-05-12']?.drankCups, 6);
    expect(nextState.history['2026-05-13']?.drankCups, 0);
    expect(nextState.history['2026-05-14']?.drankCups, 0);
  });

  test('random cup tap only toggles the tapped cup', () {
    final state = WaterTrackerState.initial(DateTime(2026, 5, 12)).copyWith(
      hasStartedTracking: true,
      goalCups: 6,
      filledCupIndices: const [1, 4],
      currentDateKey: '2026-05-12',
    );

    final nextState = state.toggleCup(3);

    expect(nextState.filledCupIndices, [1, 3, 4]);
    expect(nextState.cupStates, [false, true, false, true, true, false]);
  });

  test('decrement removes the last filled cup first', () {
    final state = WaterTrackerState.initial(DateTime(2026, 5, 12)).copyWith(
      hasStartedTracking: true,
      goalCups: 6,
      filledCupIndices: const [0, 2, 5],
      currentDateKey: '2026-05-12',
    );

    final nextState = state.decrementCup();

    expect(nextState.filledCupIndices, [0, 2]);
    expect(nextState.cupStates, [true, false, true, false, false, false]);
  });
}
