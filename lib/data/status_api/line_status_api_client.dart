import 'package:dio/dio.dart';
import 'package:seu_metro/models/line_status.dart';

class LineStatusApiClient {
  static const baseUrl =
      'https://apim-proximotrem-prd-brazilsouth-001.azure-api.net/api/v1';

  final Dio _dio;
  LineStatusApiClient({Dio? dio, int timeoutSeconds = 10})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: Duration(seconds: timeoutSeconds), receiveTimeout: Duration(seconds: timeoutSeconds)));

  Future<List<LineStatus>> fetchLines() async {
    final response = await _dio.get<Map<String, dynamic>>('/lines');
    final data = response.data?['Data'];
    if (data is! List) {
      throw const FormatException('Resposta inesperada da API de status');
    }
    return data.map((e) => LineStatus.fromJson(
        (e as Map<String, dynamic>)['Code'] as int, e)).toList();
  }
}
