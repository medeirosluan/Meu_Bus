import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/config/fares.dart';
import 'package:seu_metro/features/routes/route_result_screen.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/route.dart';
import 'package:seu_metro/models/station.dart';

void main() {
  test('formatReais formata centavos', () {
    expect(AppFares.formatReais(520), 'R\$ 5,20');
  });

  testWidgets('tela de resultado mostra resumo do trajeto', (tester) async {
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
      '4': Line(id: '4', name: 'Linha 4 - Amarela', colorValue: 0xFFEFBA00, operator: 'metro', terminalA: 'Luz', terminalB: 'Vila Sônia', stationIds: ['luz']),
      '9': Line(id: '9', name: 'Linha 9 - Esmeralda', colorValue: 0xFF00AA80, operator: 'cptm', terminalA: 'Osasco', terminalB: 'Varginha', stationIds: ['pinheiros']),
    };
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: RouteResultScreen(plan: plan, destination: destination, lines: lines)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('~23 min'), findsOneWidget);
    expect(find.text('R\$ 5,20'), findsOneWidget);
    expect(find.text('1 baldeação'), findsOneWidget);
    expect(find.textContaining('Detalhe do trajeto'), findsOneWidget);
  });
}
