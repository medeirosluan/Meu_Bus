import 'package:seu_metro/data/status_api/line_status_api_client.dart';
import 'package:seu_metro/models/line_status.dart';

class StatusRepository {
  final LineStatusApiClient client;
  final Duration cacheDuration;
  List<LineStatus>? _cache;
  DateTime? _lastFetched;
  bool _isStale = false;

  StatusRepository({required this.client, this.cacheDuration = const Duration(minutes: 5)});

  List<LineStatus>? get cache => _cache;
  DateTime? get lastFetched => _lastFetched;
  bool get isStale => _isStale;

  Future<List<LineStatus>> getStatuses() async {
    final cache = _cache;
    final last = _lastFetched;
    if (cache != null && last != null && DateTime.now().difference(last) < cacheDuration) {
      return cache;
    }
    try {
      final fresh = await client.fetchLines();
      _cache = fresh;
      _lastFetched = DateTime.now();
      _isStale = false;
      return fresh;
    } catch (_) {
      if (cache != null) {
        _isStale = true;
        return cache;
      }
      rethrow;
    }
  }
}
