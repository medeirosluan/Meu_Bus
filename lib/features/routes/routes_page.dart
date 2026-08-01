import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/route.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/repositories.dart';

import 'route_result_card.dart';
import 'station_picker.dart';

class RoutesPage extends ConsumerStatefulWidget {
  const RoutesPage({super.key});

  @override
  ConsumerState<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends ConsumerState<RoutesPage> {
  Station? _origin;
  Station? _destination;
  RoutePlan? _plan;
  bool _noRoute = false;

  void _calculate() {
    final origin = _origin;
    final destination = _destination;
    if (origin == null || destination == null) return;
    final graph = ref.read(metroGraphProvider).value;
    if (graph == null) return;
    final plan = graph.plan(origin.id, destination.id);
    setState(() {
      _plan = plan;
      _noRoute = plan == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(linesProvider).value ?? const <String, Line>{};
    ref.watch(metroGraphProvider);
    final prefillOrigin = ref.watch(selectedRouteOriginProvider);
    if (prefillOrigin != null) {
      _origin = prefillOrigin;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedRouteOriginProvider.notifier).state = null;
        }
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Rotas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            StationPicker(
              label: 'Origem',
              suggestionsFirst: true,
              initialValue: prefillOrigin,
              onSelected: (station) => setState(() => _origin = station),
            ),
            const SizedBox(height: 16),
            StationPicker(
              label: 'Destino',
              onSelected: (station) => setState(() => _destination = station),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _calculate,
              child: const Text('Calcular rota'),
            ),
            const SizedBox(height: 16),
            if (_plan != null) ..._buildPlan(_plan!, lines),
            if (_noRoute)
              const Text('Não há rota disponível entre essas estações.'),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlan(RoutePlan plan, Map<String, Line> lines) {
    return [
      Text(
        '${plan.totalMinutes} min no total',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      for (final leg in plan.legs)
        RouteResultCard(leg: leg, line: lines[leg.lineId]),
      const SizedBox(height: 8),
      for (final station in plan.transferStationNames)
        Text('Baldear em $station'),
    ];
  }
}
