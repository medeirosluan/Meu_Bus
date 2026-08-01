import 'package:flutter/material.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/route.dart';
import 'package:seu_metro/theme/line_colors.dart';

class RouteResultCard extends StatelessWidget {
  const RouteResultCard({super.key, required this.leg, this.line});

  final RouteLeg leg;
  final Line? line;

  @override
  Widget build(BuildContext context) {
    final color = line != null
        ? Color(line!.colorValue)
        : Color(LineColors.colorFor(leg.lineId));
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(width: 6, height: 48, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line?.name ?? 'Linha ${leg.lineId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('Sentido ${leg.directionTerminal}'),
                  Text('${leg.stationCount} estações'),
                  Text('${leg.minutes} min'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
