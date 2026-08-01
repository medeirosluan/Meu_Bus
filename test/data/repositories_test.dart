import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/repositories/line_repository.dart';
import 'package:seu_metro/data/repositories/schedule_repository.dart';
import 'package:seu_metro/data/repositories/station_repository.dart';

Future<String> _diskLoader(String path) async => File(path).readAsStringSync();

void main() {
  test('LineRepository carrega 15 linhas', () async {
    final repo = LineRepository(load: _diskLoader);
    final lines = await repo.getAll();
    expect(lines.length, 15);
    expect(lines.any((l) => l.id == '1'), isTrue);
  });

  test('StationRepository carrega 166 estações e byId funciona', () async {
    final repo = StationRepository(load: _diskLoader);
    final stations = await repo.getAll();
    expect(stations.length, 166);
    final byId = await repo.byId();
    expect(byId['paraiso']!.lineIds, contains('1'));
  });

  test('ScheduleRepository carrega 30 horários', () async {
    final repo = ScheduleRepository(load: _diskLoader);
    final scheds = await repo.getAll();
    expect(scheds.length, 30);
  });
}
