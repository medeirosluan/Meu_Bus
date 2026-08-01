# Rotas Guiadas + Remoção do Mapa — Implementação

> **Para agentic workers:** SUB-SKILL OBRIGATÓRIO: use `superpowers:subagent-driven-development` (recomendado) ou `superpowers:executing-plans` para implementar tarefa por tarefa. Passos usam checkbox (`- [ ]`).

**Goal:** Remover a aba Mapa (o app abre na aba Rotas) e transformar a tela de Rotas num guia passo a passo ("Busca rota") que prioriza a rota com menos baldeações.

**Architecture:** Alteração pontual em `home_shell.dart`/`navigation.dart` (4 abas, Rotas primeiro), remoção de `lib/features/map/` e das dependências `flutter_map`/`latlong2`, mudança da penalidade de baldeação no `MetroGraph` (seleção lexicográfica: menos baldeações primeiro, depois tempo; tempo exibível separado da penalidade) e reescrita do resultado de rota em `routes_page.dart` como guia textual.

**Tech Stack:** Flutter 3.44+, Riverpod, `geolocator` (mantido), testes com `flutter_test`.

## Global Constraints

- UI em **pt-BR**. Nome do app: **Seu Metrô**.
- Sem comentários no código.
- `flutter analyze` sem erros novos e `flutter test` verde a cada tarefa.
- Penalidade de **seleção** de baldeação = **1000**; tempo **exibível** por baldeação = **3** min (`RoutePlan.totalMinutes` = `sum(leg.minutes) + 3 * (legs.length - 1)`, nunca inclui os 1000).
- Ordem das abas após a mudança: **0=Rotas, 1=Status, 2=Horários, 3=Favoritos** (constantes em `lib/providers/navigation.dart`).
- Origem da rota sempre escolhida pelo usuário (sem GPS na tela de Rotas).
- Referências de spec: `docs/superpowers/specs/2026-08-01-remover-mapa-abrir-em-rotas-design.md` e `docs/superpowers/specs/2026-08-01-busca-rota-guiada-design.md`.

---

### Task 1: Pathfinding — priorizar menos baldeações e exibir tempo real

**Files:**
- Modify: `lib/services/pathfinding/metro_graph.dart`
- Modify: `test/services/metro_graph_test.dart`

**Interfaces:**
- Consumes: `MetroGraph.build(lines, stations)` (inalterada), `plan(fromId, toId) -> RoutePlan?` (assinatura inalterada).
- Produces: mudança de comportamento — `MetroGraph.transferPenalty` passa a `1000`; `RoutePlan.totalMinutes` passa a ser o tempo exibível (`sum(leg.minutes) + 3*(legs-1)`), não o custo interno do Dijkstra. Constante nova: `MetroGraph.displayTransferMinutes = 3`.

- [ ] **Step 1: Escrever o teste da prioridade (failing)**

Adicionar ao `test/services/metro_graph_test.dart` (após o teste `'baldeação gera duas pernas e penaliza troca'`):

```dart
test('rota com menos baldeações vence mesmo sendo mais lenta', () {
  final lineA = _line('A', ['x', 's1', 's2', 's3', 's4', 'y']);
  final lineB = _line('B', ['x', 't']);
  final lineC = _line('C', ['t', 'y']);
  final stations = [
    _st('x', ['A', 'B']),
    _st('s1', ['A']),
    _st('s2', ['A']),
    _st('s3', ['A']),
    _st('s4', ['A']),
    _st('t', ['B', 'C']),
    _st('y', ['A', 'C']),
  ];
  final graph = MetroGraph.build([lineA, lineB, lineC], stations);
  final plan = graph.plan('x', 'y')!;
  expect(plan.legs.length, 1);
  expect(plan.legs.first.lineId, 'A');
  expect(plan.transferStationNames, isEmpty);
  expect(plan.totalMinutes, 10);
});
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/services/metro_graph_test.dart`
Expected: FAIL — com penalidade 3, o algoritmo escolhe a rota rápida com 1 baldeação (B/C, 4 min + 3 = 7), então `legs.length` é 2 e o teste falha.

- [ ] **Step 3: Mudar `metro_graph.dart`**

Substituir a constante de penalidade e a computação do `totalMinutes`:

```dart
class MetroGraph {
  static const transferPenalty = 1000;
  static const minutePerStation = 2;
  static const displayTransferMinutes = 3;
  ...
```

No `plan()`: trocar a chamada final para não passar o custo do Dijkstra:

```dart
    if (goal == null) return null;
    return _reconstruct(goal, prev, edgeOf);
```

E substituir o método `_reconstruct` inteiro (remover o parâmetro `int total` e computar o tempo exibível a partir das pernas):

```dart
  RoutePlan _reconstruct(String goal, Map<String, String> prev,
      Map<String, _Edge> edgeOf) {
    var nodeIds = <String>[];
    var node = goal;
    while (true) {
      nodeIds.add(node);
      final parent = prev[node];
      if (parent == null) break;
      node = parent;
    }
    nodeIds = nodeIds.reversed.toList();

    final legs = <RouteLeg>[];
    final transfers = <String>{};
    final k = nodeIds.length - 1;
    String curLine = edgeOf[nodeIds[1]]!.lineId;
    int legStart = 0;
    for (var i = 1; i <= k; i++) {
      final e = edgeOf[nodeIds[i]]!;
      if (e.isTransfer) {
        _closeLeg(legs, nodeIds, legStart, i, curLine);
        transfers.add(_stations[nodeIds[i].split('|').first]!.name);
        legStart = i;
        curLine = e.lineId;
      } else if (e.lineId != curLine) {
        _closeLeg(legs, nodeIds, legStart, i, curLine);
        transfers.add(_stations[nodeIds[i - 1].split('|').first]!.name);
        legStart = i - 1;
        curLine = e.lineId;
      }
    }
    if (legStart <= k) {
      _closeLeg(legs, nodeIds, legStart, k + 1, curLine);
    }
    final displayMinutes = legs.isEmpty
        ? 0
        : legs.fold(0, (acc, l) => acc + l.minutes) +
            displayTransferMinutes * (legs.length - 1);
    return RoutePlan(
      legs: legs,
      totalMinutes: displayMinutes,
      transferStationNames: transfers.toList(),
    );
  }
```

- [ ] **Step 4: Atualizar o comentário/asserção do teste de baldeação**

No teste `'baldeação gera duas pernas e penaliza troca'`, atualizar o comentário e manter a asserção (o valor já é 9 = 4+2+3, agora como tempo exibível):

```dart
    // Tempo exibível: 2 arestas na linha 1 (4 min) + 1 aresta na linha 2 (2 min) + 3 min de baldeação
    expect(plan.totalMinutes, 2 * 2 + 1 * 2 + 3);
```

- [ ] **Step 5: Rodar os testes até passar**

Run: `flutter test test/services/metro_graph_test.dart`
Expected: PASS (todos, incluindo o novo teste de prioridade e os de integração).

- [ ] **Step 6: Analisar e commitar**

Run: `flutter analyze` → limpo.
```powershell
git add lib/services/pathfinding/metro_graph.dart test/services/metro_graph_test.dart
git commit -m "feat: prioriza rota com menos baldeações e tempo exibível separado"
```

---

### Task 2: Remover a aba Mapa e reorganizar a navegação (abrir em Rotas)

**Files:**
- Delete: `lib/features/map/map_page.dart`, `lib/features/map/station_bottom_sheet.dart`
- Delete: `test/widget/map_page_test.dart`, `test/widget/map_page_locate_test.dart`, `test/widget/station_bottom_sheet_test.dart`
- Modify: `pubspec.yaml` (remover `flutter_map`, `latlong2`)
- Modify: `lib/providers/navigation.dart`
- Modify: `lib/features/home/home_shell.dart`
- Modify: `lib/features/favorites/favorites_page.dart`
- Modify: `lib/features/status/status_page.dart`
- Modify: `test/widget/home_shell_test.dart`

**Interfaces:**
- Consumes: nada novo.
- Produces: `class Tabs { static const routes=0; status=1; schedules=2; favorites=3; }` em `lib/providers/navigation.dart`; `HomeShell` com 4 abas abrindo em Rotas; Favoritos sem botão "Ver no mapa"; "Como chegar" (Favoritos e Status) preenche `selectedRouteOriginProvider` e muda para `Tabs.routes`.

- [ ] **Step 1: Remover os arquivos do mapa e as dependências**

```powershell
git rm lib/features/map/map_page.dart lib/features/map/station_bottom_sheet.dart
git rm test/widget/map_page_test.dart test/widget/map_page_locate_test.dart test/widget/station_bottom_sheet_test.dart
```

Em `pubspec.yaml`, remover as linhas `flutter_map: ^8.1.0` e `latlong2: ^0.9.1` da seção `dependencies`. Rodar `flutter pub get`.

- [ ] **Step 2: Substituir `lib/providers/navigation.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Tabs {
  static const routes = 0;
  static const status = 1;
  static const schedules = 2;
  static const favorites = 3;
}

final selectedTabProvider = StateProvider<int>((ref) => Tabs.routes);
```

- [ ] **Step 3: Substituir `lib/features/home/home_shell.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/providers/navigation.dart';

import '../favorites/favorites_page.dart';
import '../routes/routes_page.dart';
import '../schedules/schedules_page.dart';
import '../status/status_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _pages = [
    RoutesPage(),
    StatusPage(),
    SchedulesPage(),
    FavoritesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(selectedTabProvider);
    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(selectedTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.route_outlined), label: 'Rotas'),
          NavigationDestination(icon: Icon(Icons.sensors_outlined), label: 'Status'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), label: 'Horários'),
          NavigationDestination(icon: Icon(Icons.star_outline), label: 'Favoritos'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Atualizar `lib/features/favorites/favorites_page.dart`**

Remover as constantes `_mapTab`/`_routesTab` (linhas 11-12) e o botão "Ver no mapa". O card passa a ter apenas "Como chegar":

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/navigation.dart';
import 'package:seu_metro/providers/repositories.dart';
import 'package:seu_metro/theme/line_colors.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final stationsAsync = ref.watch(stationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: stationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: Text('Não foi possível carregar as estações.')),
        data: (stations) {
          final favorites = stations
              .where((s) => favoriteIds.contains(s.id))
              .toList();
          if (favorites.isEmpty) {
            return const Center(child: Text('Nenhuma estação favorita ainda'));
          }
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) => _FavoriteCard(
              station: favorites[index],
              onToggle: () =>
                  ref.read(favoritesProvider.notifier).toggle(favorites[index].id),
              onGetDirections: () {
                ref.read(selectedRouteOriginProvider.notifier).state =
                    favorites[index];
                ref.read(selectedTabProvider.notifier).state = Tabs.routes;
              },
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.station,
    required this.onToggle,
    required this.onGetDirections,
  });

  final Station station;
  final VoidCallback onToggle;
  final VoidCallback onGetDirections;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    station.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.star),
                  color: Colors.amber,
                  tooltip: 'Remover dos favoritos',
                  onPressed: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final lineId in station.lineIds)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(LineColors.colorFor(lineId)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Linha $lineId',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onGetDirections,
                child: const Text('Como chegar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Atualizar `lib/features/status/status_page.dart`**

Remover a constante `static const _routesTab = 1;` (linha 23) e usar `Tabs.routes`:

```dart
                      ref.read(selectedRouteOriginProvider.notifier).state = nearest;
                      ref.read(selectedTabProvider.notifier).state = Tabs.routes;
```

`lib/features/status/status_page.dart` já importa `package:seu_metro/providers/navigation.dart` (usa `selectedTabProvider`) — basta trocar `_routesTab` por `Tabs.routes`.

- [ ] **Step 6: Atualizar `test/widget/home_shell_test.dart`**

Renomear o teste e ajustar para 4 destinos (Rotas primeiro), mantendo o override do `statusProvider`:

```dart
  testWidgets('HomeShell mostra 4 destinos e abre em Rotas', (tester) async {
    final snapshot = StatusSnapshot(
      data: [LineStatus(lineId: '1', statusCode: 'OperacaoNormal', statusLabel: 'Operação Normal', statusColor: 'verde', description: null, updatedAt: DateTime.now())],
      updatedAt: DateTime.now(),
      isStale: false,
    );
    final override = statusProvider.overrideWith((ref) => Future.value(snapshot));
    await tester.pumpWidget(ProviderScope(overrides: [override], child: const MaterialApp(home: HomeShell())));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    final navBar = find.byType(NavigationBar);
    expect(find.descendant(of: navBar, matching: find.text('Rotas')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Status')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Horários')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Favoritos')), findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Mapa')), findsNothing);
    expect(find.text('Origem'), findsOneWidget);
  });
```

- [ ] **Step 7: Rodar a suíte e o analyze**

Run: `flutter pub get` e `flutter analyze` → limpo. `flutter test` → verde (a contagem cai pelos 3 testes de mapa removidos).

- [ ] **Step 8: Commit**

```powershell
git add -A
git commit -m "feat: remove aba Mapa e abre o app na aba Rotas"
```

---

### Task 3: Tela de Rotas — "Busca rota" com guia passo a passo

**Files:**
- Modify: `lib/features/routes/routes_page.dart`
- Modify: `test/widget/routes_page_test.dart`
- Modify: `test/widget/routes_page_stale_test.dart`

**Interfaces:**
- Consumes: `RoutePlan { legs, totalMinutes, transferStationNames }`, `RouteLeg { lineId, directionTerminal, ... }`, `linesProvider` (`Map<String, Line>`), `selectedRouteOriginProvider` (já usado para prefill).
- Produces: `RoutesPage` com botão **"Busca rota"** e resultado guiado (cabeçalho "Como chegar em <Destino>", resumo "Rota com N baldeação(ões) · ~X min", passos "Pegue a ... no sentido ...", "Baldear para a ... em ...", "Desça em ...", mais `RouteResultCard` por perna). Mensagem "Origem e destino são a mesma estação." quando origem == destino.

- [ ] **Step 1: Escrever o teste de tela (failing)**

Substituir `test/widget/routes_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/routes/routes_page.dart';

void main() {
  testWidgets('RoutesPage mostra guia passo a passo com Busca rota', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RoutesPage())));
    await tester.pumpAndSettle();
    expect(find.text('Origem'), findsOneWidget);
    expect(find.text('Destino'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Luz');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luz').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Santo Amaro');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Santo Amaro').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Busca rota'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Como chegar em Santo Amaro'), findsOneWidget);
    expect(find.textContaining('Rota com'), findsOneWidget);
    expect(find.textContaining('Pegue a'), findsWidgets);
    expect(find.textContaining('Baldear para a'), findsWidgets);
    expect(find.textContaining('Desça em Santo Amaro'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/routes_page_test.dart`
Expected: FAIL (botão ainda é "Calcular rota"; guia não existe).

- [ ] **Step 3: Implementar `routes_page.dart`**

Substituir o arquivo inteiro:

```dart
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
```

- [ ] **Step 4: Atualizar `test/widget/routes_page_stale_test.dart`**

Trocar a linha do botão:

```dart
    await tester.tap(find.widgetWithText(FilledButton, 'Busca rota'));
```

- [ ] **Step 5: Rodar os testes até passar**

Run: `flutter test test/widget/routes_page_test.dart test/widget/routes_page_stale_test.dart test/widget/routes_page_prefill_test.dart`
Expected: PASS.

- [ ] **Step 6: Analisar e commitar**

Run: `flutter analyze` → limpo; `flutter test` → suíte completa verde.
```powershell
git add lib/features/routes/routes_page.dart test/widget/routes_page_test.dart test/widget/routes_page_stale_test.dart
git commit -m "feat: rota guiada com Busca rota (linha, sentido, baldeações)"
```

---

### Task 4: Verificação final

**Files:**
- Modify: nenhum (somente verificação).

- [ ] **Step 1: Analisar**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 2: Rodar todos os testes**

Run: `flutter test`
Expected: TODOS passam.

- [ ] **Step 3: Hot reload / run no Chrome (verificação manual opcional)**

Se o `flutter run` em background ainda estiver ativo, pedir hot reload (`r`) ou reiniciar com `flutter run -d chrome`. Conferir: app abre em Rotas, "Busca rota" mostra o guia (ex.: Luz → Santo Amaro), Favoritos sem "Ver no mapa".

- [ ] **Step 4: Commit final**

```powershell
git add -A
git commit -m "chore: verificação final rotas guiadas"
```
