import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/routes/routes_page.dart';

void main() {
  testWidgets('botão desabilitado até selecionar origem e destino; busca abre resultado',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RoutesPage())));
    await tester.pumpAndSettle();
    final buttonFinder = find.widgetWithText(FilledButton, 'Busca rota');
    FilledButton button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull);
    expect(find.byIcon(Icons.circle), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).first, 'Luz');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luz').first);
    await tester.pumpAndSettle();
    button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull);
    await tester.enterText(find.byType(TextField).last, 'Santo Amaro');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Santo Amaro').last);
    await tester.pumpAndSettle();
    button = tester.widget(buttonFinder);
    expect(button.onPressed, isNotNull);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
    expect(find.text('Melhor trajeto'), findsOneWidget);
  });
}
