import 'dart:convert';

import 'package:seu_metro/data/repositories/line_repository.dart';
import 'package:seu_metro/models/station.dart';

class StationRepository {
  final AssetLoader load;
  StationRepository({AssetLoader? load}) : load = load ?? defaultAssetLoader;

  Future<List<Station>> getAll() async {
    final raw = await load('assets/data/stations.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return (data['stations'] as List)
        .map((e) => Station.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, Station>> byId() async {
    final all = await getAll();
    return {for (final s in all) s.id: s};
  }
}
