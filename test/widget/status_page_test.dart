import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/status/status_page.dart';
import 'package:seu_metro/models/line_status.dart';
import 'package:seu_metro/providers/status_provider.dart';

void main() {
  testWidgets('StatusPage lista linhas com status', (tester) async {
    final snapshot = StatusSnapshot(
      data: [LineStatus(lineId: '1', statusCode: 'OperacaoNormal', statusLabel: 'Operação Normal', statusColor: 'verde', description: null, updatedAt: DateTime.now())],
      updatedAt: DateTime.now(),
      isStale: false,
    );
    final override = statusProvider.overrideWith((ref) => Future.value(snapshot));
    await tester.pumpWidget(ProviderScope(overrides: [override], child: const MaterialApp(home: StatusPage())));
    await tester.pumpAndSettle();
    expect(find.textContaining('Operação Normal'), findsWidgets);
  });
}
