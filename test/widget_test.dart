import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterdays/app_localizations.dart';
import 'package:waterdays/main.dart';
import 'package:waterdays/water_reminder_service.dart';
import 'package:waterdays/water_state_store.dart';

void main() {
  testWidgets('goal input is capped and tracker opens from the main screen', (
    WidgetTester tester,
  ) async {
    final l10n = AppLocalizations(const Locale('ko'));
    final store = MemoryWaterStateStore();

    await tester.pumpWidget(
      WaterDaysApp(
        locale: const Locale('ko'),
        stateStore: store,
        reminderService: NoopWaterReminderService(),
      ),
    );
    await tester.pumpAndSettle();

    final goalField = find.byType(TextField);
    await tester.enterText(goalField, '17');
    await tester.pump();
    expect(find.text('17'), findsNothing);

    await tester.enterText(goalField, '6');
    expect(find.text(l10n.startTrackingButton), findsOneWidget);
    await tester.tap(find.text(l10n.startTrackingButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.trackerGoal(6)), findsOneWidget);
    expect(find.byType(WaterCup), findsNWidgets(6));
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
  });

  testWidgets('tracker shows cups and completion dialog', (
    WidgetTester tester,
  ) async {
    final l10n = AppLocalizations(const Locale('ko'));
    final store = MemoryWaterStateStore();

    await tester.pumpWidget(
      WaterDaysApp(
        locale: const Locale('ko'),
        stateStore: store,
        reminderService: NoopWaterReminderService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '6');
    await tester.tap(find.text(l10n.startTrackingButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.trackerGoal(6)), findsOneWidget);
    expect(find.byType(WaterCup), findsNWidgets(6));

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byType(WaterCup).at(i));
      await tester.pump(const Duration(milliseconds: 350));
    }
    await tester.pump();

    expect(find.text(l10n.completionDialogContent), findsWidgets);
    expect(find.text(l10n.completionDialogAction), findsOneWidget);

    await tester.tap(find.text(l10n.completionDialogAction));
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(const ValueKey('trackerCelebrationEmoji')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.remove), findsNothing);
  });

  testWidgets(
    'random cup taps fill only that cup and minus clears from the end',
    (WidgetTester tester) async {
      final l10n = AppLocalizations(const Locale('en'));
      final store = MemoryWaterStateStore();

      await tester.pumpWidget(
        WaterDaysApp(
          locale: const Locale('en'),
          stateStore: store,
          reminderService: NoopWaterReminderService(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '6');
      await tester.tap(find.text(l10n.startTrackingButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(WaterCup).at(4));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.byType(WaterCup).at(1));
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        tester.widget<WaterCup>(find.byType(WaterCup).at(0)).isFilled,
        isFalse,
      );
      expect(
        tester.widget<WaterCup>(find.byType(WaterCup).at(1)).isFilled,
        isTrue,
      );
      expect(
        tester.widget<WaterCup>(find.byType(WaterCup).at(2)).isFilled,
        isFalse,
      );
      expect(
        tester.widget<WaterCup>(find.byType(WaterCup).at(3)).isFilled,
        isFalse,
      );
      expect(
        tester.widget<WaterCup>(find.byType(WaterCup).at(4)).isFilled,
        isTrue,
      );
      expect(
        tester.widget<WaterCup>(find.byType(WaterCup).at(5)).isFilled,
        isFalse,
      );

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        tester.widget<WaterCup>(find.byType(WaterCup).at(1)).isFilled,
        isTrue,
      );
      expect(
        tester.widget<WaterCup>(find.byType(WaterCup).at(4)).isFilled,
        isFalse,
      );
      expect(find.text('1 / 6'), findsOneWidget);
    },
  );

  testWidgets('app reopens into tracker and goal can be edited from header', (
    WidgetTester tester,
  ) async {
    final l10n = AppLocalizations(const Locale('en'));
    final store = MemoryWaterStateStore();

    await tester.pumpWidget(
      WaterDaysApp(
        locale: const Locale('en'),
        stateStore: store,
        reminderService: NoopWaterReminderService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '2');
    await tester.tap(find.text(l10n.startTrackingButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.trackerGoal(2)), findsOneWidget);
    expect(find.text(l10n.startTrackingButton), findsNothing);

    await tester.pumpWidget(
      WaterDaysApp(
        locale: const Locale('en'),
        stateStore: store,
        reminderService: NoopWaterReminderService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.trackerGoal(2)), findsOneWidget);
    expect(find.text(l10n.startTrackingButton), findsNothing);

    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    expect(find.text(l10n.editGoalTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField), '4');
    await tester.tap(find.text(l10n.saveGoalButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.trackerGoal(4)), findsOneWidget);
    expect(find.byType(WaterCup), findsNWidgets(4));
  });

  testWidgets('monthly history sheet opens on small screens without overflow', (
    WidgetTester tester,
  ) async {
    final l10n = AppLocalizations(const Locale('en'));
    final store = MemoryWaterStateStore();

    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      WaterDaysApp(
        locale: const Locale('en'),
        stateStore: store,
        reminderService: NoopWaterReminderService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Monthly record'), findsNothing);
    expect(find.text(l10n.calendarEmptyTitle), findsOneWidget);
  });
}
