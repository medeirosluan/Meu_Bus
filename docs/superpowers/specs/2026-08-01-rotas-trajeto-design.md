# Design — Rotas: busca com estado, resultado do trajeto e mapa da rota

- **Data**: 2026-08-01
- **Status**: Aprovado
- **Escopo**: Reformular a tela de Rotas — botão com estado habilitado/desabilitado, sugestões com círculos de linha, tela de resultado do trajeto (previsão, valor, baldeações, chegada) e tela "Mapa da rota" (diagrama esquemático).
- **Supersede**: `docs/superpowers/specs/2026-08-01-rotas-redesign-design.md` (a linha do tempo do resultado vira a tela "Mapa da rota"; o resultado passa a ser uma tela própria com resumo).

## Resumo

O usuário escolhe Origem e Destino; o botão "Busca rota" fica **desabilitado** (cor apagada) até que ambos estejam selecionados. Ao buscar, abre uma **tela de resultado** com previsão (tempo), valor da viagem (R$ 5,20), número de baldeações e previsão de chegada; um botão "Detalhe do trajeto" abre a tela **"Mapa da rota"** com o diagrama esquemático do trajeto. As sugestões de estação mostram **círculos coloridos com o código da linha (L1, L4...)**.

## Escopo

### Incluído

**1. Botão "Busca rota" com estado (`lib/features/routes/routes_page.dart`)**
- `FilledButton.icon` com `Icons.search` e rótulo "Busca rota".
- `onPressed` = `_calculate` **apenas quando** `_origin != null && _destination != null`; senão `null` (botão desabilitado, cor apagada via tema). O estado muda ao selecionar/limpar um campo.

**2. Campos filled com ícones (`lib/features/routes/station_picker.dart`)**
- `StationPicker` com novo parâmetro `Widget? prefixIcon`; `InputDecoration` `filled: true`, `fillColor: Color(0xFFEEF0F5)`, cantos `BorderRadius.circular(12)`, `focusedBorder` `Color(0xFF00378C)` width 2.
- Origem: `Icon(Icons.circle, size: 14, color: Color(0xFF1E8E3E))`; Destino: `Icon(Icons.circle, size: 14, color: Color(0xFFD93025))`.

**3. Sugestões com círculos de linha (`lib/features/routes/station_picker.dart`)**
- Cada `ListTile` de sugestão mostra, ao lado do nome da estação, um **círculo por linha** (`lineIds` da estação) com a **cor oficial** (`LineColors.colorFor`) e o **código** (ex.: "L1", "L4") em texto branco pequeno dentro do círculo. Estações de baldeação mostram múltiplos círculos (ex.: L1 e L4).

**4. Tela de resultado do trajeto (`lib/features/routes/route_result_screen.dart`)**
- Ao clicar "Busca rota", `Navigator.push` para `RouteResultScreen(plan, origin, destination, lines)` (ConsumerWidget; `AppBar` com título "Melhor trajeto").
- Mostra:
  - Cabeçalho: "Como chegar em <Destino>" (ou "Melhor trajeto de <Origem> para <Destino>").
  - Cartões/linhas de resumo:
    - **Previsão**: "~X min" (`plan.totalMinutes`).
    - **Valor da viagem**: "R$ 5,20" (constante `AppFares.metro` em `lib/config/fares.dart`).
    - **Baldeações**: "N baldeação(ões)" (`plan.transferStationNames.length`).
    - **Previsão de chegada**: hora estimada = `DateTime.now().add(Duration(minutes: totalMinutes))` formatada HH:mm.
  - Botão **"Detalhe do trajeto"** (`FilledButton` com `Icons.map_outlined`) → `Navigator.push` para `RouteMapScreen`.
- Estados: sem caminho → não navega (mostra a mensagem "Não há rota disponível entre essas estações." na tela de Rotas, como hoje). Origem==destino → mensagem atual.

**5. Tela "Mapa da rota" (`lib/features/routes/route_map_screen.dart`)**
- `AppBar` com título **"Mapa da rota"**.
- **Diagrama esquemático** do trajeto (sem mapa de rua): lista as estações do trajeto em ordem (da Origem ao Destino), cada uma com um círculo da cor da linha (ou múltiplos nas baldeações) + código L<n>, conectadas por uma linha vertical colorida. Destaques:
  - Estação de **baldeação**: círculo duplo com a cor da nova linha + rótulo "Baldear".
  - Estação de **embarque** (Origem) e **desembarque** (Destino): rótulos "Embarque"/"Desembarque".
  - Rótulo de direção "Sentido <terminal>" no topo ou entre trechos.
- Implementação: um widget que monta a lista ordenada de estações por perna a partir do `RoutePlan` (reusa a lógica de reconstrução de pernas do `MetroGraph`, que já expõe `legs` e `transferStationNames`; para a lista completa de estações por perna, derivar dos `fromStationId`/`toStationId` e da ordem da linha via `Line.stationIds`).

**6. Navegação e aba**
- A tela de Rotas continua a primeira aba; resultado e mapa são telas empilhadas (`Navigator.push`), com botão voltar.
- `routes_page.dart` deixa de montar o resultado inline (remove `_buildPlan`/`_timeline`/`_guideStep`).
- **Remover** `lib/features/routes/route_result_card.dart` (não é mais usado — grep confirma que só `routes_page.dart` o referencia).

### Fora do escopo

- Mapa geográfico real (diagrama esquemático apenas).
- Cálculo de valor por trecho ou tarifa integrada diferente de R$ 5,20.
- Estimativa de chegada com dados de tempo real (usa horário atual + tempo estimado).

## Arquivos

**Criar:**
- `lib/config/fares.dart` — `class AppFares { static const String metro = 'R\$ 5,20'; static const int metroCents = 520; }`
- `lib/features/routes/route_result_screen.dart`
- `lib/features/routes/route_map_screen.dart`
- Testes: `test/widget/routes_result_screen_test.dart`, `test/widget/routes_map_screen_test.dart`, e atualizar `test/widget/routes_page_test.dart`.

**Modificar:**
- `lib/features/routes/routes_page.dart` — botão com estado, navegação para resultado, remoção do resultado inline.
- `lib/features/routes/station_picker.dart` — prefixIcon + círculos L<n> nas sugestões.
- `lib/features/status/status_page.dart`, `schedules_page.dart`, `favorites_page.dart`, `history_page.dart` — remover AppBar (a barra superior única cuida do cabeçalho; ver spec de barra/configurações).

## Verificação

- `flutter analyze` sem erros.
- `flutter test` verde.
- `flutter build web` ok.

## Decisões Registradas

- Botão desabilitado até Origem e Destino selecionados.
- Resultado em tela própria (push) com resumo (previsão, valor R$ 5,20, baldeações, chegada).
- "Mapa da rota" como diagrama esquemático (sem flutter_map).
- Sugestões de estação com círculos coloridos L1/L4.
