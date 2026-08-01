import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/repositories/status_repository.dart';
import 'package:seu_metro/data/status_api/line_status_api_client.dart';
import 'package:seu_metro/models/line_status.dart';

class _FakeClient implements LineStatusApiClient {
  int calls = 0;
  bool failNext = false;
  @override
  Future<List<LineStatus>> fetchLines() async {
    calls++;
    if (failNext) throw Exception('offline');
    return [LineStatus(lineId: '1', statusCode: 'OperacaoNormal', statusLabel: 'Operação Normal', statusColor: 'verde', description: null, updatedAt: DateTime.now())];
  }
}

void main() {
  test('getStatuses busca na API e faz cache', () async {
    final fake = _FakeClient();
    final repo = StatusRepository(client: fake);
    final a = await repo.getStatuses();
    final b = await repo.getStatuses();
    expect(a.length, 1);
    expect(b.length, 1);
    expect(fake.calls, 1, reason: 'segunda chamada deve usar cache');
  });

  test('erro usa cache antigo', () async {
    final fake = _FakeClient();
    final repo = StatusRepository(client: fake, cacheDuration: const Duration(milliseconds: 1));
    await repo.getStatuses();
    fake.failNext = true;
    final result = await repo.getStatuses();
    expect(result.length, 1);
  });

  test('erro sem cache propaga', () async {
    final fake = _FakeClient()..failNext = true;
    final repo = StatusRepository(client: fake);
    expect(repo.getStatuses(), throwsA(isA<Exception>()));
  });

  test('falha ao buscar serve cache e marca isStale; sucesso reseta', () async {
    final fake = _FakeClient();
    final repo = StatusRepository(client: fake, cacheDuration: Duration.zero);
    await repo.getStatuses();
    expect(repo.isStale, isFalse);
    fake.failNext = true;
    final result = await repo.getStatuses();
    expect(result.length, 1);
    expect(repo.isStale, isTrue);
    fake.failNext = false;
    await repo.getStatuses();
    expect(repo.isStale, isFalse);
  });
}
