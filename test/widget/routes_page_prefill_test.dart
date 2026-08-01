import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/routes/routes_page.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/repositories.dart';

void main() {
  testWidgets('RoutesPage pré-preenche origem a partir do provider', (tester) async {
    const station = Station(
      id: 'luz',
      name: 'Luz',
      lat: -23.534,
      lon: -46.635,
      lineIds: ['1'],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(selectedRouteOriginProvider.notifier).state = station;

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: RoutesPage()),
    ));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Luz'), findsOneWidget);
    expect(container.read(selectedRouteOriginProvider), isNull);
  });
}
