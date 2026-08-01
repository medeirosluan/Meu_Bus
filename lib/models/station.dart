class Station {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final List<String> lineIds;

  const Station({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.lineIds,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      lineIds: (json['lines'] as List<dynamic>).cast<String>(),
    );
  }
}
