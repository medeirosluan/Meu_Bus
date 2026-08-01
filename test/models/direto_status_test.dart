import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/models/direto_status.dart';

void main() {
  test('DiretoStatus.fromJson parseia os campos', () {
    final status = DiretoStatus.fromJson({
      'codigo': 1,
      'situacao': 'Operação Reduzida',
      'descricao': 'Trens circulando com intervalos maiores',
      'criado': '2026-07-31T08:30:00Z',
      'modificado': '2026-07-31T09:00:00Z',
      'id': 42,
    });
    expect(status.codigo, 1);
    expect(status.situacao, 'Operação Reduzida');
    expect(status.descricao, 'Trens circulando com intervalos maiores');
    expect(status.criado.isUtc, isTrue);
    expect(status.modificado, isNotNull);
    expect(status.id, 42);
  });

  test('DiretoStatus.fromJson tolera descricao/modificado ausentes', () {
    final status = DiretoStatus.fromJson({
      'codigo': 2,
      'situacao': 'Operação Normal',
      'criado': '2026-07-31T10:00:00Z',
      'id': 7,
    });
    expect(status.descricao, isNull);
    expect(status.modificado, isNull);
  });
}
