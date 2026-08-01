import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/config/api_config.dart';
import 'package:seu_metro/data/direto/direto_api_client.dart';
import 'package:seu_metro/data/repositories/direto_status_repository.dart';
import 'package:seu_metro/models/direto_status.dart';

final diretoStatusRepositoryProvider = Provider<DiretoStatusRepository>(
    (ref) => DiretoStatusRepository(client: DiretoApiClient()));

final diretoTokenConfiguredProvider =
    Provider<bool>((ref) => ApiConfig.diretoToken.isNotEmpty);

final historyProvider =
    FutureProvider.family<List<DiretoStatus>, ({int linha, int ano})>(
  (ref, arg) => ref
      .watch(diretoStatusRepositoryProvider)
      .getHistory(arg.linha, arg.ano),
);
