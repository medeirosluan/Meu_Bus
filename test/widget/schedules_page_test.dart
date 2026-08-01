import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/schedules/schedules_page.dart';

void main() {
  testWidgets('SchedulesPage mostra horários da estação', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SchedulesPage())));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Luz');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luz').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Primeiro trem'), findsWidgets);
  });
}
