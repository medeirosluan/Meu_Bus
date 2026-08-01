import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/repositories.dart';

import 'route_result_screen.dart';
import 'station_picker.dart';

class RoutesPage extends ConsumerStatefulWidget {
  const RoutesPage({super.key});

  @override
  ConsumerState<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends ConsumerState<RoutesPage> {
  Station? _origin;
  Station? _destination;
  bool _noRoute = false;
  bool _sameStation = false;

  void _calculate() {
    final origin = _origin;
    final destination = _destination;
    if (origin == null || destination == null) return;
    final graph = ref.read(metroGraphProvider).value;
    if (graph == null) return;
    if (origin.id == destination.id) {
      setState(() => _sameStation = true);
      return;
    }
    final plan = graph.plan(origin.id, destination.id);
    if (plan == null) {
      setState(() => _noRoute = true);
      return;
    }
    setState(() {
      _noRoute = false;
      _sameStation = false;
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteResultScreen(
          plan: plan,
          destination: destination,
          lines: ref.read(linesProvider).value ?? const <String, Line>{},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            StationPicker(
              label: 'Origem',
              suggestionsFirst: true,
              initialValue: prefillOrigin,
              prefixIcon: const Icon(Icons.circle, color: Color(0xFF1E8E3E), size: 16),
              onSelected: (station) => setState(() => _origin = station),
            ),
            const SizedBox(height: 16),
            StationPicker(
              label: 'Destino',
              prefixIcon: const Icon(Icons.circle, color: Color(0xFFD93025), size: 16),
              onSelected: (station) => setState(() => _destination = station),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (_origin != null && _destination != null) ? _calculate : null,
              icon: const Icon(Icons.search),
              label: const Text('Busca rota'),
            ),
            const SizedBox(height: 16),
            if (_sameStation)
              const Text('Origem e destino são a mesma estação.'),
            if (_noRoute)
              const Text('Não há rota disponível entre essas estações.'),
          ],
        ),
      ),
    );
  }

}
