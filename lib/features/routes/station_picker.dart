import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/repositories.dart';
import 'package:seu_metro/theme/line_colors.dart';

class StationPicker extends ConsumerStatefulWidget {
  const StationPicker({
    super.key,
    required this.label,
    required this.onSelected,
    this.suggestionsFirst = false,
    this.initialValue,
    this.prefixIcon,
  });

  final String label;
  final ValueChanged<Station?> onSelected;
  final bool suggestionsFirst;
  final Station? initialValue;
  final Widget? prefixIcon;

  @override
  ConsumerState<StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends ConsumerState<StationPicker> {
  final TextEditingController _controller = TextEditingController();
  Station? _selected;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    if (initial != null) {
      _selected = initial;
      _controller.text = initial.name;
    }
  }

  @override
  void didUpdateWidget(StationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final initial = widget.initialValue;
    if (initial != null && initial.id != oldWidget.initialValue?.id) {
      _selected = initial;
      _controller.text = initial.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(Station station) {
    setState(() {
      _selected = station;
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
      onChanged: (text) {
        final selected = _selected;
        if (selected != null && text.trim() != selected.name) {
          _selected = null;
          widget.onSelected(null);
        }
        setState(() {});
      },
      decoration: InputDecoration(
        labelText: widget.label,
        filled: true,
        fillColor: const Color(0xFFEEF0F5),
        prefixIcon: widget.prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00378C), width: 2),
        ),
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
                    title: Row(
                      children: [
                        for (final lineId in station.lineIds)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(LineColors.colorFor(lineId)),
                            ),
                            child: Center(
                              child: Text(
                                'L$lineId',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(station.name)),
                      ],
                    ),
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
