import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persiste e carrega configurações', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = SettingsRepository();
    const state = SettingsState(
      themeMode: ThemeMode.dark,
      refreshIntervalMinutes: 15,
      textScale: TextScale.large,
      highContrast: true,
    );
    await repo.save(state);
    final loaded = await repo.load();
    expect(loaded.themeMode, ThemeMode.dark);
    expect(loaded.refreshIntervalMinutes, 15);
    expect(loaded.textScale, TextScale.large);
    expect(loaded.highContrast, isTrue);
  });

  test('load retorna default quando nada salvo', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = SettingsRepository();
    final loaded = await repo.load();
    expect(loaded.themeMode, ThemeMode.system);
    expect(loaded.refreshIntervalMinutes, 5);
    expect(loaded.textScale, TextScale.normal);
    expect(loaded.highContrast, isFalse);
  });
}
