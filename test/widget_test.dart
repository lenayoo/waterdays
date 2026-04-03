import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterdays/main.dart';

void main() {
  testWidgets('waterdays uses per-cup toggles with goal limit and completion lock', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WaterDaysApp());

    await tester.enterText(find.byType(TextField), 'Lena');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    final goalField = find.byType(TextField);
    await tester.enterText(goalField, '17');
    await tester.pump();
    expect(find.text('17'), findsNothing);

    await tester.enterText(goalField, '6');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.textContaining('6잔이에요'), findsOneWidget);

    await tester.tap(find.text('물마시기로 시작하기'));
    await tester.pumpAndSettle();

    expect(find.byType(WaterCup), findsNWidgets(6));
    expect(find.textContaining('현재 0잔 완료'), findsOneWidget);

    await tester.tap(find.byType(WaterCup).at(2));
    await tester.pumpAndSettle();
    expect(find.textContaining('현재 1잔 완료'), findsOneWidget);

    await tester.tap(find.byType(WaterCup).at(2));
    await tester.pumpAndSettle();
    expect(find.textContaining('현재 0잔 완료'), findsOneWidget);

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byType(WaterCup).at(i));
      await tester.pumpAndSettle();
    }

    expect(find.text('오늘은 목표를 완료했어요!'), findsOneWidget);

    await tester.tap(find.byType(WaterCup).first);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('오늘은 목표를 완료했어요!'), findsOneWidget);
  });
}
