import 'package:flutter/material.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/route.dart';
import 'package:seu_metro/models/station.dart';

class RouteMapScreen extends StatelessWidget {
  const RouteMapScreen({
    super.key,
    required this.plan,
    required this.lines,
    required this.destination,
  });

  final RoutePlan plan;
  final Map<String, Line> lines;
  final Station destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa da rota')),
      body: const SizedBox.shrink(),
    );
  }
}
