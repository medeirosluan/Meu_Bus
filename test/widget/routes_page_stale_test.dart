import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/routes/routes_page.dart';

void main() {
  testWidgets('RoutesPage ignora texto editado que não bate com estação selecionada', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RoutesPage())));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Luz');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luz').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Santo Amaro');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Santo Amaro').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Luz Norte');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Calcular rota'));
    await tester.pumpAndSettle();
    expect(find.textContaining('min no total'), findsNothing);
  });
}
