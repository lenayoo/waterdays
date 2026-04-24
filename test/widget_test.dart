import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterdays/app_localizations.dart';
import 'package:waterdays/main.dart';

void main() {
  testWidgets('goal input is capped and tracker opens from the main screen', (
    WidgetTester tester,
  ) async {
    final l10n = AppLocalizations(const Locale('ko'));

    await tester.pumpWidget(const WaterDaysApp(locale: Locale('ko')));
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

    await tester.pumpWidget(const WaterDaysApp(locale: Locale('ko')));
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

    expect(find.text(l10n.completionDialogTitle), findsOneWidget);
    expect(find.text(l10n.completionDialogAction), findsOneWidget);

    await tester.tap(find.text(l10n.completionDialogAction));
    await tester.pump(const Duration(milliseconds: 350));
  });
}
