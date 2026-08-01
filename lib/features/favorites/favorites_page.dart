import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/navigation.dart';
import 'package:seu_metro/providers/repositories.dart';
import 'package:seu_metro/theme/line_colors.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final stationsAsync = ref.watch(stationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: stationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: Text('Não foi possível carregar as estações.')),
        data: (stations) {
          final favorites = stations
              .where((s) => favoriteIds.contains(s.id))
              .toList();
          if (favorites.isEmpty) {
            return const Center(child: Text('Nenhuma estação favorita ainda'));
          }
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) => _FavoriteCard(
              station: favorites[index],
              onToggle: () =>
                  ref.read(favoritesProvider.notifier).toggle(favorites[index].id),
              onGetDirections: () {
                ref.read(selectedRouteOriginProvider.notifier).state =
                    favorites[index];
                ref.read(selectedTabProvider.notifier).state = Tabs.routes;
              },
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.station,
    required this.onToggle,
    required this.onGetDirections,
  });

  final Station station;
  final VoidCallback onToggle;
  final VoidCallback onGetDirections;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    station.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.star),
                  color: Colors.amber,
                  tooltip: 'Remover dos favoritos',
                  onPressed: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final lineId in station.lineIds)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(LineColors.colorFor(lineId)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Linha $lineId',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onGetDirections,
                child: const Text('Como chegar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
