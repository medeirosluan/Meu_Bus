import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/direto/direto_api_client.dart';

void main() {
  group('DiretoApiClient.parseStatusIds', () {
    test('converte ids numéricos', () {
      expect(
        DiretoApiClient.parseStatusIds([
          {'id': 3},
          {'id': 1},
        ]),
        [3, 1],
      );
    });

    test('lança FormatException para id não numérico', () {
      expect(
        () => DiretoApiClient.parseStatusIds([
          {'id': 'x'},
        ]),
        throwsFormatException,
      );
    });

    test('lança FormatException para entrada que não é um mapa', () {
      expect(
        () => DiretoApiClient.parseStatusIds(['nope']),
        throwsFormatException,
      );
    });
  });
}
