import 'package:flutter/material.dart';
import 'package:seu_metro/config/fares.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/route.dart';
import 'package:seu_metro/models/station.dart';

import 'route_map_screen.dart';

class RouteResultScreen extends StatelessWidget {
  const RouteResultScreen({
    super.key,
    required this.plan,
    required this.destination,
    required this.lines,
  });

  final RoutePlan plan;
  final Station destination;
  final Map<String, Line> lines;

  @override
  Widget build(BuildContext context) {
    final arrival = DateTime.now().add(Duration(minutes: plan.totalMinutes));
    final arrivalLabel = '${arrival.hour.toString().padLeft(2, '0')}:'
        '${arrival.minute.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: const Text('Melhor trajeto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Como chegar em ${destination.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _summaryCard(context, Icons.timer_outlined, 'Previsão', '~${plan.totalMinutes} min'),
          _summaryCard(context, Icons.payments_outlined, 'Valor da viagem', AppFares.formatReais(AppFares.metroCents)),
          _summaryCard(context, Icons.swap_horiz, 'Baldeações', _transfersLabel(plan.transferStationNames.length)),
          _summaryCard(context, Icons.schedule_outlined, 'Previsão de chegada', arrivalLabel),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RouteMapScreen(plan: plan, lines: lines, destination: destination),
              ),
            ),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Detalhe do trajeto'),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context, IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(value,
            style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }

  String _transfersLabel(int count) {
    if (count == 1) return '1 baldeação';
    return '$count baldeações';
  }
}
