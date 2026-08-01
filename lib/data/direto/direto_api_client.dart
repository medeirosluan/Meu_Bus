import 'package:dio/dio.dart';
import 'package:seu_metro/config/api_config.dart';
import 'package:seu_metro/models/direto_status.dart';

class DiretoApiClient {
  static const baseUrl = 'https://a.diretodostrens.com.br';

  final Dio _dio;
  final String token;

  DiretoApiClient({
    Dio? dio,
    this.token = ApiConfig.diretoToken,
    int timeoutSeconds = 10,
  }) : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: Duration(seconds: timeoutSeconds),
              receiveTimeout: Duration(seconds: timeoutSeconds),
            ));

  Future<dynamic> _get(String path) async {
    final query = token.isEmpty ? null : {'token': token};
    final response = await _dio.get<dynamic>(path, queryParameters: query);
    return response.data;
  }

  List<dynamic> _expectList(dynamic data) {
    if (data is! List) {
      throw const FormatException('Resposta inesperada da API Direto dos Trens');
    }
    return data;
  }

  Future<List<DiretoStatus>> getLastStatuses() async {
    final data = _expectList(await _get('/status'));
    return data
        .map((e) => DiretoStatus.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<int>> getLineStatusIds(int linha, {int? ano}) async {
    final path =
        ano == null ? '/status/codigo/$linha' : '/status/codigo/$linha/$ano';
    return parseStatusIds(_expectList(await _get(path)));
  }

  static List<int> parseStatusIds(List<dynamic> data) {
    final ids = <int>[];
    for (final entry in data) {
      if (entry is! Map<String, dynamic> || entry['id'] is! num) {
        throw const FormatException('Resposta inesperada da API Direto dos Trens');
      }
      ids.add((entry['id'] as num).toInt());
    }
    return ids;
  }

  Future<DiretoStatus> getStatusById(int id) async {
    final data = await _get('/status/id/$id');
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Resposta inesperada da API Direto dos Trens');
    }
    return DiretoStatus.fromJson(data);
  }
}
