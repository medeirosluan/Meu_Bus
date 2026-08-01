import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/data/repositories/settings_repository.dart';
import 'package:seu_metro/providers/settings_provider.dart';

import 'offline_info_page.dart';

class AppSettingsDrawer extends ConsumerWidget {
  const AppSettingsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final themeMode = settings.themeMode;
    final refresh = settings.refreshIntervalMinutes;
    final textScale = settings.textScale;
    final highContrast = settings.highContrast;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF00378C)),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.directions_subway, color: Color(0xFF00378C)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Seu Metrô',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('Configurações', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Tema', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
                ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) => notifier.setThemeMode(s.first),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Frequência de atualização', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1 min')),
                ButtonSegment(value: 5, label: Text('5 min')),
                ButtonSegment(value: 15, label: Text('15 min')),
              ],
              selected: {refresh},
              onSelectionChanged: (s) => notifier.setRefreshIntervalMinutes(s.first),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Acessibilidade', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<TextScale>(
              segments: const [
                ButtonSegment(value: TextScale.small, label: Text('Pequeno')),
                ButtonSegment(value: TextScale.normal, label: Text('Normal')),
                ButtonSegment(value: TextScale.large, label: Text('Grande')),
              ],
              selected: {textScale},
              onSelectionChanged: (s) => notifier.setTextScale(s.first),
            ),
          ),
          SwitchListTile(
            title: const Text('Alto contraste'),
            value: highContrast,
            onChanged: (v) => notifier.setHighContrast(v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_off_outlined),
            title: const Text('Recursos offline'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OfflineInfoPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre o app'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Seu Metrô',
              applicationVersion: '1.0.0',
              children: const [Text('App de informações do Metrô e CPTM de São Paulo.')],
            ),
          ),
        ],
      ),
    );
  }
}
