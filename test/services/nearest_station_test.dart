import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/services/location/nearest_station.dart';

void main() {
  const stations = [
    Station(id: 'luz', name: 'Luz', lat: -23.534, lon: -46.635, lineIds: ['1']),
    Station(id: 'se', name: 'Sé', lat: -23.550, lon: -46.633, lineIds: ['1']),
  ];

  test('nearestStation retorna a estação mais próxima', () {
    // Perto da Sé
    final result = nearestStation(stations, -23.549, -46.633);
    expect(result!.id, 'se');
  });

  test('distanceKm calcula ~1.8km entre Luz e Sé', () {
    final km = distanceKm(stations[0], stations[1].lat, stations[1].lon);
    expect(km, closeTo(1.8, 0.3));
  });

  test('lista vazia retorna null', () {
    expect(nearestStation(const [], -23.5, -46.6), isNull);
  });
}
