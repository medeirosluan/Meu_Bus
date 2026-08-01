import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seu_metro/features/map/map_page.dart';

class _FakeGeolocator extends GeolocatorPlatform {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    throw Exception('localização indisponível');
  }
}

void main() {
  testWidgets('MapPage mostra SnackBar quando a localização falha', (tester) async {
    final original = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = _FakeGeolocator();
    addTearDown(() => GeolocatorPlatform.instance = original);

    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: MapPage())));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Não foi possível obter sua localização.'), findsOneWidget);
  });
}
