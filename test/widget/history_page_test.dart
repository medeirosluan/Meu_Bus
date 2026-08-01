import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/history/history_page.dart';
import 'package:seu_metro/models/direto_status.dart';
import 'package:seu_metro/providers/direto_providers.dart';

void main() {
  testWidgets('HistoryPage sem token mostra aviso e botão desabilitado',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: HistoryPage())));
    await tester.pumpAndSettle();
    expect(find.textContaining('Configure o token'), findsOneWidget);
    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Ver histórico'));
    expect(button.onPressed, isNull);
  });

  testWidgets('HistoryPage com dados mostra cartões', (tester) async {
    final status = DiretoStatus(
      codigo: 1, situacao: 'Operação Reduzida', descricao: 'Intervalo maior',
      criado: DateTime.utc(2026, 7, 31, 8, 30), modificado: null, id: 1,
    );
    final token = diretoTokenConfiguredProvider.overrideWith((ref) => true);
    final history = historyProvider.overrideWith(
        (ref, arg) => Future.value([status]));
    await tester.pumpWidget(ProviderScope(
      overrides: [token, history],
      child: const MaterialApp(home: HistoryPage()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ver histórico'));
    await tester.pumpAndSettle();
    expect(find.text('Operação Reduzida'), findsOneWidget);
    expect(find.textContaining('Intervalo maior'), findsOneWidget);
  });
}
