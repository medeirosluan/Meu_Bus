import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/route.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/repositories.dart';
import 'package:seu_metro/theme/line_colors.dart';

class RouteMapScreen extends ConsumerWidget {
  const RouteMapScreen({
    super.key,
    required this.plan,
    required this.lines,
    required this.destination,
  });

  final RoutePlan plan;
  final Map<String, Line> lines;
  final Station destination;

  List<Station?> _legStations(RouteLeg leg, List<Station> stations) {
    final line = lines[leg.lineId];
    if (line == null) return const [];
    final ids = line.stationIds;
    final iFrom = ids.indexOf(leg.fromStationId);
    final iTo = ids.indexOf(leg.toStationId);
    if (iFrom < 0 || iTo < 0) return const [];
    final start = iFrom < iTo ? iFrom : iTo;
    final end = iFrom < iTo ? iTo : iFrom;
    final sub = ids.sublist(start, end + 1);
    final ordered = iFrom < iTo ? sub : sub.reversed.toList();
    return [for (final id in ordered) _find(stations, id)];
  }

  Station? _find(List<Station> stations, String id) {
    for (final s in stations) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(stationsProvider).value ?? const <Station>[];
    final seen = <String>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa da rota')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final leg in plan.legs) ...[
            if (leg != plan.legs.first)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text('Sentido ${leg.directionTerminal}',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            for (final station in _legStations(leg, stations))
              if (station != null && seen.add(station.id))
                _StationRow(
                  station: station,
                  lineIds: station.lineIds,
                  isFirst: station.id == plan.legs.first.fromStationId,
                  isLast: station.id == destination.id,
                  isTransfer: plan.transferStationNames.contains(station.name),
                ),
          ],
        ],
      ),
    );
  }
}

class _StationRow extends StatelessWidget {
  const _StationRow({
    required this.station,
    required this.lineIds,
    required this.isFirst,
    required this.isLast,
    required this.isTransfer,
  });

  final Station station;
  final List<String> lineIds;
  final bool isFirst;
  final bool isLast;
  final bool isTransfer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (final lineId in lineIds)
            Container(
              margin: const EdgeInsets.only(right: 4),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(LineColors.colorFor(lineId)),
              ),
              child: Center(
                child: Text(
                  'L$lineId',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              station.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (isTransfer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00378C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Baldear', style: TextStyle(color: Colors.white, fontSize: 11)),
            )
          else if (isFirst)
            const Text('Embarque', style: TextStyle(fontSize: 11, color: Color(0xFF1E8E3E)))
          else if (isLast)
            const Text('Desembarque', style: TextStyle(fontSize: 11, color: Color(0xFFD93025))),
        ],
      ),
    );
  }
}
