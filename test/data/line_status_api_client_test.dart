import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/status_api/line_status_api_client.dart';

void main() {
  final live = !const bool.fromEnvironment('skipLiveApi');

  test('fetchLines parseia resposta da API real', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://apim-proximotrem-prd-brazilsouth-001.azure-api.net/api/v1'));
    final client = LineStatusApiClient(dio: dio);
    final statuses = await client.fetchLines();
    expect(statuses.length, greaterThanOrEqualTo(10));
    expect(statuses.every((s) => s.statusLabel.isNotEmpty), isTrue);
  }, skip: live ? false : 'API offline');

  test('fetchLines falha com erro de rede lança DioException', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:1'));
    final client = LineStatusApiClient(dio: dio, timeoutSeconds: 2);
    expect(client.fetchLines(), throwsA(isA<DioException>()));
  });
}
