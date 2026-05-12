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
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(l10n.trackerGoal(6)), findsOneWidget);
    expect(find.byType(WaterCup), findsNWidgets(6));
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
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text(l10n.trackerGoal(6)), findsOneWidget);
    expect(find.byType(WaterCup), findsNWidgets(6));

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byType(WaterCup).at(i));
      await tester.pump(const Duration(milliseconds: 350));
    }
    await tester.pump();

    expect(find.text(l10n.completionDialogContent), findsOneWidget);
    expect(find.text(l10n.completionDialogAction), findsOneWidget);

    await tester.tap(find.text(l10n.completionDialogAction));
    await tester.pump(const Duration(milliseconds: 350));
  });

  testWidgets('completed tracker can be adjusted and completed again', (
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
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.byType(WaterCup).at(0));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byType(WaterCup).at(1));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text(l10n.completionDialogContent), findsOneWidget);
    await tester.tap(find.text(l10n.completionDialogAction));
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.byType(WaterCup).at(1));
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      tester.widget<WaterCup>(find.byType(WaterCup).at(0)).isFilled,
      isTrue,
    );
    expect(
      tester.widget<WaterCup>(find.byType(WaterCup).at(1)).isFilled,
      isFalse,
    );

    await tester.tap(find.byType(WaterCup).at(1));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text(l10n.completionDialogContent), findsOneWidget);
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

    expect(find.text(l10n.monthlyRecordTitle), findsOneWidget);
  });
}
