import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/data/repositories/status_repository.dart';
import 'package:seu_metro/data/status_api/line_status_api_client.dart';
import 'package:seu_metro/models/line_status.dart';

class StatusSnapshot {
  final List<LineStatus> data;
  final DateTime updatedAt;
  final bool isStale;
  const StatusSnapshot({
    required this.data,
    required this.updatedAt,
    required this.isStale,
  });
}

final statusRepositoryProvider =
    Provider<StatusRepository>((ref) => StatusRepository(client: LineStatusApiClient()));

final statusProvider = FutureProvider<StatusSnapshot>((ref) async {
  final repo = ref.watch(statusRepositoryProvider);
  try {
    final data = await repo.getStatuses();
    return StatusSnapshot(
      data: data,
      updatedAt: repo.lastFetched ?? DateTime.now(),
      isStale: false,
    );
  } catch (_) {
    final cached = repo.cache;
    if (cached != null) {
      return StatusSnapshot(
        data: cached,
        updatedAt: repo.lastFetched ?? DateTime.now(),
        isStale: true,
      );
    }
    rethrow;
  }
});
