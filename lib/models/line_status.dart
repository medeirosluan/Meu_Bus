class LineStatus {
  final String lineId;
  final String statusCode;
  final String statusLabel;
  final String statusColor;
  final String? description;
  final DateTime updatedAt;

  const LineStatus({
    required this.lineId,
    required this.statusCode,
    required this.statusLabel,
    required this.statusColor,
    required this.description,
    required this.updatedAt,
  });

  factory LineStatus.fromJson(int code, Map<String, dynamic> json) {
    return LineStatus(
      lineId: '$code',
      statusCode: json['StatusCode'] as String? ?? 'unknown',
      statusLabel: json['StatusLabel'] as String? ?? 'Indisponível',
      statusColor: json['StatusColor'] as String? ?? 'cinza',
      description: json['Description'] as String?,
      updatedAt: DateTime.now(),
    );
  }
}
