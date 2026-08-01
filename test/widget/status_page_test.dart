import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/repositories/settings_repository.dart';
import 'package:seu_metro/features/status/status_page.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/line_status.dart';
import 'package:seu_metro/providers/repositories.dart';
import 'package:seu_metro/providers/settings_provider.dart';
import 'package:seu_metro/providers/status_provider.dart';

void main() {
  final linesFixture = <String, Line>{
    '1': const Line(id: '1', name: 'Linha 1 - Azul', colorValue: 0xFF00378C, operator: 'metro', terminalA: 'A', terminalB: 'B', stationIds: []),
    '2': const Line(id: '2', name: 'Linha 2 - Verde', colorValue: 0xFF186D55, operator: 'metro', terminalA: 'C', terminalB: 'D', stationIds: []),
  };

  testWidgets('StatusPage usa intervalo configurado para o timer', (tester) async {
    final snapshot = StatusSnapshot(
      data: [LineStatus(lineId: '1', statusCode: 'OperacaoNormal', statusLabel: 'Operação Normal', statusColor: 'verde', description: null, updatedAt: DateTime.now())],
      updatedAt: DateTime.now(),
      isStale: false,
    );
    final overrides = [
      statusProvider.overrideWith((ref) => Future.value(snapshot)),
      linesProvider.overrideWith((ref) => Future.value(linesFixture)),
      settingsProvider.overrideWith((ref) => SettingsNotifier(
        SettingsRepository(),
        const SettingsState(
          themeMode: ThemeMode.system,
          refreshIntervalMinutes: 15,
          textScale: TextScale.normal,
          highContrast: false,
        ),
      )),
    ];
    await tester.pumpWidget(ProviderScope(overrides: overrides, child: const MaterialApp(home: StatusPage())));
    await tester.pumpAndSettle();
    expect(find.textContaining('Operação Normal'), findsWidgets);
  });

  testWidgets('StatusPage mostra cartões com bloco de cor e chip', (tester) async {
    final snapshot = StatusSnapshot(
      data: [
        LineStatus(lineId: '1', statusCode: 'OperacaoNormal', statusLabel: 'Operação Normal', statusColor: 'verde', description: null, updatedAt: DateTime.now()),
        LineStatus(lineId: '2', statusCode: 'OperacaoReduzida', statusLabel: 'Operação Reduzida', statusColor: 'amarelo', description: 'Trens circulando com intervalos maiores', updatedAt: DateTime.now()),
      ],
      updatedAt: DateTime.now(),
      isStale: false,
    );
    final overrides = [
      statusProvider.overrideWith((ref) => Future.value(snapshot)),
      linesProvider.overrideWith((ref) => Future.value(linesFixture)),
    ];
    await tester.pumpWidget(ProviderScope(overrides: overrides, child: const MaterialApp(home: StatusPage())));
    await tester.pumpAndSettle();
    expect(find.textContaining('Operação Normal'), findsWidgets);
    expect(find.text('Linha 1'), findsOneWidget);
    expect(find.textContaining('Trens circulando'), findsWidgets);
    expect(find.textContaining('atualizado'), findsWidgets);
  });
}
