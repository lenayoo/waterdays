import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterdays/app_strings.dart';
import 'package:waterdays/main.dart';

void main() {
  testWidgets(
    'waterdays supports monthly calendar and completion celebration',
    (WidgetTester tester) async {
      await tester.pumpWidget(const WaterDaysApp());

      final goalField = find.byType(TextField).last;
      await tester.enterText(goalField, '17');
      await tester.pump();
      expect(find.text('17'), findsNothing);

      await tester.enterText(goalField, '6');
      await tester.tap(find.text(AppStrings.nextButton).last);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(AppStrings.viewMonthlyRecordButton), findsOneWidget);
      expect(find.text(AppStrings.startTrackingButton), findsOneWidget);

      await tester.tap(find.text(AppStrings.viewMonthlyRecordButton));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.textContaining('월 기록'), findsOneWidget);
      expect(find.textContaining('물을 많이 마시는 습관을 들여요!'), findsOneWidget);
      expect(find.text(AppStrings.goToTodayTrackingButton), findsOneWidget);

      await tester.ensureVisible(find.text(AppStrings.goToTodayTrackingButton));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text(AppStrings.goToTodayTrackingButton));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(WaterCup), findsNWidgets(6));

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byType(WaterCup).at(i));
        await tester.pump(const Duration(milliseconds: 350));
      }
      await tester.pump();

      expect(find.text(AppStrings.completionDialogTitle), findsOneWidget);
      expect(find.text(AppStrings.completionDialogAction), findsOneWidget);

      await tester.tap(find.text(AppStrings.completionDialogAction));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byType(WaterCup).first);
      await tester.tap(find.byIcon(Icons.remove));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text(AppStrings.trackerGoal(6)), findsOneWidget);
    },
  );
}
