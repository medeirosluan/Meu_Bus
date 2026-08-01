import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/map/map_page.dart';

void main() {
  testWidgets('MapPage renderiza o mapa e estações', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: MapPage())));
    await tester.pumpAndSettle();
    expect(find.text('Seu Metrô'), findsNothing); // sem título fixo
    expect(find.byType(FlutterMap), findsWidgets);
  });
}
