# Design — Remover a aba Mapa e abrir o app na aba Rotas

- **Data**: 2026-08-01
- **Status**: Aprovado
- **Escopo**: Alteração no app "Seu Metrô" v1 (em `main`)

## Resumo

O usuário não achou a tela de mapa relevante para o app. Esta mudança remove a aba **Mapa** por completo (código + dependências `flutter_map` e `latlong2`), reorganiza a navegação para abrir diretamente na aba **Rotas** e ajusta os atalhos de navegação que referenciam o mapa. O recurso "Estação mais próxima" (GPS) permanece na aba Status.

## Escopo

### Incluído

- Remover a aba Mapa da navegação e o código do mapa.
- O app abre na aba **Rotas**.
- 4 abas na ordem: **Rotas, Status, Horários, Favoritos**.
- Remover dependências `flutter_map` e `latlong2` do `pubspec.yaml` + `flutter pub get`.
- Ajustar os atalhos: Favoritos perde o botão "Ver no mapa"; "Como chegar" (Favoritos e Status) preenche a Origem e abre Rotas.
- Remover os testes do mapa.
- Verificação: `flutter analyze` limpo, suíte completa verde, hot reload no Chrome.

### Fora do escopo

- Mudar a lógica de rotas, status, horários ou favoritos (exceto os atalhos de navegação acima).
- Remover `geolocator`, `nearest_station.dart` ou o card "Estação mais próxima" da aba Status.
- Mudar a identidade visual do app.

## Arquivos

**Remover:**
- `lib/features/map/map_page.dart`
- `lib/features/map/station_bottom_sheet.dart`
- `test/widget/map_page_test.dart`
- `test/widget/map_page_locate_test.dart`
- `test/widget/station_bottom_sheet_test.dart`

**Modificar:**
- `pubspec.yaml` — remover `flutter_map` e `latlong2`
- `lib/features/home/home_shell.dart` — remover `MapPage`; 4 destinos; `_pages`/destinations sem Mapa; índice inicial 0 = Rotas
- `lib/providers/navigation.dart` — manter `selectedTabProvider`/`selectedRouteOriginProvider`; os índices de aba passam a ser: 0=Rotas, 1=Status, 2=Horários, 3=Favoritos
- `lib/features/status/status_page.dart` — "Como chegar" da estação mais próxima: `selectedRouteOriginProvider` + aba 0 (Rotas)
- `lib/features/favorites/favorites_page.dart` — remover botão "Ver no mapa"; "Como chegar" preenche a Origem via `selectedRouteOriginProvider` + aba 0
- `test/widget/home_shell_test.dart` — 4 destinos, primeiro = Rotas

**Manter (sem mudança):**
- `geolocator`, `lib/services/location/nearest_station.dart`, card "Estação mais próxima" na aba Status
- `lib/features/routes/*`, `lib/features/schedules/*`, `lib/features/status/*` (exceto o atalho), `lib/features/favorites/*` (exceto o atalho)
- `lib/providers/repositories.dart`, `lib/models/*`, `lib/data/*`

## Comportamento

- Ao abrir o app, a primeira aba visível é **Rotas**.
- A barra inferior tem 4 ícones: Rotas (ícone `Icons.route_outlined`), Status (`Icons.sensors_outlined`), Horários (`Icons.schedule_outlined`), Favoritos (`Icons.star_outline`).
- Nenhum código referencia mais `flutter_map`/`latlong2`/`MapPage`/`StationSheet` — o projeto compila sem essas dependências.

## Verificação

- `flutter analyze` sem erros.
- `flutter test` com a suíte completa verde (a contagem cai pelos 3 testes de mapa removidos; `home_shell_test` atualizado para 4 abas).
- `flutter pub get` bem-sucedido após remover dependências.
- Hot reload/run no Chrome para conferir que o app abre em Rotas e os atalhos funcionam.

## Decisões Registradas

- Remoção total do código do mapa e das dependências (não apenas ocultar a aba) — app mais leve e sem código morto.
- "Estação mais próxima" (GPS) mantido na aba Status — é útil e independe do mapa.
- "Ver no mapa" removido dos Favoritos por não ter mais alvo.
