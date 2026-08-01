import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/repositories/status_repository.dart';
import 'package:seu_metro/data/status_api/line_status_api_client.dart';
import 'package:seu_metro/models/line_status.dart';
import 'package:seu_metro/providers/status_provider.dart';

class _FakeClient implements LineStatusApiClient {
  bool failNext = false;
  @override
  Future<List<LineStatus>> fetchLines() async {
    if (failNext) throw Exception('offline');
    return [
      LineStatus(
        lineId: '1',
        statusCode: 'OperacaoNormal',
        statusLabel: 'Operação Normal',
        statusColor: 'verde',
        description: null,
        updatedAt: DateTime.now(),
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('statusProvider marca snapshot stale quando fetch falha com cache', () async {
    final fake = _FakeClient();
    final repo = StatusRepository(client: fake, cacheDuration: Duration.zero);
    final container = ProviderContainer(overrides: [
      statusRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final first = await container.read(statusProvider.future);
    expect(first.isStale, isFalse);

    fake.failNext = true;
    container.invalidate(statusProvider);
    final snapshot = await container.read(statusProvider.future);
    expect(snapshot.isStale, isTrue);
    expect(snapshot.data.length, 1);
  });
}
