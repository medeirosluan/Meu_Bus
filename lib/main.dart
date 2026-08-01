import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/settings_repository.dart';
import 'features/home/home_shell.dart';
import 'providers/settings_provider.dart';

void main() {
  runApp(const ProviderScope(child: SeuMetroApp()));
}

ThemeData _buildLightTheme(bool highContrast) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00378C),
      contrastLevel: highContrast ? 1.0 : 0.0,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF6F7FB),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF6F7FB),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF0B1B33),
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}

ThemeData _buildDarkTheme(bool highContrast) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00378C),
      brightness: Brightness.dark,
      contrastLevel: highContrast ? 1.0 : 0.0,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}

class SeuMetroApp extends ConsumerWidget {
  const SeuMetroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = settings.themeMode;
    final highContrast = settings.highContrast;
    final textScale = settings.textScale;
    final scale = switch (textScale) {
      TextScale.small => 0.9,
      TextScale.large => 1.15,
      TextScale.normal => 1.0,
    };
    return MaterialApp(
      title: 'Seu Metrô',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(highContrast),
      darkTheme: _buildDarkTheme(highContrast),
      themeMode: themeMode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const HomeShell(),
    );
  }
}
