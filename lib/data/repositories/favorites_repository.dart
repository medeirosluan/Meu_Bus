import 'package:shared_preferences/shared_preferences.dart';

class FavoritesRepository {
  static const _key = 'favorites_station_ids';

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<bool> isFavorite(String stationId) async {
    return (await getFavorites()).contains(stationId);
  }

  Future<void> toggle(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    if (current.contains(stationId)) {
      await prefs.setStringList(_key, current.where((id) => id != stationId).toList());
    } else {
      await prefs.setStringList(_key, [...current, stationId]);
    }
  }
}
