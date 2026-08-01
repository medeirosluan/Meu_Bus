class Line {
  final String id;
  final String name;
  final int colorValue;
  final String operator;
  final String terminalA;
  final String terminalB;
  final List<String> stationIds;

  const Line({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.operator,
    required this.terminalA,
    required this.terminalB,
    required this.stationIds,
  });

  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: _parseHex(json['colorHex'] as String),
      operator: json['operator'] as String,
      terminalA: json['terminalA'] as String,
      terminalB: json['terminalB'] as String,
      stationIds: (json['stations'] as List<dynamic>).cast<String>(),
    );
  }

  static int _parseHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return int.parse('FF$cleaned', radix: 16);
  }
}
