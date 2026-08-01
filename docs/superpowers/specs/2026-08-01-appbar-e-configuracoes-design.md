# Design — Barra superior e menu de configurações

- **Data**: 2026-08-01
- **Status**: Aprovado
- **Escopo**: Barra superior única (hambúrguer + identidade + nome da aba) e drawer de configurações persistidas no app "Seu Metrô".

## Resumo

Adicionar uma barra superior única no `HomeShell` com botão hambúrguer à esquerda, ícone de metrô + "Seu Metrô" como título e o nome da aba atual como subtítulo. O hambúrguer abre um **drawer** com configurações (tema, frequência de atualização, acessibilidade, recursos offline, sobre), todas persistidas via `shared_preferences`.

## Escopo

### Incluído

**1. Barra superior (`lib/features/home/home_shell.dart`)**
- `AppBar` no `Scaffold` do `HomeShell`:
  - `leading`: `Builder` com `IconButton(Icons.menu)` que abre o `Drawer` (via `Scaffold.of(context).openDrawer()`).
  - `title`: `Column(crossAxisAlignment: start)` com linha 1 = círculo azul (`#00378C`) contendo `Icons.directions_subway` branco + `Text('Seu Metrô')` (bold) e linha 2 = nome da aba atual (subtítulo, `bodySmall`, cor secundária). O nome da aba vem do índice atual (`selectedTabProvider`) mapeado por um `List<String>` de nomes das 5 abas.
  - `drawer`: `AppSettingsDrawer`.
- As 5 páginas de aba **perdem o `AppBar` próprio** (corpo apenas). Nomes de aba para o subtítulo: Rotas, Status, Horários, Favoritos, Histórico.

**2. Configurações (`lib/data/repositories/settings_repository.dart`, `lib/providers/settings_provider.dart`)**
- `SettingsRepository` (shared_preferences) com getters/setters: `themeMode` (`system|light|dark`), `refreshIntervalMinutes` (`1|5|15`), `textScale` (`small|normal|large`), `highContrast` (`bool`). Chaves constantes.
- `SettingsNotifier extends StateNotifier<SettingsState>` + `settingsProvider`; carrega do repositório no início e persiste a cada alteração.
- `SettingsState { ThemeMode themeMode; int refreshIntervalMinutes; TextScale textScale; bool highContrast; }` (enum `TextScale { small, normal, large }`).

**3. Aplicação das configurações**
- `lib/main.dart` (`SeuMetroApp`): vira `ConsumerWidget`; observa `settingsProvider`:
  - `MaterialApp.themeMode` = estado.
  - `theme`/`darkTheme`: quando `highContrast` ativo, usa um `ColorScheme` de alto contraste (variantes mais fortes das cores); quando `textScale` ≠ normal, aplica `textTheme` escalado (fator 0.9 / 1.0 / 1.15).
  - Alternativa: aplicar escala de texto via `MediaQuery.textScaler` no `builder` do `MaterialApp`.
- `lib/features/status/status_page.dart`: o `Timer.periodic` de refresh passa a usar `ref.watch(settingsProvider).refreshIntervalMinutes` (em vez de 5 min fixo).

**4. Drawer (`lib/features/settings/app_settings_drawer.dart`, `lib/features/settings/offline_info_page.dart`, `lib/features/settings/about_dialog.dart`)**
- `AppSettingsDrawer` (`ConsumerWidget`, `Drawer`):
  - Tema: `SegmentedButton`/3 opções (Sistema / Claro / Escuro).
  - Frequência de atualização: `SegmentedButton`/3 opções (1 / 5 / 15 min).
  - Acessibilidade: seletor de tamanho de texto (Pequeno / Normal / Grande) + `SwitchListTile` "Alto contraste".
  - `ListTile` "Recursos offline" → `Navigator.push` para `OfflineInfoPage`.
  - `ListTile` "Sobre o app" → `showAboutDialog` com versão, descrição e créditos.
- `OfflineInfoPage`: tela informativa pt-BR — funciona offline: mapa de estações (estático), horários, favoritos; precisa de internet: status ao vivo, histórico (Direto dos Trens).
- `AboutDialog`: usa `showAboutDialog` do Flutter com `applicationName: 'Seu Metrô'`, `applicationVersion`, `children` com créditos.

### Fora do escopo

- Redesign de outras telas além do necessário para remover o AppBar das abas.
- Novas configurações além das listadas (pode evoluir depois).
- Notificações, contas, sincronização.

## Arquivos

**Criar:**
- `lib/data/repositories/settings_repository.dart`
- `lib/providers/settings_provider.dart`
- `lib/features/settings/app_settings_drawer.dart`
- `lib/features/settings/offline_info_page.dart`
- Testes: `test/data/settings_repository_test.dart`, `test/providers/settings_provider_test.dart`, `test/widget/app_settings_drawer_test.dart`, `test/widget/home_shell_test.dart` (atualizar).

**Modificar:**
- `lib/features/home/home_shell.dart` — AppBar + Drawer; remover AppBar das páginas é feito nas próprias páginas (`routes_page.dart`, `status_page.dart`, `schedules_page.dart`, `favorites_page.dart`, `history_page.dart` removem o `appBar:`).
- `lib/main.dart` — `ConsumerWidget`, aplica tema/escala/contraste.
- `lib/features/status/status_page.dart` — intervalo de refresh do settings.

## Verificação

- `flutter analyze` sem erros.
- `flutter test` verde (home_shell_test atualizado; novos testes de settings).
- `flutter build web` ok.

## Decisões Registradas

- Barra única com hambúrguer + ícone de metrô + "Seu Metrô" (título) e nome da aba como subtítulo.
- Configurações persistidas localmente; tema, frequência, acessibilidade aplicados em tempo real.
- "Recursos offline" como tela informativa (não cacheia status/histórico).
