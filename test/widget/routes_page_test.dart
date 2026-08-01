import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/routes/routes_page.dart';

void main() {
  testWidgets('RoutesPage mostra guia passo a passo com Busca rota', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RoutesPage())));
    await tester.pumpAndSettle();
    expect(find.text('Origem'), findsOneWidget);
    expect(find.text('Destino'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Luz');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luz').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Santo Amaro');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Santo Amaro').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Busca rota'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Como chegar em Santo Amaro'), findsOneWidget);
    expect(find.textContaining('Rota com'), findsOneWidget);
    expect(find.textContaining('Pegue a'), findsWidgets);
    expect(find.textContaining('Baldear para a'), findsWidgets);
    expect(find.textContaining('Desça em Santo Amaro'), findsOneWidget);
  });
}
