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
        onDestinationSelected: (i) =>
            ref.read(selectedTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.route_outlined), label: 'Rotas'),
          NavigationDestination(icon: Icon(Icons.sensors_outlined), label: 'Status'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), label: 'Horários'),
          NavigationDestination(icon: Icon(Icons.star_outline), label: 'Favoritos'),
        ],
      ),
    );
  }
}
