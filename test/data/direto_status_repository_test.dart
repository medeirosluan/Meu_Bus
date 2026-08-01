import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/direto/direto_api_client.dart';
import 'package:seu_metro/data/repositories/direto_status_repository.dart';
import 'package:seu_metro/models/direto_status.dart';

DiretoStatus _st(int id, DateTime criado) => DiretoStatus(
      codigo: 1, situacao: 'S', descricao: null, criado: criado,
      modificado: null, id: id,
    );

class _FakeClient implements DiretoApiClient {
  int detailCalls = 0;
  @override
  String get token => 'fake';
  @override
  Future<List<DiretoStatus>> getLastStatuses() async => [];
  @override
  Future<List<int>> getLineStatusIds(int linha, {int? ano}) async => [3, 1, 2];
  @override
  Future<DiretoStatus> getStatusById(int id) async {
    detailCalls++;
    return _st(id, DateTime.utc(2026, 7, id));
  }
}

void main() {
  test('getHistory busca IDs, detalhes e ordena por criado decrescente', () async {
    final fake = _FakeClient();
    final repo = DiretoStatusRepository(client: fake);
    final history = await repo.getHistory(1, 2026);
    expect(history.map((s) => s.id).toList(), [3, 2, 1]);
    expect(fake.detailCalls, 3);
  });

  test('getHistory com lista vazia retorna lista vazia', () async {
    final fake = _EmptyClient();
    final repo = DiretoStatusRepository(client: fake);
    expect(await repo.getHistory(1, 2026), isEmpty);
  });
}

class _EmptyClient implements DiretoApiClient {
  @override
  String get token => '';
  @override
  Future<List<DiretoStatus>> getLastStatuses() async => [];
  @override
  Future<List<int>> getLineStatusIds(int linha, {int? ano}) async => [];
  @override
  Future<DiretoStatus> getStatusById(int id) async =>
      throw StateError('não deveria ser chamado');
}
