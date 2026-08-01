import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/providers/navigation.dart';

import '../favorites/favorites_page.dart';
import '../routes/routes_page.dart';
import '../schedules/schedules_page.dart';
import '../status/status_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _pages = [
    RoutesPage(),
    StatusPage(),
    SchedulesPage(),
    FavoritesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(selectedTabProvider);
    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        backgroundColor: const Color(0xFF00378C),
        indicatorColor: Colors.white24,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        onDestinationSelected: (i) =>
            ref.read(selectedTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.route_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.route, color: Colors.white),
            label: 'Rotas',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.sensors, color: Colors.white),
            label: 'Status',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.schedule, color: Colors.white),
            label: 'Horários',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline, color: Colors.white70),
            selectedIcon: Icon(Icons.star, color: Colors.white),
            label: 'Favoritos',
          ),
        ],
      ),
    );
  }
}
