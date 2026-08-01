import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/home/home_shell.dart';
import 'package:seu_metro/models/line_status.dart';
import 'package:seu_metro/providers/status_provider.dart';

void main() {
  testWidgets('HomeShell mostra 5 destinos de navegação', (tester) async {
    final snapshot = StatusSnapshot(
      data: [LineStatus(lineId: '1', statusCode: 'OperacaoNormal', statusLabel: 'Operação Normal', statusColor: 'verde', description: null, updatedAt: DateTime.now())],
      updatedAt: DateTime.now(),
      isStale: false,
    );
    final override = statusProvider.overrideWith((ref) => Future.value(snapshot));
    await tester.pumpWidget(ProviderScope(overrides: [override], child: const MaterialApp(home: HomeShell())));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    final navBar = find.byType(NavigationBar);
    expect(find.descendant(of: navBar, matching: find.text('Mapa')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Rotas')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Status')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Horários')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Favoritos')), findsOneWidget);
  });
}
