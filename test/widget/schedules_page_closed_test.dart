import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/schedules/schedules_page.dart';

void main() {
  testWidgets('SchedulesPage mostra estação fechada fora do horário', (tester) async {
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: SchedulesPage(clock: () => DateTime(2026, 1, 1, 3, 0)))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Luz');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luz').first);
    await tester.pumpAndSettle();
    expect(find.text('Estação fechada'), findsWidgets);
    expect(find.textContaining('Primeiro trem'), findsNothing);
  });
}
