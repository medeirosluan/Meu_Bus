import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/line_schedule.dart';
import 'package:seu_metro/models/station.dart';

Map<String, dynamic> _load(String name) {
  final raw = File('assets/data/$name').readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

void main() {
  test('lines.json tem 15 linhas e ids únicos', () {
    final lines = (_load('lines.json')['lines'] as List)
        .map((e) => Line.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(lines.length, 15);
    expect(lines.map((l) => l.id).toSet().length, 15);
  });

  test('stations.json tem 166 estações com ids únicos', () {
    final stations = (_load('stations.json')['stations'] as List)
        .map((e) => Station.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(stations.length, 166);
    expect(stations.map((s) => s.id).toSet().length, 166);
  });

  test('stations.json: cada lineId referenciada existe em lines.json', () {
    final lineIds = (_load('lines.json')['lines'] as List)
        .map((e) => (e as Map<String, dynamic>)['id'] as String)
        .toSet();
    final stations = (_load('stations.json')['stations'] as List)
        .map((e) => Station.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final s in stations) {
      for (final l in s.lineIds) {
        expect(lineIds.contains(l), isTrue,
            reason: 'estação ${s.name} referencia linha inexistente $l');
      }
    }
  });

  test('stations.json: cada estação tem ao menos uma linha', () {
    final stations = (_load('stations.json')['stations'] as List)
        .map((e) => Station.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final s in stations) {
      expect(s.lineIds.isNotEmpty, isTrue, reason: '${s.name} sem linha');
    }
  });

  test('lines.json: stationIds existem e batem com lines das estações', () {
    final rawLines = _load('lines.json')['lines'] as List;
    final rawStations = _load('stations.json')['stations'] as List;
    final lines = rawLines.map((e) => Line.fromJson(e as Map<String, dynamic>)).toList();
    final stations = rawStations.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
    final byId = {for (final s in stations) s.id: s};
    for (final line in lines) {
      for (final sid in line.stationIds) {
        final station = byId[sid];
        expect(station, isNotNull, reason: 'linha ${line.id} referencia estação inexistente $sid');
        expect(station!.lineIds, contains(line.id),
            reason: 'estação $sid não marca a linha ${line.id}');
      }
    }
  });

  test('schedules.json: 2 horários por linha e campos válidos', () {
    final scheds = (_load('schedules.json')['schedules'] as List)
        .map((e) => LineSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(scheds.length, 30);
    expect(scheds.where((s) => s.lineId == '1').length, 2);
    for (final s in scheds) {
      expect(s.firstTrain, matches(RegExp(r'^\d{2}:\d{2}$')));
      expect(s.lastTrain, matches(RegExp(r'^\d{2}:\d{2}$')));
    }
  });
}
