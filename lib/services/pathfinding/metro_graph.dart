import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/route.dart';
import 'package:seu_metro/models/station.dart';

class _Edge {
  final String toNode;
  final int cost;
  final bool isTransfer;
  final String lineId;
  _Edge(this.toNode, this.cost, this.isTransfer, this.lineId);
}

class _PriorityQueue {
  final List<(String, int)> _heap = [];
  bool get isEmpty => _heap.isEmpty;
  void add(String node, int dist) {
    _heap.add((node, dist));
    var i = _heap.length - 1;
    while (i > 0) {
      final p = (i - 1) ~/ 2;
      if (_heap[p].$2 <= _heap[i].$2) break;
      final t = _heap[p];
      _heap[p] = _heap[i];
      _heap[i] = t;
      i = p;
    }
  }

  (String, int) removeMin() {
    final top = _heap[0];
    final last = _heap.removeLast();
    if (_heap.isEmpty) return top;
    _heap[0] = last;
    var i = 0;
    while (true) {
      final l = 2 * i + 1;
      final r = 2 * i + 2;
      var m = i;
      if (l < _heap.length && _heap[l].$2 < _heap[m].$2) m = l;
      if (r < _heap.length && _heap[r].$2 < _heap[m].$2) m = r;
      if (m == i) break;
      final t = _heap[m];
      _heap[m] = _heap[i];
      _heap[i] = t;
      i = m;
    }
    return top;
  }
}

class MetroGraph {
  static const transferPenalty = 1000;
  static const minutePerStation = 2;
  static const displayTransferMinutes = 3;

  final Map<String, List<_Edge>> _adjacency = {};
  final Map<String, Station> _stations;
  final Map<String, Line> _lines;

  MetroGraph.build(List<Line> lines, List<Station> stations)
      : _stations = {for (final s in stations) s.id: s},
        _lines = {for (final l in lines) l.id: l} {
    String nodeId(String stationId, String lineId) => '$stationId|$lineId';

    for (final station in stations) {
      for (final lineId in station.lineIds) {
        _adjacency.putIfAbsent(nodeId(station.id, lineId), () => []);
      }
    }

    for (final line in lines) {
      final ordered = line.stationIds;
      for (var i = 0; i < ordered.length - 1; i++) {
        final a = nodeId(ordered[i], line.id);
        final b = nodeId(ordered[i + 1], line.id);
        _adjacency[a]!.add(_Edge(b, minutePerStation, false, line.id));
        _adjacency[b]!.add(_Edge(a, minutePerStation, false, line.id));
      }
    }

    for (final station in stations) {
      final lines = station.lineIds;
      for (var i = 0; i < lines.length; i++) {
        for (var j = i + 1; j < lines.length; j++) {
          final a = nodeId(station.id, lines[i]);
          final b = nodeId(station.id, lines[j]);
          _adjacency[a]!.add(_Edge(b, transferPenalty, true, lines[j]));
          _adjacency[b]!.add(_Edge(a, transferPenalty, true, lines[i]));
        }
      }
    }
  }

  RoutePlan? plan(String fromId, String toId) {
    if (fromId == toId) {
      return const RoutePlan(legs: [], totalMinutes: 0, transferStationNames: []);
    }
    final fromStation = _stations[fromId];
    final toStation = _stations[toId];
    if (fromStation == null || toStation == null) return null;

    final starts = fromStation.lineIds.map((l) => '$fromId|$l').toList();
    final ends = toStation.lineIds.map((l) => '$toId|$l').toSet();

    final dist = <String, int>{};
    final prev = <String, String>{};
    final edgeOf = <String, _Edge>{};
    final pq = _PriorityQueue();
    for (final s in starts) {
      dist[s] = 0;
      pq.add(s, 0);
    }
    String? goal;
    while (!pq.isEmpty) {
      final entry = pq.removeMin();
      final current = entry.$1;
      final d = entry.$2;
      if (d != dist[current]) continue;
      if (ends.contains(current)) {
        goal = current;
        break;
      }
      for (final e in _adjacency[current] ?? const <_Edge>[]) {
        final nd = d + e.cost;
        if (nd < (dist[e.toNode] ?? 1 << 30)) {
          dist[e.toNode] = nd;
          prev[e.toNode] = current;
          edgeOf[e.toNode] = e;
          pq.add(e.toNode, nd);
        }
      }
    }
    if (goal == null) return null;
    return _reconstruct(goal, prev, edgeOf);
  }

  RoutePlan _reconstruct(String goal, Map<String, String> prev,
      Map<String, _Edge> edgeOf) {
    var nodeIds = <String>[];
    var node = goal;
    while (true) {
      nodeIds.add(node);
      final parent = prev[node];
      if (parent == null) break;
      node = parent;
    }
    nodeIds = nodeIds.reversed.toList();

    final legs = <RouteLeg>[];
    final transfers = <String>{};
    final k = nodeIds.length - 1;
    String curLine = edgeOf[nodeIds[1]]!.lineId;
    int legStart = 0;
    for (var i = 1; i <= k; i++) {
      final e = edgeOf[nodeIds[i]]!;
      if (e.isTransfer) {
        _closeLeg(legs, nodeIds, legStart, i, curLine);
        transfers.add(_stations[nodeIds[i].split('|').first]!.name);
        legStart = i;
        curLine = e.lineId;
      } else if (e.lineId != curLine) {
        _closeLeg(legs, nodeIds, legStart, i, curLine);
        transfers.add(_stations[nodeIds[i - 1].split('|').first]!.name);
        legStart = i - 1;
        curLine = e.lineId;
      }
    }
    if (legStart <= k) {
      _closeLeg(legs, nodeIds, legStart, k + 1, curLine);
    }
    final displayMinutes = legs.isEmpty
        ? 0
        : legs.fold(0, (acc, l) => acc + l.minutes) +
            displayTransferMinutes * (legs.length - 1);
    return RoutePlan(
      legs: legs,
      totalMinutes: displayMinutes,
      transferStationNames: transfers.toList(),
    );
  }

  void _closeLeg(List<RouteLeg> legs, List<String> nodeIds, int start, int end, String lineId) {
    if (end <= start) return;
    final line = _lines[lineId]!;
    final from = _stations[nodeIds[start].split('|').first]!;
    final to = _stations[nodeIds[end - 1].split('|').first]!;
    final fromIdx = line.stationIds.indexOf(from.id);
    final toIdx = line.stationIds.indexOf(to.id);
    final dirId = toIdx > fromIdx ? line.stationIds.last : line.stationIds.first;
    final direction = _stations[dirId]!.name;
    legs.add(RouteLeg(
      lineId: lineId,
      directionTerminal: direction,
      fromStationId: from.id,
      toStationId: to.id,
      stationCount: end - 1 - start,
      minutes: (end - 1 - start) * minutePerStation,
    ));
  }
}
