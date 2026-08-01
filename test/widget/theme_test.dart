import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/repositories/settings_repository.dart';
import 'package:seu_metro/main.dart';
import 'package:seu_metro/models/line_status.dart';
import 'package:seu_metro/providers/settings_provider.dart';
import 'package:seu_metro/providers/status_provider.dart';

void main() {
  final snapshot = StatusSnapshot(
    data: [
      LineStatus(lineId: '1', statusCode: 'OperacaoNormal', statusLabel: 'Operação Normal', statusColor: 'verde', description: null, updatedAt: DateTime.now()),
    ],
    updatedAt: DateTime.now(),
    isStale: false,
  );
  final statusOverride = statusProvider.overrideWith((ref) => Future.value(snapshot));

  testWidgets('tema claro usa fundo F6F7FB', (tester) async {
    final override = settingsProvider.overrideWith((ref) => SettingsNotifier(
      SettingsRepository(),
      const SettingsState(
        themeMode: ThemeMode.light,
        refreshIntervalMinutes: 5,
        textScale: TextScale.normal,
        highContrast: false,
      ),
    ));
    await tester.pumpWidget(ProviderScope(overrides: [override, statusOverride], child: const SeuMetroApp()));
    await tester.pump();
    final context = tester.element(find.byType(Scaffold).first);
    final theme = Theme.of(context);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF6F7FB));
  });

  testWidgets('tema escuro aplicado via configuração', (tester) async {
    final override = settingsProvider.overrideWith((ref) => SettingsNotifier(
      SettingsRepository(),
      const SettingsState(
        themeMode: ThemeMode.dark,
        refreshIntervalMinutes: 5,
        textScale: TextScale.normal,
        highContrast: false,
      ),
    ));
    await tester.pumpWidget(ProviderScope(overrides: [override, statusOverride], child: const SeuMetroApp()));
    await tester.pump();
    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
