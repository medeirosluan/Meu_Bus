import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TextScale { small, normal, large }

class SettingsState {
  final ThemeMode themeMode;
  final int refreshIntervalMinutes;
  final TextScale textScale;
  final bool highContrast;

  const SettingsState({
    required this.themeMode,
    required this.refreshIntervalMinutes,
    required this.textScale,
    required this.highContrast,
  });

  const SettingsState.defaults()
      : themeMode = ThemeMode.system,
        refreshIntervalMinutes = 5,
        textScale = TextScale.normal,
        highContrast = false;

  SettingsState copyWith({
    ThemeMode? themeMode,
    int? refreshIntervalMinutes,
    TextScale? textScale,
    bool? highContrast,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      refreshIntervalMinutes:
          refreshIntervalMinutes ?? this.refreshIntervalMinutes,
      textScale: textScale ?? this.textScale,
      highContrast: highContrast ?? this.highContrast,
    );
  }
}

class SettingsRepository {
  static const _kTheme = 'settings_theme_mode';
  static const _kRefresh = 'settings_refresh_minutes';
  static const _kTextScale = 'settings_text_scale';
  static const _kHighContrast = 'settings_high_contrast';

  Future<SettingsState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsState(
      themeMode: _themeMode(prefs.getString(_kTheme)),
      refreshIntervalMinutes: prefs.getInt(_kRefresh) ?? 5,
      textScale: _textScale(prefs.getString(_kTextScale)),
      highContrast: prefs.getBool(_kHighContrast) ?? false,
    );
  }

  Future<void> save(SettingsState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, state.themeMode.name);
    await prefs.setInt(_kRefresh, state.refreshIntervalMinutes);
    await prefs.setString(_kTextScale, state.textScale.name);
    await prefs.setBool(_kHighContrast, state.highContrast);
  }

  ThemeMode _themeMode(String? value) {
    for (final mode in ThemeMode.values) {
      if (mode.name == value) return mode;
    }
    return ThemeMode.system;
  }

  TextScale _textScale(String? value) {
    for (final scale in TextScale.values) {
      if (scale.name == value) return scale;
    }
    return TextScale.normal;
  }
}
