import 'dart:convert';

import 'package:seu_metro/data/repositories/line_repository.dart';
import 'package:seu_metro/models/line_schedule.dart';

class ScheduleRepository {
  final AssetLoader load;
  ScheduleRepository({AssetLoader? load}) : load = load ?? defaultAssetLoader;

  Future<List<LineSchedule>> getAll() async {
    final raw = await load('assets/data/schedules.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return (data['schedules'] as List)
        .map((e) => LineSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
