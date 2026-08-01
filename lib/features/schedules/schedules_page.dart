import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/line_schedule.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/repositories.dart';
import 'package:seu_metro/theme/line_colors.dart';

import '../routes/station_picker.dart';

class SchedulesPage extends ConsumerStatefulWidget {
  const SchedulesPage({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  ConsumerState<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends ConsumerState<SchedulesPage> {
  Station? _station;

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(linesProvider).value ?? const <String, Line>{};
    final schedules =
        ref.watch(schedulesProvider).value ?? const <LineSchedule>[];
    final station = _station;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            StationPicker(
              label: 'Estação',
              suggestionsFirst: true,
              onSelected: (s) => setState(() => _station = s),
            ),
            const SizedBox(height: 16),
            if (station == null)
              const Text('Selecione uma estação para ver os horários.')
            else ...[
              Text(
                station.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (final lineId in station.lineIds)
                ..._buildLineSection(lineId, lines[lineId], schedules),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLineSection(
      String lineId, Line? line, List<LineSchedule> schedules) {
    final forLine = schedules.where((s) => s.lineId == lineId).toList()
      ..sort((a, b) => a.direction.compareTo(b.direction));
    if (forLine.isEmpty) return const [];
    final now = widget.clock();
    return [
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 24,
                    color: line != null
                        ? Color(line.colorValue)
                        : Color(LineColors.colorFor(lineId)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line?.name ?? 'Linha $lineId',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              for (final s in forLine) ...[
                const SizedBox(height: 8),
                Text(
                  'Sentido ${s.terminal}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                if (_isOpen(s, now))
                  _scheduleTable(s)
                else
                  const Text('Estação fechada'),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  Widget _scheduleTable(LineSchedule schedule) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
      },
      border: TableBorder.all(color: Colors.grey.shade400),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _row('Primeiro trem', schedule.firstTrain),
        _row('Último trem', schedule.lastTrain),
        _row('Intervalo (pico)', '${schedule.headwayPeakMin} min'),
        _row('Intervalo (normal)', '${schedule.headwayNormalMin} min'),
      ],
    );
  }

  TableRow _row(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(value),
        ),
      ],
    );
  }

  static bool _isOpen(LineSchedule schedule, DateTime now) {
    final open = _toMinutes(schedule.firstTrain);
    final end = (_toMinutes(schedule.lastTrain) + 60) % 1440;
    final nowMin = now.hour * 60 + now.minute;
    if (end < open) {
      return nowMin >= open || nowMin <= end;
    }
    return nowMin >= open && nowMin <= end;
  }

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
