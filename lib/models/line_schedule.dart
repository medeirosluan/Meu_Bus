class LineSchedule {
  final String lineId;
  final String direction;
  final String terminal;
  final String firstTrain;
  final String lastTrain;
  final int headwayPeakMin;
  final int headwayNormalMin;

  const LineSchedule({
    required this.lineId,
    required this.direction,
    required this.terminal,
    required this.firstTrain,
    required this.lastTrain,
    required this.headwayPeakMin,
    required this.headwayNormalMin,
  });

  factory LineSchedule.fromJson(Map<String, dynamic> json) {
    return LineSchedule(
      lineId: json['lineId'] as String,
      direction: json['direction'] as String,
      terminal: json['terminal'] as String,
      firstTrain: json['firstTrain'] as String,
      lastTrain: json['lastTrain'] as String,
      headwayPeakMin: json['headwayPeakMin'] as int,
      headwayNormalMin: json['headwayNormalMin'] as int,
    );
  }
}
