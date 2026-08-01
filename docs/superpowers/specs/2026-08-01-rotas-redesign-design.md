# Design — Tela de Rotas redesenhada (inputs filled + guia em linha do tempo)

- **Data**: 2026-08-01
- **Status**: Aprovado
- **Escopo**: Redesign da tela de Rotas do app "Seu Metrô" — área de busca e resultado guiado.

## Resumo

Melhorar o visual da tela de Rotas mantendo a direção "Azul Metrô". Decisões validadas por mockups: **campos de busca filled com ícones** de origem/destino, botão "Busca rota" com ícone de busca, e **resultado guiado como linha do tempo** (passos numerados conectados por linha vertical, coloridos por linha).

## Escopo

### Incluído

**1. Inputs de Origem/Destino (`lib/features/routes/station_picker.dart`)**
- Campos **filled** (Material 3): `InputDecoration` com `filled: true`, cor de fundo cinza claro (ex.: `#EEF0F5` no tema claro), cantos arredondados (`borderRadius` ~12), sem borda outline.
- **Ícone de origem** (ponto verde, ex.: `Icons.circle`, cor `Colors.green`/`#1E8E3E`) no campo Origem; **ícone de destino** (ponto vermelho, cor `#D93025`) no campo Destino — via parâmetro `icon`/`prefixIcon` do `StationPicker` (adicionar campo `Widget? prefixIcon`).
- Autocomplete de sugestões mantido (a lista de `ListTile` abaixo do campo).
- Ajustes em `StationPicker` para aceitar `prefixIcon` e `filled`; os dois campos continuam com `onSelected`/`initialValue`/`suggestionsFirst`.

**2. Botão "Busca rota" (`lib/features/routes/routes_page.dart`)**
- `FilledButton.icon` com `Icons.search` antes do rótulo "Busca rota", largura total, cantos arredondados.

**3. Resultado guiado — linha do tempo (`lib/features/routes/routes_page.dart`, `route_result_card.dart`)**
- Cabeçalho "Como chegar em <Destino>" + resumo "Rota com N baldeação(ões) · ~X min" (mantidos).
- **Linha do tempo**: coluna vertical com bolinhas numeradas (1, 2, 3...) conectadas por uma linha vertical; cada bolinha na **cor da linha** do passo (via `LineColors.colorFor`).
  - Passo 1 (embarque): "Pegue a <Linha>" + "no sentido <Sentido> · N min" (de `legs.first`).
  - Passos de baldeação (um por transferência): "Baldear em <Estação>" + "para a <Linha>" (de `transferStationNames[i]` e `legs[i+1]`).
  - Passo final: "Desça em <Destino>" + "<Linha> · N min".
- **Remover** a listagem separada de `RouteResultCard` por perna (as informações de linha/sentido/tempo/estações ficam dentro dos passos). O `route_result_card.dart` deixa de ser usado na tela de Rotas.
- Estados mantidos: origem==destino → "Origem e destino são a mesma estação."; sem caminho → "Não há rota disponível entre essas estações."; seleção obsoleta → sem resultado (comportamento atual preservado).

### Fora do escopo

- Mudar a lógica de rotas/pathfinding, dados ou providers.
- Redesenhar outras telas (apenas Rotas).
- Mudar o `StationPicker` além de filled + prefixIcon.

## Arquivos

**Modificar:**
- `lib/features/routes/station_picker.dart` — `prefixIcon` (novo parâmetro opcional), `filled`/fundo cinza, cantos arredondados.
- `lib/features/routes/routes_page.dart` — campos com prefixIcon verde/vermelho, botão `FilledButton.icon` com `Icons.search`, resultado em linha do tempo (substituir `_buildPlan`).
- `lib/features/routes/route_result_card.dart` — **remover** (é usado somente em `routes_page.dart`; após o redesign fica órfão). Confirmar com grep antes de apagar.
- Testes: `test/widget/routes_page_test.dart` (novo texto do guia), `test/widget/routes_page_stale_test.dart` (mantido, re-mirar asserção para 'Como chegar').

## Verificação

- `flutter analyze` sem erros.
- `flutter test` verde (testes de Rotas ajustados para a linha do tempo; nenhum teste referencia `RouteResultCard` diretamente).
- `flutter build web` ok.

## Decisões Registradas

- Campos filled com ícones de origem (verde) e destino (vermelho) — opção 3 dos mockups.
- Resultado guiado em linha do tempo com passos numerados coloridos — opção 1.
- Botão "Busca rota" com ícone `Icons.search`.
- `RouteResultCard` removido da tela de Rotas (informações integradas aos passos).
