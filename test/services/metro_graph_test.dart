import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/services/pathfinding/metro_graph.dart';

Line _line(String id, List<String> stationIds) => Line(
      id: id, name: 'Linha $id', colorValue: 0xFF000000,
      operator: 'metro', terminalA: 'A', terminalB: 'B',
      stationIds: stationIds,
    );

Station _st(String id, List<String> lines) =>
    Station(id: id, name: id, lat: 0, lon: 0, lineIds: lines);

void main() {
  // Rota direta na linha 1: tucuruvi -> liberdade (mesma linha, sem baldeação)
  final line1 = _line('1', ['tucuruvi', 'santana', 'luz', 'se', 'liberdade']);
  final line2 = _line('2', ['luz', 'paraiso']);
  final stations = [
    _st('tucuruvi', ['1']),
    _st('santana', ['1']),
    _st('luz', ['1', '2']),
    _st('se', ['1']),
    _st('liberdade', ['1']),
    _st('paraiso', ['2']),
  ];

  test('rota direta sem baldeação gera uma única perna', () {
    final graph = MetroGraph.build([line1, line2], stations);
    final plan = graph.plan('tucuruvi', 'liberdade')!;
    expect(plan.legs.length, 1);
    expect(plan.legs.first.fromStationId, 'tucuruvi');
    expect(plan.legs.first.toStationId, 'liberdade');
    expect(plan.totalMinutes, 4 * 2); // 4 estações vizinhas percorridas
  });

  test('baldeação gera duas pernas e penaliza troca', () {
    final graph = MetroGraph.build([line1, line2], stations);
    final plan = graph.plan('tucuruvi', 'paraiso')!;
    expect(plan.legs.length, 2);
    expect(plan.legs.last.lineId, '2');
    expect(plan.transferStationNames, ['luz']);
    // Tempo exibível: 2 arestas na linha 1 (4 min) + 1 aresta na linha 2 (2 min) + 3 min de baldeação
    expect(plan.totalMinutes, 2 * 2 + 1 * 2 + 3);
  });

  test('rota com menos baldeações vence mesmo sendo mais lenta', () {
    final lineA = _line('A', ['x', 's1', 's2', 's3', 's4', 'y']);
    final lineB = _line('B', ['x', 't']);
    final lineC = _line('C', ['t', 'y']);
    final stations = [
      _st('x', ['A', 'B']),
      _st('s1', ['A']),
      _st('s2', ['A']),
      _st('s3', ['A']),
      _st('s4', ['A']),
      _st('t', ['B', 'C']),
      _st('y', ['A', 'C']),
    ];
    final graph = MetroGraph.build([lineA, lineB, lineC], stations);
    final plan = graph.plan('x', 'y')!;
    expect(plan.legs.length, 1);
    expect(plan.legs.first.lineId, 'A');
    expect(plan.transferStationNames, isEmpty);
    expect(plan.totalMinutes, 10);
  });

  test('origem igual ao destino retorna plano vazio', () {
    final graph = MetroGraph.build([line1, line2], stations);
    final plan = graph.plan('tucuruvi', 'tucuruvi')!;
    expect(plan.legs, isEmpty);
    expect(plan.totalMinutes, 0);
  });

  test('sem caminho retorna null', () {
    final isolated = _st('sozinho', ['9']);
    final graph = MetroGraph.build([line1, line2], stations + [isolated]);
    expect(graph.plan('sozinho', 'tucuruvi'), isNull);
  });

  test('directionTerminal aponta para o terminal no sentido da viagem', () {
    final graph = MetroGraph.build([line1, line2], stations);
    final plan = graph.plan('tucuruvi', 'liberdade')!;
    expect(plan.legs.first.directionTerminal, 'liberdade');
    final reverse = graph.plan('liberdade', 'tucuruvi')!;
    expect(reverse.legs.first.directionTerminal, 'tucuruvi');
  });

  test('integração: rota luz->santo_amaro passa por baldeação', () {
    final rawLines = File('assets/data/lines.json').readAsStringSync();
    final rawStations = File('assets/data/stations.json').readAsStringSync();
    final lines = (jsonDecode(rawLines)['lines'] as List)
        .map((e) => Line.fromJson(e as Map<String, dynamic>)).toList();
    final stations = (jsonDecode(rawStations)['stations'] as List)
        .map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
    final graph = MetroGraph.build(lines, stations);
    final plan = graph.plan('luz', 'santo_amaro');
    expect(plan, isNotNull);
    expect(plan!.totalMinutes, greaterThan(0));
  });

  test('integração: sentido tucuruvi->jabaquara aponta para Jabaquara', () {
    final rawLines = File('assets/data/lines.json').readAsStringSync();
    final rawStations = File('assets/data/stations.json').readAsStringSync();
    final lines = (jsonDecode(rawLines)['lines'] as List)
        .map((e) => Line.fromJson(e as Map<String, dynamic>)).toList();
    final stations = (jsonDecode(rawStations)['stations'] as List)
        .map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
    final graph = MetroGraph.build(lines, stations);
    final plan = graph.plan('tucuruvi', 'jabaquara')!;
    expect(plan.legs.first.directionTerminal, 'Jabaquara');
  });
}
