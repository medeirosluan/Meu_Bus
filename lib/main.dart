import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_shell.dart';

void main() {
  runApp(const ProviderScope(child: SeuMetroApp()));
}

ThemeData _buildLightTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00378C)),
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

ThemeData _buildDarkTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00378C),
      brightness: Brightness.dark,
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

class SeuMetroApp extends StatelessWidget {
  const SeuMetroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seu Metrô',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const HomeShell(),
    );
  }
}
