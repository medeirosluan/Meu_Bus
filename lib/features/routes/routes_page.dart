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
  bool _sameStation = false;

  void _calculate() {
    final origin = _origin;
    final destination = _destination;
    if (origin == null || destination == null) return;
    final graph = ref.read(metroGraphProvider).value;
    if (graph == null) return;
    if (origin.id == destination.id) {
      setState(() {
        _plan = null;
        _noRoute = false;
        _sameStation = true;
      });
      return;
    }
    final plan = graph.plan(origin.id, destination.id);
    setState(() {
      _plan = plan;
      _noRoute = plan == null;
      _sameStation = false;
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
              child: const Text('Busca rota'),
            ),
            const SizedBox(height: 16),
            if (_sameStation)
              const Text('Origem e destino são a mesma estação.'),
            if (_plan != null) ..._buildPlan(_plan!, lines),
            if (_noRoute)
              const Text('Não há rota disponível entre essas estações.'),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlan(RoutePlan plan, Map<String, Line> lines) {
    final destination = _destination;
    final header = destination == null
        ? 'Como chegar no destino'
        : 'Como chegar em ${destination.name}';
    final transferCount = plan.transferStationNames.length;
    final resumo =
        'Rota com $transferCount baldeação(ões) · ~${plan.totalMinutes} min';
    return [
      Text(header, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(resumo, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      if (plan.legs.isNotEmpty) ...[
        _guideStep(
          'Pegue a ${_lineName(plan.legs.first, lines)} no sentido '
          '${plan.legs.first.directionTerminal}',
        ),
        for (var i = 0; i < plan.transferStationNames.length; i++)
          _guideStep(
            'Baldear para a ${_lineName(plan.legs[i + 1], lines)} em '
            '${plan.transferStationNames[i]}',
          ),
        _guideStep(
          'Desça em ${destination?.name ?? plan.legs.last.toStationId}',
        ),
      ],
      const SizedBox(height: 12),
      for (final leg in plan.legs)
        RouteResultCard(leg: leg, line: lines[leg.lineId]),
    ];
  }

  String _lineName(RouteLeg leg, Map<String, Line> lines) =>
      lines[leg.lineId]?.name ?? 'Linha ${leg.lineId}';

  Widget _guideStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.directions_subway, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
