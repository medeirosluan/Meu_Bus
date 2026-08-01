import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/home/home_shell.dart';

void main() {
  testWidgets('HomeShell mostra 5 destinos de navegação', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: HomeShell())));
    expect(find.byType(NavigationBar), findsOneWidget);
    final navBar = find.byType(NavigationBar);
    expect(find.descendant(of: navBar, matching: find.text('Mapa')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Rotas')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Status')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Horários')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Favoritos')), findsOneWidget);
  });
}
