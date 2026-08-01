# Redesign da Tela de Rotas — Implementação

> **Para agentic workers:** SUB-SKILL OBRIGATÓRIO: use `superpowers:subagent-driven-development` (recomendado) ou `superpowers:executing-plans` para implementar tarefa por tarefa. Passos usam checkbox (`- [ ]`).

**Goal:** Redesenhar a tela de Rotas do app "Seu Metrô": campos de busca filled com ícones de origem/destino, botão "Busca rota" com ícone de busca, e resultado guiado em linha do tempo.

**Architecture:** Estilização pontual no `StationPicker` (novo parâmetro `prefixIcon`, `filled` com fundo cinza e cantos arredondados), no botão (`FilledButton.icon` com `Icons.search`) e na montagem do resultado em `routes_page.dart` (linha do tempo com passos numerados coloridos por linha, substituindo os `RouteResultCard`). `route_result_card.dart` deixa de ser usado e é removido.

**Tech Stack:** Flutter 3.44+, Riverpod, testes com `flutter_test`.

## Global Constraints

- UI em **pt-BR**; sem comentários no código.
- Cores: primary **`#00378C`**; fundo de campo filled **`#EEF0F5`**; ícone de origem **`#1E8E3E`** (verde), destino **`#D93025`** (vermelho); cantos arredondados ~12.
- Botão "Busca rota": `FilledButton.icon` com `Icons.search`, rótulo "Busca rota".
- Resultado: cabeçalho "Como chegar em <Destino>", resumo "Rota com N baldeação(ões) · ~X min", passos numerados (1, 2, 3...) conectados por linha vertical, cada bolinha na cor da linha (`LineColors.colorFor`).
- Textos de passos: "Pegue a <Linha>" + "no sentido <Sentido> · N min"; "Baldear em <Estação>" + "para a <Linha>"; "Desça em <Destino>" + "<Linha> · N min".
- Estados mantidos: origem==destino → "Origem e destino são a mesma estação."; sem caminho → "Não há rota disponível entre essas estações.".
- `flutter analyze` sem erros e `flutter test` verde a cada tarefa.
- Spec de referência: `docs/superpowers/specs/2026-08-01-rotas-redesign-design.md`.

---

### Task 1: Campos filled com ícones + botão com ícone de busca

**Files:**
- Modify: `lib/features/routes/station_picker.dart`
- Modify: `lib/features/routes/routes_page.dart`
- Test: `test/widget/routes_page_test.dart`

**Interfaces:**
- Consumes: `StationPicker` atual (label, onSelected, suggestionsFirst, initialValue).
- Produces: `StationPicker` com novo parâmetro opcional `Widget? prefixIcon`; `InputDecoration` `filled: true`, `fillColor: Color(0xFFEEF0F5)`, cantos `BorderRadius.circular(12)` sem `borderSide`, `focusedBorder` com borda `Color(0xFF00378C)` width 2. `RoutesPage` passa `Icons.circle` verde (Origem) e vermelho (Destino), e o botão vira `FilledButton.icon` com `Icons.search`.

- [ ] **Step 1: Escrever o teste (failing)**

Adicionar ao `test/widget/routes_page_test.dart` (novo `testWidgets`):

```dart
  testWidgets('campos de busca usam filled com ícones e botão tem ícone de busca',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RoutesPage())));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.circle), findsNWidgets(2));
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Busca rota'), findsOneWidget);
  });
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/routes_page_test.dart`
Expected: FAIL — `Icons.circle` não aparece (campos sem prefixIcon) e `Icons.search` não existe (botão sem ícone).

- [ ] **Step 3: Atualizar `lib/features/routes/station_picker.dart`**

Adicionar o parâmetro `prefixIcon` ao widget e trocar a decoração do campo:

```dart
  const StationPicker({
    super.key,
    required this.label,
    required this.onSelected,
    this.suggestionsFirst = false,
    this.initialValue,
    this.prefixIcon,
  });

  final Widget? prefixIcon;
```

E substituir o `InputDecoration` (linhas 83-86) por:

```dart
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
```

- [ ] **Step 4: Atualizar `lib/features/routes/routes_page.dart`**

Passar os prefixIcons e trocar o botão:

```dart
            StationPicker(
              label: 'Origem',
              suggestionsFirst: true,
              initialValue: prefillOrigin,
              prefixIcon: const Icon(Icons.circle, size: 14, color: Color(0xFF1E8E3E)),
              onSelected: (station) => setState(() => _origin = station),
            ),
```

```dart
            StationPicker(
              label: 'Destino',
              prefixIcon: const Icon(Icons.circle, size: 14, color: Color(0xFFD93025)),
              onSelected: (station) => setState(() => _destination = station),
            ),
```

```dart
            FilledButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.search),
              label: const Text('Busca rota'),
            ),
```

- [ ] **Step 5: Rodar o teste para passar**

Run: `flutter test test/widget/routes_page_test.dart`
Expected: PASS (inclui o teste novo e o fluxo existente, que ainda usa `find.widgetWithText(FilledButton, 'Busca rota')`).

- [ ] **Step 6: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/features/routes/station_picker.dart lib/features/routes/routes_page.dart test/widget/routes_page_test.dart
git commit -m "feat: campos filled com ícones e botão Busca rota com ícone de busca"
```

---

### Task 2: Resultado guiado em linha do tempo

**Files:**
- Modify: `lib/features/routes/routes_page.dart` (métodos `_buildPlan`, `_timeline`, `_timelineStep`; remover `_guideStep` e o import/uso de `RouteResultCard`)
- Delete: `lib/features/routes/route_result_card.dart`
- Modify: `test/widget/routes_page_test.dart`

**Interfaces:**
- Consumes: `RoutePlan { legs, totalMinutes, transferStationNames }`, `RouteLeg { lineId, directionTerminal, minutes, ... }`, `linesProvider`, `LineColors.colorFor`.
- Produces: `_buildPlan` retorna cabeçalho + resumo + linha do tempo de passos numerados coloridos; `route_result_card.dart` removido (grep confirma que nenhum outro arquivo o usa).

- [ ] **Step 1: Atualizar o teste de fluxo (failing)**

Em `test/widget/routes_page_test.dart`, no teste `'RoutesPage mostra guia passo a passo com Busca rota'`, trocar as asserções para a linha do tempo (números + textos):

```dart
    expect(find.textContaining('Como chegar em Santo Amaro'), findsOneWidget);
    expect(find.textContaining('Rota com'), findsOneWidget);
    expect(find.textContaining('Pegue a'), findsWidgets);
    expect(find.textContaining('Baldear'), findsWidgets);
    expect(find.textContaining('Desça em Santo Amaro'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/routes_page_test.dart`
Expected: FAIL — a implementação atual usa "Baldear para a" e não mostra passos numerados.

- [ ] **Step 3: Substituir `_buildPlan` e helpers em `lib/features/routes/routes_page.dart`**

Remover o import `import 'route_result_card.dart';` e adicionar `import 'package:seu_metro/theme/line_colors.dart';`. Substituir `_buildPlan`, `_guideStep` por:

```dart
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
      const SizedBox(height: 16),
      if (plan.legs.isNotEmpty) _timeline(plan, lines, destination),
    ];
  }

  Widget _timeline(RoutePlan plan, Map<String, Line> lines, Station? destination) {
    final steps = <(String, String, String)>[];
    final first = plan.legs.first;
    steps.add((
      first.lineId,
      'Pegue a ${_lineName(first, lines)}',
      'no sentido ${first.directionTerminal} · ${first.minutes} min',
    ));
    for (var i = 0; i < plan.transferStationNames.length; i++) {
      final next = plan.legs[i + 1];
      steps.add((
        next.lineId,
        'Baldear em ${plan.transferStationNames[i]}',
        'para a ${_lineName(next, lines)}',
      ));
    }
    final last = plan.legs.last;
    steps.add((
      last.lineId,
      'Desça em ${destination?.name ?? last.toStationId}',
      '${_lineName(last, lines)} · ${last.minutes} min',
    ));
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _timelineStep(i, steps.length, steps[i]),
      ],
    );
  }

  Widget _timelineStep(int index, int total, (String, String, String) step) {
    final color = Color(LineColors.colorFor(step.$1));
    final isLast = index == total - 1;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 3, color: color),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.$2,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(step.$3,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _lineName(RouteLeg leg, Map<String, Line> lines) =>
      lines[leg.lineId]?.name ?? 'Linha ${leg.lineId}';
```

- [ ] **Step 4: Remover `lib/features/routes/route_result_card.dart`**

```powershell
git rm lib/features/routes/route_result_card.dart
```

Confirmar com grep que nenhum outro arquivo importa `route_result_card` (já verificado: só `routes_page.dart` o usava).

- [ ] **Step 5: Rodar o teste para passar**

Run: `flutter test test/widget/routes_page_test.dart test/widget/routes_page_stale_test.dart`
Expected: PASS (o teste de fluxo com a linha do tempo + o teste de stale, que usa 'Como chegar').

- [ ] **Step 6: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/features/routes/routes_page.dart test/widget/routes_page_test.dart
git commit -m "feat: resultado de rotas em linha do tempo e remove RouteResultCard"
```

---

### Task 3: Verificação final

**Files:**
- Modify: nenhum (somente verificação).

- [ ] **Step 1: Analisar**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 2: Rodar todos os testes**

Run: `flutter test`
Expected: TODOS passam.

- [ ] **Step 3: Build web**

Run: `flutter build web --release`
Expected: BUILD SUCCESSFUL (o usuário testa no Chrome).

- [ ] **Step 4: Smoke manual (opcional)**

`flutter run -d chrome`: conferir campos filled com ícones verde/vermelho, botão com lupa, e o guia em linha do tempo (ex.: Luz → Santo Amaro).

- [ ] **Step 5: Commit final (se houver mudanças)**

```powershell
git add -A
git commit -m "chore: verificação final redesign de rotas"
```
