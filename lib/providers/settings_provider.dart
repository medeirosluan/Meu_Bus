import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/data/repositories/settings_repository.dart';

final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) => SettingsRepository());

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final notifier = SettingsNotifier(
    ref.watch(settingsRepositoryProvider),
    const SettingsState.defaults(),
  );
  notifier.load();
  return notifier;
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo, SettingsState initial) : super(initial);

  Future<void> load() async {
    try {
      state = await _repo.load();
    } catch (_) {
      state = const SettingsState.defaults();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update((s) => s.copyWith(themeMode: mode));

  Future<void> setRefreshIntervalMinutes(int minutes) =>
      _update((s) => s.copyWith(refreshIntervalMinutes: minutes));

  Future<void> setTextScale(TextScale scale) =>
      _update((s) => s.copyWith(textScale: scale));

  Future<void> setHighContrast(bool enabled) =>
      _update((s) => s.copyWith(highContrast: enabled));

  Future<void> _update(SettingsState Function(SettingsState) fn) async {
    final next = fn(state);
    state = next;
    try {
      await _repo.save(next);
    } catch (_) {}
  }
}
