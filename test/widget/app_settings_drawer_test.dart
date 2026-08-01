import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/repositories/settings_repository.dart';
import 'package:seu_metro/features/settings/app_settings_drawer.dart';
import 'package:seu_metro/providers/settings_provider.dart';

void main() {
  testWidgets('drawer lista as seções de configuração', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final override = settingsProvider.overrideWith((ref) => SettingsNotifier(
      SettingsRepository(),
      const SettingsState.defaults(),
    ));
    await tester.pumpWidget(ProviderScope(
      overrides: [override],
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Abrir menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          )),
          drawer: const AppSettingsDrawer(),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Frequência de atualização'), findsOneWidget);
    expect(find.text('Acessibilidade'), findsOneWidget);
    expect(find.text('Recursos offline'), findsOneWidget);
    expect(find.text('Sobre o app'), findsOneWidget);
  });
}
