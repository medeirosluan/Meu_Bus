import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/line_schedule.dart';
import 'package:seu_metro/models/line_status.dart';
import 'package:seu_metro/models/station.dart';

void main() {
  test('Line.fromJson parseia os campos', () {
    final line = Line.fromJson({
      'id': '1', 'name': 'Linha 1 - Azul', 'colorHex': '#00378c',
      'operator': 'metro', 'terminalA': 'Jabaquara', 'terminalB': 'Tucuruvi',
      'stations': ['jabaquara', 'conceicao', 'tucuruvi'],
    });
    expect(line.id, '1');
    expect(line.name, 'Linha 1 - Azul');
    expect(line.colorValue, 0xFF00378C);
    expect(line.operator, 'metro');
    expect(line.terminalA, 'Jabaquara');
    expect(line.stationIds, ['jabaquara', 'conceicao', 'tucuruvi']);
  });

  test('Station.fromJson parseia os campos', () {
    final station = Station.fromJson({
      'id': 'paraiso', 'name': 'Paraíso', 'lat': -23.574, 'lon': -46.642,
      'lines': ['1', '2'],
    });
    expect(station.id, 'paraiso');
    expect(station.lineIds, ['1', '2']);
  });

  test('LineStatus.fromJson mapeia StatusColor', () {
    final status = LineStatus.fromJson(1, {
      'Code': 1, 'StatusLabel': 'Operação Normal', 'StatusCode': 'OperacaoNormal',
      'StatusColor': 'verde', 'Description': null,
    });
    expect(status.statusCode, 'OperacaoNormal');
    expect(status.statusColor, 'verde');
  });

  test('LineSchedule.fromJson parseia horários', () {
    final sched = LineSchedule.fromJson({
      'lineId': '1', 'direction': 'A', 'terminal': 'Jabaquara',
      'firstTrain': '04:40', 'lastTrain': '00:29',
      'headwayPeakMin': 2, 'headwayNormalMin': 6,
    });
    expect(sched.firstTrain, '04:40');
    expect(sched.headwayPeakMin, 2);
  });
}
