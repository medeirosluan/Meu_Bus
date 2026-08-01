import 'dart:math';

import 'package:seu_metro/models/station.dart';

const _earthRadiusKm = 6371.0;

double distanceKm(Station station, double lat, double lon) {
  const p = pi / 180;
  final dLat = (lat - station.lat) * p;
  final dLon = (lon - station.lon) * p;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(station.lat * p) * cos(lat * p) *
          sin(dLon / 2) * sin(dLon / 2);
  return 2 * _earthRadiusKm * atan2(sqrt(a), sqrt(1 - a));
}

Station? nearestStation(List<Station> stations, double lat, double lon) {
  Station? best;
  var bestKm = double.infinity;
  for (final s in stations) {
    final km = distanceKm(s, lat, lon);
    if (km < bestKm) {
      bestKm = km;
      best = s;
    }
  }
  return best;
}
