import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/status/status_page.dart';
import 'package:seu_metro/models/line_status.dart';
import 'package:seu_metro/providers/repositories.dart';
import 'package:seu_metro/providers/status_provider.dart';
import 'package:flutter/services.dart';

void main() {
  testWidgets('StatusPage A', (tester) async {
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

  testWidgets('StatusPage B', (tester) async {
    await tester.runAsync(() => rootBundle.loadString('assets/data/lines.json'));
    final snapshot = StatusSnapshot(
      data: [LineStatus(lineId: '1', statusCode: 'OperacaoNormal', statusLabel: 'Operação Normal', statusColor: 'verde', description: null, updatedAt: DateTime.now())],
      updatedAt: DateTime.now(),
      isStale: false,
    );
    final override = statusProvider.overrideWith((ref) => Future.value(snapshot));
    await tester.pumpWidget(ProviderScope(overrides: [override], child: const MaterialApp(home: StatusPage())));
    await tester.pumpAndSettle();
    debugPrint('B_LINES=${ProviderScope.containerOf(tester.element(find.byType(StatusPage)), listen: false).read(linesProvider)}');
    expect(find.textContaining('Operação Normal'), findsWidgets);
    expect(find.text('Linha 1'), findsOneWidget);
  });
}
