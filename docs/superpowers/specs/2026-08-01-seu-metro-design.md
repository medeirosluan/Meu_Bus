# Design — App "Seu Metrô"

- **Data**: 2026-08-01
- **Status**: Aprovado
- **Escopo**: v1

## Resumo

Aplicativo mobile (iOS + Android) em Flutter para a malha de transporte metropolitano sobre trilhos de São Paulo — **Metrô SP + CPTM**. O app oferece mapa geográfico das estações, planejador de rotas estação a estação, status operacional ao vivo das linhas, horários tabelados, estação mais próxima via GPS e favoritos locais. Interface em pt-BR, visual moderno com as cores oficiais das linhas e suporte a tema escuro.

## Contexto e Objetivos

Pessoas que se deslocam na região metropolitana de São Paulo usam o metrô e a CPTM diariamente. O app centraliza informações hoje espalhadas: mapa, rotas, status operacional e horários. Objetivo do v1 é cobrir o essencial com entrega rápida e arquitetura preparada para evolução.

Sucesso do v1: usuário abre o app, encontra no mapa a estação mais próxima, planeja uma rota entre estações com passos claros e vê o status ao vivo das linhas.

## Escopo

### Incluído (v1)

- Malha **Metrô SP + CPTM** (~150 estações, 12+ linhas)
- Mapa geográfico com estações marcadas e bottom sheet de detalhes
- Planejador de rotas estação a estação (A* com penalidade de baldeação)
- Status operacional ao vivo das linhas (API pública, refresh 5 min, cache offline)
- Horários **tabelados** por estação/linha/direção (não tempo real)
- Estação mais próxima via GPS
- Favoritos locais (sem conta, `shared_preferences`)
- Tema claro/escuro, visual com cores oficiais das linhas
- Tratamento de erros amigável (pt-BR) e modo offline

### Fora do escopo (v1)

- Notificações push de status
- Contas / sincronização em nuvem
- Integração com ônibus (EMTU, SPTrans) ou caminhada no cálculo de rotas
- Horários de chegada em tempo real por estação (indisponível em APIs públicas oficiais)
- Rotas por endereço completo

## Arquitetura

Stack Flutter com padrão de **repositórios** (abordagem evolutiva): as fontes de dados (JSON local, API pública) são abstraídas atrás de interfaces. Trocar JSON local por backend no futuro = trocar apenas a implementação do repositório.

Dependências principais:
- `flutter_map` + tiles OpenStreetMap (mapa)
- `geolocator` (GPS)
- `dio` (HTTP)
- `shared_preferences` (favoritos locais)
- `flutter_riverpod` (gerenciamento de estado)
- `google_fonts` (tipografia)

### Estrutura de pastas

```
lib/
  main.dart
  models/               # Line, Station, Schedule, LineStatus, RouteStep, RouteLeg
  data/
    repositories/       # interfaces + implementações (StationRepository, LineRepository,
                        #   StatusRepository, ScheduleRepository, FavoritesRepository)
    sources/            # leitura dos JSONs embutidos + clientes HTTP das APIs públicas
    status_api/         # clientes específicos Metrô SP e CPTM
  features/
    map/                # tela de mapa + bottom sheet de estação
    routes/             # planejador de rotas
    status/             # status ao vivo das linhas
    schedules/          # horários por estação/linha/direção
    favorites/          # lista de favoritos e histórico
    home/               # shell de navegação (tabs)
  services/
    pathfinding/        # grafo + algoritmo A*
    location/           # geolocalização e estação mais próxima
  theme/                # cores oficiais das linhas, tema claro/escuro
  utils/                # helpers (formatadores, cores)
assets/
  data/
    lines.json
    stations.json
    schedules.json
test/
  unit/                 # pathfinding, parsing de dados
  widget/               # telas principais
```

### Camadas e fluxo de dados

Telas → repositórios (interfaces) → fontes (JSON local + API pública). Fluxo:

1. `StationRepository` e `LineRepository` leem os JSONs embutidos (estáticos, sempre disponíveis).
2. `ScheduleRepository` lê `schedules.json` (horários tabelados).
3. `StatusRepository` busca status ao vivo na API pública, com cache em memória e refresh periódico de 5 min. Em falha, retorna o último status cacheado com flag de desatualização.
4. `FavoritesRepository` persiste favoritos e histórico em `shared_preferences`.
5. Pathfinding consome `StationRepository`/`LineRepository` (grafo estático) e retorna passos de rota.

## Modelo de Dados

### `Line`
- `id` (ex.: `1`, `7`)
- `name` (ex.: "Linha 1-Azul")
- `colorHex` (cor oficial)
- `operator` (`metro` | `cptm`)
- `terminalA`, `terminalB` (extremidades / sentidos)

### `Station`
- `id`
- `name`
- `lat`, `lon`
- `lineIds` (lista; baldeações têm mais de uma)
- `transferIds` (baldeações: linhas que conecta — derivável de `lineIds`)

### `Schedule`
- `stationId`
- `lineId`
- `direction` (sentido terminal A ou B)
- `firstTrain` (HH:mm)
- `lastTrain` (HH:mm)
- `headwayPeakMin` (intervalo médio em horário de pico, minutos)
- `headwayNormalMin` (intervalo médio fora de pico, minutos)

### `LineStatus`
- `lineId`
- `status` (enum: `normal` | `reduced` | `stopped` | `unknown`)
- `description` (texto oficial em pt-BR, quando disponível)
- `updatedAt` (timestamp da última atualização)

### `RouteStep` / `RouteLeg`
- `leg`: linha, direção (sentido), estação de embarque, estação de desembarque, nº de estações, tempo estimado
- Passo de baldeação: de linha X para linha Y na estação Z

## Componentes

### 1. Tela de Mapa

- `flutter_map` com tiles OpenStreetMap, inicializado centralizado em São Paulo.
- Marcadores de estações com a cor da linha; estações de baldeação com múltiplas cores (sobreposição de círculos).
- Toque na estação → bottom sheet: nome, linhas servidas, horários (primeiro/último trem), botões "Como chegar", "Ver horários" e "Favoritar".
- Botão de localização: move o mapa até a posição do usuário e destaca a estação mais próxima.
- Toggle de camadas: exibe/oculta grupos de linhas (Metrô, CPTM).
- Estações fora da viewport: badge com contagem das estações ocultas.

### 2. Planejador de Rotas (estação a estação)

- Seleção de origem/destino via autocomplete filtrando estações pelo nome.
- Grafo: nós = estações; arestas = estações adjacentes na mesma linha, com peso = tempo de viagem.
- Algoritmo A* com **penalidade de baldeação** (~3 min) para preferir menos trocas.
- Resultado: lista de pernas — "Linha 2-Verde · Trianon-Masp → Clínicas" e passos de baldeação ("Baldear na Linha 1-Azul em Paraíso").
- Cada perna: tempo estimado, nº de estações, direção (Sentido).
- Tempo total estimado usando horários tabelados.
- Sem caminho encontrado → mensagem clara (não deve ocorrer na malha real).

### 3. Status em Tempo Real

- Aba de status lista todas as linhas com chip de status e cores oficiais:
  - `Operação Normal` (verde)
  - `Operação Reduzida` (amarelo)
  - `Operação Parada` (vermelho)
  - `Indisponível / sem conexão` (cinza)
- Refresh automático a cada 5 min + pull-to-refresh; rótulo "atualizado há X min".
- Modo offline: usa último status em cache com aviso "sem conexão — dados podem estar desatualizados".
- **Estação mais próxima**: botão de GPS que calcula a estação mais próxima com distância estimada e botão "Como chegar".

### 4. Horários

- Tabela por estação/linha/direção: primeiro trem, último trem, intervalo de pico e normal.
- Fora do intervalo de operação → destaque "Estação fechada" / "Próximo trem: amanhã 04:40".
- Acesso pelo bottom sheet do mapa e pela aba de horários.
- Fonte: quadro tabelado (JSON) — não é tempo real.

### 5. Favoritos

- Aba com lista de estações salvas: atalho para mapa, horários e "Como chegar".
- Botão de estrela no bottom sheet da estação e na tela de horários.
- Persistência local via `shared_preferences`.
- Histórico simples: última estação consultada como atalho.

## Fontes de Dados

- **Estáticos (embutidos)**: `lines.json`, `stations.json`, `schedules.json` com a malha Metrô SP + CPTM.
- **API pública de status**: endpoints públicos de status operacional do Metrô SP e CPTM. A implementação deve pesquisar os endpoints atualmente disponíveis; se a API mudar ou cair, o app usa o cache com aviso.
- **GPS**: `geolocator`.

## Tratamento de Erros e Offline

- Repositórios retornam estados `ok`/`error`; telas exibem mensagens amigáveis em pt-BR — nunca telas brancas.
- Dados estáticos sempre funcionam offline (JSON local).
- Status ao vivo falho → último dado em cache + banner "sem conexão".
- GPS negado → pedido de permissão; se negado, oferece busca manual de estação.
- Timeout HTTP com retry único e feedback ao usuário.

## Testes

- **Unitários**:
  - Pathfinding: caminho mais curto, preferência por menos baldeações, rota direta vs. com baldeação, ausência de caminho.
  - Parsing dos JSONs de linhas, estações e horários.
  - Cálculo de estação mais próxima.
- **Widget tests**: tela de status (estados ok/erro/offline), tela de horários, bottom sheet de estação, fluxo de favoritos.
- Comando de verificação: `flutter test` e `flutter analyze`.

## Decisões Registradas

- **Abordagem C (evolutiva)**: app 100% cliente com camada de repositórios para permitir backend futuro sem retrabalho.
- **Horários tabelados, não tempo real**: APIs públicas oficiais não expõem chegadas por estação; o v1 usa o quadro oficial.
- **Malha Metrô + CPTM** no v1 (sem EMTU/SPTrans).
- **Favoritos locais, sem conta.**
- **Nome do app**: "Seu Metrô".
