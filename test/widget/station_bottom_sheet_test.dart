import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/map/station_bottom_sheet.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/navigation.dart';
import 'package:seu_metro/providers/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bottom sheet navega para Horários e Rotas', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const station = Station(
      id: 'luz',
      name: 'Luz',
      lat: -23.534,
      lon: -46.635,
      lineIds: ['1'],
    );

    Future<void> openSheet() async {
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showStationSheet(context, station),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ));

    await openSheet();
    expect(find.text('Ver horários'), findsOneWidget);
    await tester.tap(find.text('Ver horários'));
    await tester.pumpAndSettle();
    expect(container.read(selectedTabProvider), 3);

    await openSheet();
    await tester.tap(find.text('Como chegar'));
    await tester.pumpAndSettle();
    expect(container.read(selectedTabProvider), 1);
    expect(container.read(selectedRouteOriginProvider), same(station));
  });
}
