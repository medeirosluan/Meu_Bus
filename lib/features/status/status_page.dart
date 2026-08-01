import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/line_status.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/navigation.dart';
import 'package:seu_metro/providers/repositories.dart';
import 'package:seu_metro/providers/status_provider.dart';
import 'package:seu_metro/services/location/nearest_station.dart';
import 'package:seu_metro/theme/line_colors.dart';

class StatusPage extends ConsumerStatefulWidget {
  const StatusPage({super.key});

  @override
  ConsumerState<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends ConsumerState<StatusPage> {
  Timer? _refreshTimer;
  bool _locating = false;
  bool _gpsDenied = false;
  bool _gpsError = false;
  Station? _nearest;
  double? _distanceKm;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      ref.invalidate(statusProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(statusProvider);
    try {
      await ref.read(statusProvider.future);
    } catch (_) {
      return;
    }
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _gpsDenied = false;
      _gpsError = false;
      _nearest = null;
      _distanceKm = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locating = false;
            _gpsDenied = true;
          });
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final stations = await ref.read(stationsProvider.future);
      final nearest =
          nearestStation(stations, position.latitude, position.longitude);
      if (!mounted) return;
      if (nearest == null) {
        setState(() {
          _locating = false;
          _gpsError = true;
        });
        return;
      }
      setState(() {
        _locating = false;
        _nearest = nearest;
        _distanceKm =
            distanceKm(nearest, position.latitude, position.longitude);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _locating = false;
          _gpsError = true;
        });
      }
    }
  }

  Color _statusColor(String statusColor) {
    switch (statusColor) {
      case 'verde':
        return Colors.green;
      case 'amarelo':
        return Colors.amber;
      case 'vermelho':
        return Colors.red;
      case 'cinza':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _updatedLabel(DateTime updatedAt) {
    final minutes = DateTime.now().difference(updatedAt).inMinutes;
    if (minutes < 1) return 'atualizado agora';
    return 'atualizado há $minutes min';
  }

  String _lineName(String lineId, Map<String, Line>? lines) {
    final line = lines?[lineId];
    if (line != null) return line.name;
    return 'Linha $lineId';
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(statusProvider);
    final linesAsync = ref.watch(linesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Status ao vivo')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _nearestStationCard(),
            const SizedBox(height: 16),
            ...statusAsync.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (_, _) => const [
                Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      'Não foi possível obter o status. Puxe para tentar novamente.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
              data: (snapshot) => _statusContent(snapshot, linesAsync.value),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _statusContent(StatusSnapshot snapshot, Map<String, Line>? lines) {
    return [
      if (snapshot.isStale)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Sem conexão — mostrando últimos dados conhecidos'),
        ),
      Text(
        _updatedLabel(snapshot.updatedAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      for (final status in snapshot.data) _statusTile(status, lines),
    ];
  }

  Widget _statusTile(LineStatus status, Map<String, Line>? lines) {
    final color = _statusColor(status.statusColor);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 6,
          height: 36,
          decoration: BoxDecoration(
            color: Color(LineColors.colorFor(status.lineId)),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        title: Text(_lineName(status.lineId, lines)),
        subtitle: status.description == null ? null : Text(status.description!),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.statusLabel,
            style: TextStyle(
              color: ThemeData.estimateBrightnessForColor(color) ==
                      Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _nearestStationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(children: [
              Icon(Icons.location_on_outlined),
              SizedBox(width: 8),
              Text(
                'Estação mais próxima',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ]),
            const SizedBox(height: 12),
            if (_locating)
              const Row(children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Buscando...'),
              ])
            else if (_nearest != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nearest!.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '~${_distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km de distância',
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      final nearest = _nearest;
                      if (nearest == null) return;
                      ref.read(selectedRouteOriginProvider.notifier).state = nearest;
                      ref.read(selectedTabProvider.notifier).state = Tabs.routes;
                    },
                    child: const Text('Como chegar'),
                  ),
                ],
              )
            else if (_gpsDenied)
              _gpsMessage(
                'Ative a localização para encontrar a estação mais próxima',
              )
            else if (_gpsError)
              _gpsMessage('Não foi possível usar a localização. Tente novamente.')
            else
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: _locate,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Usar minha localização'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _gpsMessage(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 8),
        TextButton(onPressed: _locate, child: const Text('Tentar novamente')),
      ],
    );
  }
}
