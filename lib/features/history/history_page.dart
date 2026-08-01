import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/models/direto_status.dart';
import 'package:seu_metro/providers/direto_providers.dart';
import 'package:seu_metro/theme/line_colors.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  int _linha = 1;
  int _ano = DateTime.now().year;
  ({int linha, int ano})? _query;

  List<int> get _lineIds =>
      (LineColors.official.keys.map(int.parse).toList()..sort());

  @override
  Widget build(BuildContext context) {
    final tokenConfigured = ref.watch(diretoTokenConfiguredProvider);
    final query = _query;
    final historyAsync =
        query == null ? null : ref.watch(historyProvider(query));
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _linha,
                  decoration: const InputDecoration(labelText: 'Linha'),
                  items: [
                    for (final id in _lineIds)
                      DropdownMenuItem(value: id, child: Text('Linha $id')),
                  ],
                  onChanged: (v) => setState(() {
                    _linha = v ?? 1;
                    _query = null;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _ano,
                  decoration: const InputDecoration(labelText: 'Ano'),
                  items: [
                    for (var y = DateTime.now().year;
                        y >= DateTime.now().year - 2;
                        y--)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (v) => setState(() {
                    _ano = v ?? DateTime.now().year;
                    _query = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: tokenConfigured
                ? () => setState(() => _query = (linha: _linha, ano: _ano))
                : null,
            child: const Text('Ver histórico'),
          ),
          const SizedBox(height: 16),
          if (!tokenConfigured)
            const Text(
                'Configure o token da API em lib/config/api_config.dart.'),
          if (historyAsync != null)
            historyAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Text(
                  'Não foi possível carregar o histórico. Verifique o token da API.'),
              data: (items) => items.isEmpty
                  ? const Text('Sem ocorrências registradas para essa linha/ano.')
                  : Column(
                      children: [for (final item in items) _historyCard(item)],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _historyCard(DiretoStatus item) {
    final color = Color(LineColors.colorFor('${item.codigo}'));
    final date = item.criado.toLocal();
    final label =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: color,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              item.situacao,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                if (item.descricao != null && item.descricao!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(item.descricao!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
