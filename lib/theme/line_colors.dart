class LineColors {
  static const Map<String, int> official = {
    '1': 0xFF00378C, '2': 0xFF186D55, '3': 0xFFF51200, '4': 0xFFEFBA00,
    '5': 0xFF9271B1, '6': 0xFFF27C00, '7': 0xFFC80857, '8': 0xFF949488,
    '9': 0xFF00AA80, '10': 0xFF00998C, '11': 0xFFE33825, '12': 0xFF193E81,
    '13': 0xFF2D9F7E, '15': 0xFF9D968D, '17': 0xFFD0A238,
  };
  static const _fallback = 0xFF757575;
  static int colorFor(String lineId) => official[lineId] ?? _fallback;
}
