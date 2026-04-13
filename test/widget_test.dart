import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterdays/app_localizations.dart';
import 'package:waterdays/main.dart';

void main() {
  testWidgets(
    'waterdays supports monthly calendar and completion celebration',
    (WidgetTester tester) async {
      final l10n = AppLocalizations(const Locale('ko'));

      await tester.pumpWidget(const WaterDaysApp(locale: Locale('ko')));
      await tester.pumpAndSettle();

      final goalField = find.byType(TextField);
      await tester.enterText(goalField, '17');
      await tester.pump();
      expect(find.text('17'), findsNothing);

      await tester.enterText(goalField, '6');
      await tester.tap(find.text(l10n.nextButton).last);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(l10n.viewMonthlyRecordButton), findsOneWidget);
      expect(find.text(l10n.startTrackingButton), findsOneWidget);

      await tester.tap(find.text(l10n.viewMonthlyRecordButton));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.textContaining('월 기록'), findsOneWidget);
      expect(find.textContaining('물을 많이 마시는 습관을 들여요!'), findsOneWidget);
      expect(find.text(l10n.goToTodayTrackingButton), findsOneWidget);

      await tester.ensureVisible(find.text(l10n.goToTodayTrackingButton));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text(l10n.goToTodayTrackingButton));
      await tester.pump(const Duration(milliseconds: 350));

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

      await tester.tap(find.byType(WaterCup).first);
      await tester.tap(find.byIcon(Icons.remove));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text(l10n.trackerGoal(6)), findsOneWidget);
    },
  );
}
