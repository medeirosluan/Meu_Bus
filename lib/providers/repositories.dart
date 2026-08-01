import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/data/repositories/favorites_repository.dart';
import 'package:seu_metro/data/repositories/line_repository.dart';
import 'package:seu_metro/data/repositories/schedule_repository.dart';
import 'package:seu_metro/data/repositories/station_repository.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/line_schedule.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/services/pathfinding/metro_graph.dart';

final lineRepositoryProvider = Provider<LineRepository>((ref) => LineRepository());
final stationRepositoryProvider = Provider<StationRepository>((ref) => StationRepository());
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) => ScheduleRepository());
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) => FavoritesRepository());

final stationsProvider = FutureProvider<List<Station>>((ref) async {
  return ref.watch(stationRepositoryProvider).getAll();
});

final linesProvider = FutureProvider<Map<String, Line>>((ref) async {
  return ref.watch(lineRepositoryProvider).byId();
});

final schedulesProvider = FutureProvider<List<LineSchedule>>((ref) async {
  return ref.watch(scheduleRepositoryProvider).getAll();
});

final metroGraphProvider = FutureProvider<MetroGraph>((ref) async {
  final lines = await ref.watch(lineRepositoryProvider).getAll();
  final stations = await ref.watch(stationRepositoryProvider).getAll();
  return MetroGraph.build(lines, stations);
});

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>(
        (ref) => FavoritesNotifier(ref.watch(favoritesRepositoryProvider)));

final selectedRouteOriginProvider = StateProvider<Station?>((ref) => null);

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final FavoritesRepository _repo;
  FavoritesNotifier(this._repo) : super(const {}) {
    _load();
  }
  Future<void> _load() async {
    state = (await _repo.getFavorites()).toSet();
  }
  Future<void> toggle(String stationId) async {
    await _repo.toggle(stationId);
    state = (await _repo.getFavorites()).toSet();
  }
}
