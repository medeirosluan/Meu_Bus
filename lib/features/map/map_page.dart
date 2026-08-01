import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:seu_metro/features/map/station_bottom_sheet.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/repositories.dart';
import 'package:seu_metro/services/location/nearest_station.dart';
import 'package:seu_metro/theme/line_colors.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});
  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  static const _metroLineIds = {'1', '2', '3', '4', '5', '6', '15', '17'};

  final _controller = MapController();
  bool _showMetro = true;
  bool _showCptm = true;
  int _offscreenCount = 0;

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);
    return Scaffold(
      body: stationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Não foi possível carregar as estações.')),
        data: (stations) => _buildMap(context, stations),
      ),
      floatingActionButton: _locateButton(),
    );
  }

  Widget _buildMap(BuildContext context, List<Station> stations) {
    final visible = stations.where((s) {
      final metro = s.lineIds.any((l) => _metroLineIds.contains(l));
      return (_showMetro && metro) || (_showCptm && !metro);
    }).toList();
    return Stack(children: [
      FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: const LatLng(-23.55, -46.633),
          initialZoom: 12,
          interactionOptions:
              const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          onPositionChanged: (pos, hasGesture) {
            final bounds = pos.visibleBounds;
            setState(() {
              _offscreenCount = visible
                  .where((s) => !bounds.contains(LatLng(s.lat, s.lon)))
                  .length;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'br.com.seumetro',
          ),
          MarkerLayer(markers: visible.map((s) => Marker(
            point: LatLng(s.lat, s.lon),
            width: 22,
            height: 22,
            child: GestureDetector(
              onTap: () => showStationSheet(context, s),
              child: _stationMarker(s),
            ),
          )).toList()),
        ],
      ),
      Positioned(top: 16, right: 16, child: _layerToggles()),
      if (_offscreenCount > 0)
        Positioned(left: 16, bottom: 16, child: _offscreenBadge()),
    ]);
  }

  Widget _offscreenBadge() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text('$_offscreenCount estações fora da tela'),
      ),
    );
  }

  Widget _stationMarker(Station s) {
    final color = Color(LineColors.colorFor(s.lineIds.first));
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
      ),
      padding: EdgeInsets.all(s.lineIds.length > 1 ? 2 : 4),
    );
  }

  Widget _layerToggles() {
    return Card(child: Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 168,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SwitchListTile(
            title: const Text('Metrô'),
            value: _showMetro,
            onChanged: (v) => setState(() => _showMetro = v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('CPTM'),
            value: _showCptm,
            onChanged: (v) => setState(() => _showCptm = v),
            dense: true,
          ),
        ]),
      ),
    ));
  }

  Widget _locateButton() {
    return FloatingActionButton(
      onPressed: () => _locate(),
      child: const Icon(Icons.my_location),
    );
  }

  Future<void> _locate() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização negada. Use a busca de estação.'),
          ),
        );
      }
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    final stations = await ref.read(stationsProvider.future);
    final nearest =
        nearestStation(stations, position.latitude, position.longitude);
    if (!mounted) return;
    if (nearest != null) {
      _controller.move(LatLng(nearest.lat, nearest.lon), 15);
      showStationSheet(context, nearest);
    }
  }
}
