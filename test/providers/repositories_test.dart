import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/providers/repositories.dart';
import 'package:seu_metro/theme/line_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('stationsProvider carrega estações', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final stations = await container.read(stationsProvider.future);
    expect(stations.length, greaterThanOrEqualTo(100));
  });

  test('metroGraphProvider monta grafo conectado', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final graph = await container.read(metroGraphProvider.future);
    expect(graph.plan('luz', 'santo_amaro'), isNotNull);
  });

  test('LineColors retorna cor oficial da linha 1', () {
    expect(LineColors.colorFor('1'), 0xFF00378C);
  });
}
