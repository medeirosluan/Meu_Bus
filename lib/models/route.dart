class RouteLeg {
  final String lineId;
  final String directionTerminal;
  final String fromStationId;
  final String toStationId;
  final int stationCount;
  final int minutes;

  const RouteLeg({
    required this.lineId,
    required this.directionTerminal,
    required this.fromStationId,
    required this.toStationId,
    required this.stationCount,
    required this.minutes,
  });
}

class RoutePlan {
  final List<RouteLeg> legs;
  final int totalMinutes;
  final List<String> transferStationNames;

  const RoutePlan({
    required this.legs,
    required this.totalMinutes,
    required this.transferStationNames,
  });
}
