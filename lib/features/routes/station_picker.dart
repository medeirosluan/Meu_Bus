import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/repositories.dart';

class StationPicker extends ConsumerStatefulWidget {
  const StationPicker({
    super.key,
    required this.label,
    required this.onSelected,
    this.suggestionsFirst = false,
  });

  final String label;
  final ValueChanged<Station> onSelected;
  final bool suggestionsFirst;

  @override
  ConsumerState<StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends ConsumerState<StationPicker> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(Station station) {
    setState(() {
      _controller.text = station.name;
    });
    widget.onSelected(station);
  }

  List<Station> _suggestions(List<Station> stations, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return stations.where((s) => s.name.toLowerCase().startsWith(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stations = ref.watch(stationsProvider).value ?? const <Station>[];
    final suggestions = _suggestions(stations, _controller.text);

    final field = TextField(
      controller: _controller,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
    );

    final dropdown = suggestions.isEmpty
        ? const SizedBox.shrink()
        : Material(
            elevation: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final station in suggestions)
                  ListTile(
                    dense: true,
                    title: Text(station.name),
                    onTap: () => _select(station),
                  ),
              ],
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: widget.suggestionsFirst ? [dropdown, field] : [field, dropdown],
    );
  }
}
