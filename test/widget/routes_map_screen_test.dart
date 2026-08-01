import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/routes/route_map_screen.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/route.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/repositories.dart';

void main() {
  testWidgets('Mapa da rota mostra estações e baldeação', (tester) async {
    final plan = const RoutePlan(
      legs: [
        RouteLeg(lineId: '4', directionTerminal: 'Vila Sônia', fromStationId: 'luz', toStationId: 'pinheiros', stationCount: 7, minutes: 14),
        RouteLeg(lineId: '9', directionTerminal: 'Varginha', fromStationId: 'pinheiros', toStationId: 'santo_amaro', stationCount: 3, minutes: 6),
      ],
      totalMinutes: 23,
      transferStationNames: ['Pinheiros'],
    );
    const destination = Station(id: 'santo_amaro', name: 'Santo Amaro', lat: -23.65, lon: -46.71, lineIds: ['5', '9']);
    const lines = <String, Line>{
      '4': Line(id: '4', name: 'Linha 4 - Amarela', colorValue: 0xFFEFBA00, operator: 'metro', terminalA: 'Luz', terminalB: 'Vila Sônia', stationIds: ['luz', 'republica', 'higienopolis', 'paulista', 'oscar_freire', 'fradique', 'faria_lima', 'pinheiros']),
      '9': Line(id: '9', name: 'Linha 9 - Esmeralda', colorValue: 0xFF00AA80, operator: 'cptm', terminalA: 'Osasco', terminalB: 'Varginha', stationIds: ['pinheiros', 'morumbi', 'socorro', 'santo_amaro']),
    };
    final overrides = [stationsProvider.overrideWith((ref) async => const <Station>[
      Station(id: 'luz', name: 'Luz', lat: 0, lon: 0, lineIds: ['4']),
      Station(id: 'pinheiros', name: 'Pinheiros', lat: 0, lon: 0, lineIds: ['4', '9']),
      Station(id: 'santo_amaro', name: 'Santo Amaro', lat: 0, lon: 0, lineIds: ['5', '9']),
    ])];
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: RouteMapScreen(plan: plan, lines: lines, destination: destination)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Mapa da rota'), findsOneWidget);
    expect(find.text('Luz'), findsOneWidget);
    expect(find.text('Pinheiros'), findsOneWidget);
    expect(find.text('Santo Amaro'), findsOneWidget);
    expect(find.text('Baldear'), findsOneWidget);
  });
}
