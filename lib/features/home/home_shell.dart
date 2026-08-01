import 'package:flutter/material.dart';

import '../favorites/favorites_page.dart';
import '../map/map_page.dart';
import '../routes/routes_page.dart';
import '../schedules/schedules_page.dart';
import '../status/status_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    MapPage(),
    RoutesPage(),
    StatusPage(),
    SchedulesPage(),
    FavoritesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.route_outlined), label: 'Rotas'),
          NavigationDestination(icon: Icon(Icons.sensors_outlined), label: 'Status'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), label: 'Horários'),
          NavigationDestination(icon: Icon(Icons.star_outline), label: 'Favoritos'),
        ],
      ),
    );
  }
}
