import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/navigation.dart';
import 'package:seu_metro/providers/repositories.dart';
import 'package:seu_metro/theme/line_colors.dart';

void showStationSheet(BuildContext context, Station station) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _StationSheet(station: station),
  );
}

class _StationSheet extends ConsumerWidget {
  const _StationSheet({required this.station});

  static const _routesTab = 1;
  static const _schedulesTab = 3;

  final Station station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(station.id);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    station.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.amber : null,
                  ),
                  onPressed: () =>
                      ref.read(favoritesProvider.notifier).toggle(station.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: station.lineIds.map((lineId) {
                final color = Color(LineColors.colorFor(lineId));
                return Chip(
                  label: Text('Linha $lineId'),
                  labelStyle: const TextStyle(color: Colors.white),
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: color.withValues(alpha: 0.4)),
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref.read(selectedTabProvider.notifier).state = _schedulesTab;
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Ver horários'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref.read(selectedRouteOriginProvider.notifier).state = station;
                      ref.read(selectedTabProvider.notifier).state = _routesTab;
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Como chegar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
