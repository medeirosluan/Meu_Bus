import 'package:seu_metro/data/direto/direto_api_client.dart';
import 'package:seu_metro/models/direto_status.dart';

class DiretoStatusRepository {
  final DiretoApiClient client;

  DiretoStatusRepository({required this.client});

  Future<List<DiretoStatus>> getHistory(int linha, int ano) async {
    final ids = await client.getLineStatusIds(linha, ano: ano);
    final results = <DiretoStatus>[];
    for (var i = 0; i < ids.length; i += 4) {
      final batch = ids.skip(i).take(4);
      results.addAll(await Future.wait(batch.map(client.getStatusById)));
    }
    results.sort((a, b) => b.criado.compareTo(a.criado));
    return results;
  }
}
