# Design — Rotas guiadas ("Busca rota") com prioridade de menos baldeações

- **Data**: 2026-08-01
- **Status**: Aprovado
- **Escopo**: Alterações na tela de Rotas e no pathfinding do app "Seu Metrô" v1 (em `main`)

## Resumo

O usuário quer que o app **guie** até a estação de destino: qual linha pegar, em qual **sentido** seguir e onde **baldear**. Também quer que a rota exibida seja a **melhor rota com o menor número de baldeações**. Este spec cobre: renomear o botão de Rotas para "Busca rota", exibir o resultado como um guia passo a passo e mudar o pathfinding para priorizar menos baldeações sobre menor tempo.

## Escopo

### Incluído

- Renomear o botão "Calcular rota" para **"Busca rota"** na tela de Rotas.
- Resultado guiado quando a rota é calculada:
  - Cabeçalho "Como chegar em <Destino>" + tempo total estimado.
  - Passo 1: "Pegue a <Linha X> no sentido <Sentido>" a partir da estação de Origem.
  - Para cada baldeação: "Baldear para a <Linha Y> em <Estação>".
  - Passo final: "Desça em <Destino>".
  - Resumo: "Rota com N baldeação(ões) · ~X min".
  - Mantém por trecho: nº de estações e tempo.
- Mudar o pathfinding para **priorizar menos baldeações**: o `MetroGraph` otimiza por ordem de importância — primeiro o menor número de baldeações; entre rotas com o mesmo número, a de menor tempo. Implementado elevando a penalidade de baldeação (constante grande, ex.: 1000 min) de modo que o Dijkstra nunca troque mais baldeações por menos tempo.
- Manter o comportamento de erros: sem caminho → "Não há rota disponível entre essas estações."; origem = destino → mensagem simples.
- Atualizar os testes de pathfinding e de tela que dependem da antiga penalidade de 3 min / do botão "Calcular rota".

### Fora do escopo

- GPS na tela de Rotas (a Origem é sempre escolhida pelo usuário).
- Mudar a malha, os dados ou os demais recursos (status, horários, favoritos).
- Integração com Google Maps.

## Comportamento

**Guia passo a passo** (exemplo real: Origem = Trianon-Masp, Destino = Santo Amaro):
- "Como chegar em Santo Amaro" · "Rota com 1 baldeação · ~23 min"
- 1. "Pegue a Linha 2-Verde no sentido Vila Prudente"
- 2. "Baldear para a Linha 5-Lilás em Chácara Klabin"
- 3. "Desça em Santo Amaro"

**Prioridade de rota**: entre duas rotas possíveis, o app sempre escolhe a de **menos baldeações**, mesmo que seja mais demorada; empate em baldeações → a mais rápida.

**Tempo exibido × penalidade de seleção**: a penalidade grande (1000 min) é usada **somente para o algoritmo escolher a rota** (seleção lexicográfica). O `RoutePlan.totalMinutes` exibido ao usuário é calculado separadamente, com o tempo real: **soma dos minutos de cada perna + 3 min por baldeação** (`sum(leg.minutes) + 3 * (legs.length - 1)`). Assim a UI nunca mostra os 1000 min da penalidade.

## Arquivos

**Modificar:**
- `lib/services/pathfinding/metro_graph.dart` — `transferPenalty` de 3 → constante grande (ex.: 1000) para seleção; `totalMinutes` passado ao `RoutePlan` passa a ser o tempo real exibível (`sum(leg.minutes) + 3 * (legs - 1)`), não o custo do algoritmo.
- `lib/features/routes/routes_page.dart` — botão "Busca rota"; montagem do guia passo a passo com os dados do `RoutePlan` (`RouteLeg.lineId`, `RouteLeg.directionTerminal`, `RoutePlan.transferStationNames`, destino).
- `lib/features/routes/route_result_card.dart` — card do trecho (mantém, eventualmente ajuste de texto).
- `test/services/metro_graph_test.dart` — atualizar valores esperados de `totalMinutes` e comportamento de transferência.
- `test/widget/routes_page_test.dart` — botão "Busca rota" e asserções do guia.

**Depende do spec de remoção do mapa** (`docs/superpowers/specs/2026-08-01-remover-mapa-abrir-em-rotas-design.md`): os dois são implementados no mesmo ciclo; a tela de Rotas vira a aba inicial.

## Decisões Registradas

- Origem sempre escolhida pelo usuário (sem GPS na tela de Rotas).
- Prioridade lexicográfica: menos baldeações primeiro, depois menor tempo.
- Guia textual passo a passo, em pt-BR, com destaque para sentido e baldeação.
