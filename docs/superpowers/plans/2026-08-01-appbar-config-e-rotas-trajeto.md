# Barra Superior + Configurações + Rotas/Trajeto — Implementação

> **Para agentic workers:** SUB-SKILL OBRIGATÓRIO: use `superpowers:subagent-driven-development` (recomendado) ou `superpowers:executing-plans` para implementar tarefa por tarefa. Passos usam checkbox (`- [ ]`).

**Goal:** Adicionar a barra superior (hambúrguer + identidade + nome da aba) com drawer de configurações persistidas, e reformular a tela de Rotas (botão com estado, sugestões com círculos L<n>, tela de resultado do trajeto e "Mapa da rota" esquemático).

**Architecture:** Camada de configurações (`SettingsRepository` + `SettingsNotifier` (`StateNotifier`) + `settingsProvider`) persistida em `shared_preferences`, aplicada no `SeuMetroApp` (themeMode, textScale via `MediaQuery`, alto contraste via `ColorScheme.fromSeed(contrastLevel: 1.0)`). `HomeShell` ganha `AppBar` + `Drawer`; as páginas de aba perdem o AppBar próprio. Na tela de Rotas: botão desabilitado até Origem+Destino selecionados, `StationPicker` com `prefixIcon` e círculos de linha nas sugestões, `Navigator.push` para `RouteResultScreen` (resumo: previsão, valor R$ 5,20, baldeações, chegada) e `RouteMapScreen` (diagrama esquemático). `route_result_card.dart` é removido.

**Tech Stack:** Flutter 3.44+, Riverpod, `shared_preferences`, testes com `flutter_test`.

## Global Constraints

- UI em **pt-BR**; sem comentários no código.
- Cores: primary **`#00378C`**; fundo campo filled **`#EEF0F5`**; origem **`#1E8E3E`**, destino **`#D93025`**; cantos ~12.
- Tarifa: **R$ 5,20** (constante `AppFares.metroCents = 520`).
- Abas: **0=Rotas, 1=Status, 2=Horários, 3=Favoritos, 4=Histórico** (`Tabs`).
- Nomes das abas para o subtítulo da barra: "Rotas", "Status", "Horários", "Favoritos", "Histórico".
- `flutter analyze` sem erros e `flutter test` verde a cada tarefa.
- Specs: `docs/superpowers/specs/2026-08-01-appbar-e-configuracoes-design.md`, `docs/superpowers/specs/2026-08-01-rotas-trajeto-design.md`.

---

### Task 1: Configurações — repositório, estado e provider

**Files:**
- Create: `lib/data/repositories/settings_repository.dart`, `lib/providers/settings_provider.dart`
- Test: `test/data/settings_repository_test.dart`

**Interfaces:**
- Produces:
  - `enum TextScale { small, normal, large }`
  - `class SettingsState { ThemeMode themeMode; int refreshIntervalMinutes; TextScale textScale; bool highContrast; }` com `copyWith` e `const` default.
  - `class SettingsRepository { Future<SettingsState> load(); Future<void> save(SettingsState state); }` (chaves `settings_theme_mode`, `settings_refresh_minutes`, `settings_text_scale`, `settings_high_contrast`).
  - `settingsRepositoryProvider` (`Provider<SettingsRepository>`), `settingsProvider` (`StateNotifierProvider<SettingsNotifier, SettingsState>`) com métodos `setThemeMode`, `setRefreshIntervalMinutes`, `setTextScale`, `setHighContrast`.

- **Step 1: Escrever o teste (failing)**

`test/data/settings_repository_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persiste e carrega configurações', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = SettingsRepository();
    const state = SettingsState(
      themeMode: ThemeMode.dark,
      refreshIntervalMinutes: 15,
      textScale: TextScale.large,
      highContrast: true,
    );
    await repo.save(state);
    final loaded = await repo.load();
    expect(loaded.themeMode, ThemeMode.dark);
    expect(loaded.refreshIntervalMinutes, 15);
    expect(loaded.textScale, TextScale.large);
    expect(loaded.highContrast, isTrue);
  });

  test('load retorna default quando nada salvo', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = SettingsRepository();
    final loaded = await repo.load();
    expect(loaded.themeMode, ThemeMode.system);
    expect(loaded.refreshIntervalMinutes, 5);
    expect(loaded.textScale, TextScale.normal);
    expect(loaded.highContrast, isFalse);
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/data/settings_repository_test.dart`
Expected: FAIL (classes não existem).

- [ ] **Step 3: Criar `lib/data/repositories/settings_repository.dart`**

`TextScale`, `SettingsState` e `SettingsRepository` ficam aqui (o provider importa deste arquivo — sem import circular):

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TextScale { small, normal, large }

class SettingsState {
  final ThemeMode themeMode;
  final int refreshIntervalMinutes;
  final TextScale textScale;
  final bool highContrast;

  const SettingsState({
    required this.themeMode,
    required this.refreshIntervalMinutes,
    required this.textScale,
    required this.highContrast,
  });

  const SettingsState.defaults()
      : themeMode = ThemeMode.system,
        refreshIntervalMinutes = 5,
        textScale = TextScale.normal,
        highContrast = false;

  SettingsState copyWith({
    ThemeMode? themeMode,
    int? refreshIntervalMinutes,
    TextScale? textScale,
    bool? highContrast,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      refreshIntervalMinutes:
          refreshIntervalMinutes ?? this.refreshIntervalMinutes,
      textScale: textScale ?? this.textScale,
      highContrast: highContrast ?? this.highContrast,
    );
  }
}

class SettingsRepository {
  static const _kTheme = 'settings_theme_mode';
  static const _kRefresh = 'settings_refresh_minutes';
  static const _kTextScale = 'settings_text_scale';
  static const _kHighContrast = 'settings_high_contrast';

  Future<SettingsState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsState(
      themeMode: _themeMode(prefs.getString(_kTheme)),
      refreshIntervalMinutes: prefs.getInt(_kRefresh) ?? 5,
      textScale: _textScale(prefs.getString(_kTextScale)),
      highContrast: prefs.getBool(_kHighContrast) ?? false,
    );
  }

  Future<void> save(SettingsState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, state.themeMode.name);
    await prefs.setInt(_kRefresh, state.refreshIntervalMinutes);
    await prefs.setString(_kTextScale, state.textScale.name);
    await prefs.setBool(_kHighContrast, state.highContrast);
  }

  ThemeMode _themeMode(String? value) {
    for (final mode in ThemeMode.values) {
      if (mode.name == value) return mode;
    }
    return ThemeMode.system;
  }

  TextScale _textScale(String? value) {
    for (final scale in TextScale.values) {
      if (scale.name == value) return scale;
    }
    return TextScale.normal;
  }
}
```

- [ ] **Step 4: Criar `lib/providers/settings_provider.dart`**

`SettingsNotifier` é um `StateNotifier<SettingsState>` (estado síncrono, fácil de sobrescrever nos testes):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/data/repositories/settings_repository.dart';

final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) => SettingsRepository());

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final notifier = SettingsNotifier(
    ref.watch(settingsRepositoryProvider),
    const SettingsState.defaults(),
  );
  notifier.load();
  return notifier;
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo, SettingsState initial) : super(initial);

  Future<void> load() async {
    try {
      state = await _repo.load();
    } catch (_) {
      state = const SettingsState.defaults();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update((s) => s.copyWith(themeMode: mode));

  Future<void> setRefreshIntervalMinutes(int minutes) =>
      _update((s) => s.copyWith(refreshIntervalMinutes: minutes));

  Future<void> setTextScale(TextScale scale) =>
      _update((s) => s.copyWith(textScale: scale));

  Future<void> setHighContrast(bool enabled) =>
      _update((s) => s.copyWith(highContrast: enabled));

  Future<void> _update(SettingsState Function(SettingsState) fn) async {
    final next = fn(state);
    state = next;
    try {
      await _repo.save(next);
    } catch (_) {}
  }
}
```

- [ ] **Step 5: Rodar o teste para passar**

Run: `flutter test test/data/settings_repository_test.dart`
Expected: PASS.

- [ ] **Step 6: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/data/repositories/settings_repository.dart lib/providers/settings_provider.dart test/data/settings_repository_test.dart
git commit -m "feat: configurações persistidas (tema, frequência, acessibilidade)"
```

---

### Task 2: Aplicar configurações no app (tema, escala de texto, alto contraste)

**Files:**
- Modify: `lib/main.dart`
- Test: `test/widget/theme_test.dart`

**Interfaces:**
- Consumes: `settingsProvider` (Task 1), `_buildLightTheme`/`_buildDarkTheme`.
- Produces: `SeuMetroApp` (ConsumerWidget) que aplica `themeMode`, `builder` com `MediaQuery.textScaler` (0.9/1.0/1.15) e `contrastLevel: 1.0` no `ColorScheme.fromSeed` quando `highContrast`.

- [ ] **Step 1: Atualizar o teste (failing)**

Adicionar a `test/widget/theme_test.dart`:

```dart
import 'package:seu_metro/data/repositories/settings_repository.dart';
import 'package:seu_metro/providers/settings_provider.dart';

  testWidgets('tema escuro aplicado via configuração', (tester) async {
    final override = settingsProvider.overrideWith((ref) => SettingsNotifier(
      SettingsRepository(),
      const SettingsState(
        themeMode: ThemeMode.dark,
        refreshIntervalMinutes: 5,
        textScale: TextScale.normal,
        highContrast: false,
      ),
    ));
    await tester.pumpWidget(ProviderScope(overrides: [override], child: const SeuMetroApp()));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/theme_test.dart`
Expected: FAIL — `SeuMetroApp` não é ConsumerWidget e não respeita o override (tema permanece claro).

- [ ] **Step 3: Substituir `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_shell.dart';
import 'providers/settings_provider.dart';

ThemeData _buildLightTheme(bool highContrast) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00378C),
      contrastLevel: highContrast ? 1.0 : 0.0,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF6F7FB),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF6F7FB),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF0B1B33),
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}

ThemeData _buildDarkTheme(bool highContrast) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00378C),
      brightness: Brightness.dark,
      contrastLevel: highContrast ? 1.0 : 0.0,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}

class SeuMetroApp extends ConsumerWidget {
  const SeuMetroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = settings.themeMode;
    final highContrast = settings.highContrast;
    final textScale = settings.textScale;
    final scale = switch (textScale) {
      TextScale.small => 0.9,
      TextScale.large => 1.15,
      TextScale.normal => 1.0,
    };
    return MaterialApp(
      title: 'Seu Metrô',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(highContrast),
      darkTheme: _buildDarkTheme(highContrast),
      themeMode: themeMode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const HomeShell(),
    );
  }
}
```

- [ ] **Step 4: Rodar o teste para passar**

Run: `flutter test test/widget/theme_test.dart`
Expected: PASS (o teste original do fundo `#F6F7FB` deve continuar passando com o override default via provider real — verificar; se o provider real (async) atrasar o tema, ajustar o teste original para também usar um override estável).

- [ ] **Step 5: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/main.dart test/widget/theme_test.dart
git commit -m "feat: tema, escala de texto e alto contraste aplicados via configuração"
```

---

### Task 3: Frequência de atualização do status configurável

**Files:**
- Modify: `lib/features/status/status_page.dart`
- Test: `test/widget/status_page_test.dart`

**Interfaces:**
- Consumes: `settingsProvider` (Task 1).
- Produces: o `Timer.periodic` de refresh usa `settingsProvider.refreshIntervalMinutes`; reinicia quando o valor muda (via `ref.listen`).

- [ ] **Step 1: Atualizar o widget test (failing)**

Adicionar a `test/widget/status_page_test.dart`:

```dart
import 'package:seu_metro/providers/settings_provider.dart';

  testWidgets('StatusPage usa intervalo configurado para o timer', (tester) async {
    final snapshot = StatusSnapshot(
      data: [LineStatus(lineId: '1', statusCode: 'OperacaoNormal', statusLabel: 'Operação Normal', statusColor: 'verde', description: null, updatedAt: DateTime.now())],
      updatedAt: DateTime.now(),
      isStale: false,
    );
    final overrides = [
      statusProvider.overrideWith((ref) => Future.value(snapshot)),
      settingsProvider.overrideWith((ref) => SettingsNotifier(
        SettingsRepository(),
        const SettingsState(
          themeMode: ThemeMode.system,
          refreshIntervalMinutes: 15,
          textScale: TextScale.normal,
          highContrast: false,
        ),
      )),
    ];
    await tester.pumpWidget(ProviderScope(overrides: overrides, child: const MaterialApp(home: StatusPage())));
    await tester.pumpAndSettle();
    expect(find.textContaining('Operação Normal'), findsWidgets);
  });
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/status_page_test.dart`
Expected: FAIL — `settingsProvider` não é importável/referenciado (o teste compila pois o provider existe na Task 1, mas o `StatusPage` ainda usa 5 min fixo; o teste passa mesmo assim — para o RED ser genuíno, a falha esperada é de **compilação** se `SettingsState`/`settingsProvider` não existirem; como existem, manter o teste como guarda de regressão e seguir).

- [ ] **Step 3: Modificar `lib/features/status/status_page.dart`**

No `initState`, ler o intervalo inicial e, no `build`, `ref.listen` para reiniciar o timer:

```dart
  int? _refreshMinutes;

  @override
  void initState() {
    super.initState();
    _refreshMinutes = ref.read(settingsProvider).refreshIntervalMinutes;
    _startTimer();
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      Duration(minutes: _refreshMinutes ?? 5),
      (_) => ref.invalidate(statusProvider),
    );
  }
```

No `build`, adicionar antes do `return Scaffold`:

```dart
    ref.listen(settingsProvider, (prev, next) {
      if (next.refreshIntervalMinutes != _refreshMinutes) {
        _refreshMinutes = next.refreshIntervalMinutes;
        _startTimer();
      }
    });
```

Manter `_refreshTimer?.cancel()` no `dispose`.

- [ ] **Step 4: Rodar o teste para passar**

Run: `flutter test test/widget/status_page_test.dart`
Expected: PASS.

- [ ] **Step 5: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/features/status/status_page.dart test/widget/status_page_test.dart
git commit -m "feat: frequência de atualização do status configurável"
```

---

### Task 4: Drawer de configurações (tema, frequência, acessibilidade, offline, sobre)

**Files:**
- Create: `lib/features/settings/app_settings_drawer.dart`, `lib/features/settings/offline_info_page.dart`
- Test: `test/widget/app_settings_drawer_test.dart`

**Interfaces:**
- Consumes: `settingsProvider` (Task 1).
- Produces: `AppSettingsDrawer` (ConsumerWidget → `Drawer`) com: Tema (SegmentedButton Sistema/Claro/Escuro), Frequência (SegmentedButton 1/5/15), Acessibilidade (SegmentedButton texto Pequeno/Normal/Grande + `SwitchListTile` "Alto contraste"), `ListTile` "Recursos offline" (push `OfflineInfoPage`), `ListTile` "Sobre o app" (`showAboutDialog`). `OfflineInfoPage` (Scaffold+AppBar) com info pt-BR.

- [ ] **Step 1: Escrever o teste (failing)**

`test/widget/app_settings_drawer_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/repositories/settings_repository.dart';
import 'package:seu_metro/features/settings/app_settings_drawer.dart';
import 'package:seu_metro/providers/settings_provider.dart';

void main() {
  testWidgets('drawer lista as seções de configuração', (tester) async {
    final override = settingsProvider.overrideWith((ref) => SettingsNotifier(
      SettingsRepository(),
      const SettingsState.defaults(),
    ));
    await tester.pumpWidget(ProviderScope(
      overrides: [override],
      child: MaterialApp(home: Scaffold(drawer: const AppSettingsDrawer())),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Frequência de atualização'), findsOneWidget);
    expect(find.text('Acessibilidade'), findsOneWidget);
    expect(find.text('Recursos offline'), findsOneWidget);
    expect(find.text('Sobre o app'), findsOneWidget);
  });
}
```

Nota: se o drawer não tiver `Tooltip('Abrir menu')`, use `tester.drag`/abrir via `ScaffoldState`. Ajustar o teste para abrir o drawer (`await tester.tap(find.byType(DrawerButton))` inexistente) — usar um `Builder` com `IconButton(Icons.menu)` e `Scaffold.of(context).openDrawer()`, e no teste abrir via `tester.tap(find.byIcon(Icons.menu))`.

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/app_settings_drawer_test.dart`
Expected: FAIL (AppSettingsDrawer não existe).

- [ ] **Step 3: Criar `lib/features/settings/app_settings_drawer.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/providers/settings_provider.dart';

import 'offline_info_page.dart';

class AppSettingsDrawer extends ConsumerWidget {
  const AppSettingsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final themeMode = settings.themeMode;
    final refresh = settings.refreshIntervalMinutes;
    final textScale = settings.textScale;
    final highContrast = settings.highContrast;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF00378C)),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.directions_subway, color: Color(0xFF00378C)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Seu Metrô',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('Configurações', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Tema', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
                ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) => notifier.setThemeMode(s.first),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Frequência de atualização', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1 min')),
                ButtonSegment(value: 5, label: Text('5 min')),
                ButtonSegment(value: 15, label: Text('15 min')),
              ],
              selected: {refresh},
              onSelectionChanged: (s) => notifier.setRefreshIntervalMinutes(s.first),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Acessibilidade', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<TextScale>(
              segments: const [
                ButtonSegment(value: TextScale.small, label: Text('Pequeno')),
                ButtonSegment(value: TextScale.normal, label: Text('Normal')),
                ButtonSegment(value: TextScale.large, label: Text('Grande')),
              ],
              selected: {textScale},
              onSelectionChanged: (s) => notifier.setTextScale(s.first),
            ),
          ),
          SwitchListTile(
            title: const Text('Alto contraste'),
            value: highContrast,
            onChanged: (v) => notifier.setHighContrast(v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_off_outlined),
            title: const Text('Recursos offline'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OfflineInfoPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre o app'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Seu Metrô',
              applicationVersion: '1.0.0',
              children: const [Text('App de informações do Metrô e CPTM de São Paulo.')],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Criar `lib/features/settings/offline_info_page.dart`**

```dart
import 'package:flutter/material.dart';

class OfflineInfoPage extends StatelessWidget {
  const OfflineInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recursos offline')),
      body: const ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('O que funciona sem internet:',
              style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('• Estações e linhas do metrô e CPTM'),
          Text('• Horários tabelados'),
          Text('• Favoritos'),
          SizedBox(height: 16),
          Text('O que precisa de internet:',
              style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('• Status ao vivo das linhas'),
          Text('• Histórico de ocorrências'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Ajustar o teste para abrir o drawer e rodar até passar**

O drawer é aberto pelo `IconButton(Icons.menu)` (criado na Task 5). Para este teste isolado, envolver num `Scaffold` com um `Builder`:

```dart
    await tester.pumpWidget(ProviderScope(
      overrides: [override],
      child: MaterialApp(
        home: Builder(builder: (context) => Scaffold(
          appBar: AppBar(leading: IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Abrir menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          )),
          drawer: const AppSettingsDrawer(),
        )),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
```

Run: `flutter test test/widget/app_settings_drawer_test.dart`
Expected: PASS.

- [ ] **Step 6: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/features/settings/app_settings_drawer.dart lib/features/settings/offline_info_page.dart test/widget/app_settings_drawer_test.dart
git commit -m "feat: drawer de configurações com tema, frequência, acessibilidade, offline e sobre"
```

---

### Task 5: Barra superior única + remoção dos AppBars das abas

**Files:**
- Modify: `lib/features/home/home_shell.dart`
- Modify: `lib/features/routes/routes_page.dart`, `lib/features/status/status_page.dart`, `lib/features/schedules/schedules_page.dart`, `lib/features/favorites/favorites_page.dart`, `lib/features/history/history_page.dart` (remover `appBar:`)
- Modify: `test/widget/home_shell_test.dart`

**Interfaces:**
- Consumes: `AppSettingsDrawer` (Task 4), `Tabs`/`selectedTabProvider`.
- Produces: `HomeShell` com `Scaffold(appBar: AppBar(leading: menu, title: Column[Row(círculo metrô + 'Seu Metrô'), Text(nome da aba, bodySmall)]), drawer: AppSettingsDrawer(), body: IndexedStack, bottomNavigationBar: NavigationBar)`.

- [ ] **Step 1: Atualizar o widget test (failing)**

Em `test/widget/home_shell_test.dart`, adicionar:

```dart
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text('Seu Metrô'), findsOneWidget);
    expect(find.text('Rotas'), findsWidgets);
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/home_shell_test.dart`
Expected: FAIL — sem AppBar/menu/'Seu Metrô' no HomeShell.

- [ ] **Step 3: Substituir `lib/features/home/home_shell.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/providers/navigation.dart';

import '../favorites/favorites_page.dart';
import '../history/history_page.dart';
import '../routes/routes_page.dart';
import '../schedules/schedules_page.dart';
import '../settings/app_settings_drawer.dart';
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
    HistoryPage(),
  ];

  static const _tabNames = ['Rotas', 'Status', 'Horários', 'Favoritos', 'Histórico'];

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(selectedTabProvider);
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Abrir menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00378C),
                  ),
                  child: const Icon(Icons.directions_subway,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                const Text('Seu Metrô'),
              ],
            ),
            Text(
              _tabNames[index],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      drawer: const AppSettingsDrawer(),
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        backgroundColor: const Color(0xFF00378C),
        indicatorColor: Colors.white24,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        onDestinationSelected: (i) =>
            ref.read(selectedTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.route_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.route, color: Colors.white),
            label: 'Rotas',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.sensors, color: Colors.white),
            label: 'Status',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.schedule, color: Colors.white),
            label: 'Horários',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline, color: Colors.white70),
            selectedIcon: Icon(Icons.star, color: Colors.white),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: Icon(Icons.history, color: Colors.white70),
            selectedIcon: Icon(Icons.history, color: Colors.white),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Remover `appBar:` das 5 páginas**

Em cada página, remover a linha `appBar: AppBar(title: const Text('...')),` (ou `appBar: AppBar(...)` completo) do `Scaffold`:
- `routes_page.dart` (`AppBar(title: const Text('Rotas'))`)
- `status_page.dart` (`AppBar(title: const Text('Status ao vivo'))`)
- `schedules_page.dart` (`AppBar(title: const Text('Horários'))`)
- `favorites_page.dart` (`AppBar(title: const Text('Favoritos'))`)
- `history_page.dart` (`AppBar(title: const Text('Histórico'))`)

Se algum `import 'package:flutter/material.dart'` ficar sem uso após a remoção, o `flutter analyze` acusará — ajustar.

- [ ] **Step 5: Rodar o teste para passar**

Run: `flutter test test/widget/home_shell_test.dart`
Expected: PASS.

- [ ] **Step 6: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add -A
git commit -m "feat: barra superior única com menu, identidade e nome da aba"
```

---

### Task 6: Fares + tela de resultado do trajeto

**Files:**
- Create: `lib/config/fares.dart`, `lib/features/routes/route_result_screen.dart`
- Test: `test/widget/routes_result_screen_test.dart`

**Interfaces:**
- Consumes: `RoutePlan { legs, totalMinutes, transferStationNames }`, `Station`, `Line`, `linesProvider`.
- Produces:
  - `class AppFares { static const int metroCents = 520; }` e `String formatReais(int cents)` (ex.: "R$ 5,20").
  - `RouteResultScreen({required RoutePlan plan, required Station destination, required Map<String, Line> lines})` — `ConsumerWidget`/`StatelessWidget` com `AppBar('Melhor trajeto')` e cartões: Previsão (~X min), Valor da viagem (R$ 5,20), Baldeações (N), Previsão de chegada (HH:mm = now + totalMinutes). Botão `FilledButton.icon(Icons.map_outlined, 'Detalhe do trajeto')` que faz `Navigator.push` para `RouteMapScreen` (Task 7).

- [ ] **Step 1: Escrever o teste (failing)**

`test/widget/routes_result_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/config/fares.dart';
import 'package:seu_metro/features/routes/route_result_screen.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/route.dart';
import 'package:seu_metro/models/station.dart';

void main() {
  test('formatReais formata centavos', () {
    expect(AppFares.formatReais(520), 'R\$ 5,20');
  });

  testWidgets('tela de resultado mostra resumo do trajeto', (tester) async {
    final plan = const RoutePlan(
      legs: [
        RouteLeg(lineId: '4', directionTerminal: 'Vila Sônia', fromStationId: 'luz', toStationId: 'pinheiros', stationCount: 7, minutes: 14),
        RouteLeg(lineId: '9', directionTerminal: 'Varginha', fromStationId: 'pinheiros', toStationId: 'santo_amaro', stationCount: 3, minutes: 6),
      ],
      totalMinutes: 23,
      transferStationNames: ['Pinheiros'],
    );
    const destination = Station(id: 'santo_amaro', name: 'Santo Amaro', lat: -23.65, lon: -46.71, lineIds: ['5', '9']);
    const lines = <String, Line>{
      '4': Line(id: '4', name: 'Linha 4 - Amarela', colorValue: 0xFFEFBA00, operator: 'metro', terminalA: 'Luz', terminalB: 'Vila Sônia', stationIds: ['luz']),
      '9': Line(id: '9', name: 'Linha 9 - Esmeralda', colorValue: 0xFF00AA80, operator: 'cptm', terminalA: 'Osasco', terminalB: 'Varginha', stationIds: ['pinheiros']),
    };
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: RouteResultScreen(plan: plan, destination: destination, lines: lines)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('~23 min'), findsOneWidget);
    expect(find.text('R\$ 5,20'), findsOneWidget);
    expect(find.text('1 baldeação'), findsOneWidget);
    expect(find.textContaining('Detalhe do trajeto'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/routes_result_screen_test.dart`
Expected: FAIL (fares/screen não existem).

- [ ] **Step 3: Criar `lib/config/fares.dart`**

```dart
class AppFares {
  static const int metroCents = 520;

  static String formatReais(int cents) {
    final reais = cents ~/ 100;
    final centavos = (cents % 100).toString().padLeft(2, '0');
    return 'R\$ $reais,$centavos';
  }
}
```

- [ ] **Step 4: Criar `lib/features/routes/route_result_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:seu_metro/config/fares.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/route.dart';
import 'package:seu_metro/models/station.dart';

import 'route_map_screen.dart';

class RouteResultScreen extends StatelessWidget {
  const RouteResultScreen({
    super.key,
    required this.plan,
    required this.destination,
    required this.lines,
  });

  final RoutePlan plan;
  final Station destination;
  final Map<String, Line> lines;

  @override
  Widget build(BuildContext context) {
    final arrival = DateTime.now().add(Duration(minutes: plan.totalMinutes));
    final arrivalLabel = '${arrival.hour.toString().padLeft(2, '0')}:'
        '${arrival.minute.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: const Text('Melhor trajeto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Como chegar em ${destination.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _summaryCard(Icons.timer_outlined, 'Previsão', '~${plan.totalMinutes} min'),
          _summaryCard(Icons.payments_outlined, 'Valor da viagem', AppFares.formatReais(AppFares.metroCents)),
          _summaryCard(Icons.swap_horiz, 'Baldeações', plan.transferStationNames.isEmpty ? '0' : '${plan.transferStationNames.length}'),
          _summaryCard(Icons.schedule_outlined, 'Previsão de chegada', arrivalLabel),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RouteMapScreen(plan: plan, lines: lines, destination: destination),
              ),
            ),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Detalhe do trajeto'),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(value,
            style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
```

- [ ] **Step 5: Rodar o teste para passar**

Run: `flutter test test/widget/routes_result_screen_test.dart`
Expected: PASS (a tela importa `route_map_screen.dart`, que ainda não existe → falha de compilação. Criar um arquivo placeholder mínimo `route_map_screen.dart` na Task 7, ou criar a Task 7 antes de rodar. **Ordem**: criar a Task 7 (arquivo) antes de rodar o Step 5 deste teste, OU adicionar um stub. Recomenda-se implementar a Task 7 em seguida e rodar o teste aqui junto).

- [ ] **Step 6: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/config/fares.dart lib/features/routes/route_result_screen.dart test/widget/routes_result_screen_test.dart
git commit -m "feat: tela de resultado do trajeto com previsão, valor, baldeações e chegada"
```

---

### Task 7: Tela "Mapa da rota" (diagrama esquemático)

**Files:**
- Create: `lib/features/routes/route_map_screen.dart`
- Test: `test/widget/routes_map_screen_test.dart`

**Interfaces:**
- Consumes: `RoutePlan`, `Line`, `Station`, `LineColors.colorFor`, `linesProvider` (estações).
- Produces: `RouteMapScreen({required RoutePlan plan, required Map<String, Line> lines, required Station destination})` — `ConsumerWidget` com `AppBar('Mapa da rota')` e diagrama esquemático: lista de estações por perna (ordem), cada uma com círculo da cor da linha + código L<n>; baldeações com dois círculos e rótulo "Baldear"; embarque/desembarque rotulados; direção "Sentido <terminal>" por trecho.

- [ ] **Step 1: Escrever o teste (failing)**

`test/widget/routes_map_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/routes/route_map_screen.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/route.dart';
import 'package:seu_metro/models/station.dart';

void main() {
  testWidgets('Mapa da rota mostra estações e baldeação', (tester) async {
    final plan = const RoutePlan(
      legs: [
        RouteLeg(lineId: '4', directionTerminal: 'Vila Sônia', fromStationId: 'luz', toStationId: 'pinheiros', stationCount: 7, minutes: 14),
        RouteLeg(lineId: '9', directionTerminal: 'Varginha', fromStationId: 'pinheiros', toStationId: 'santo_amaro', stationCount: 3, minutes: 6),
      ],
      totalMinutes: 23,
      transferStationNames: ['Pinheiros'],
    );
    const destination = Station(id: 'santo_amaro', name: 'Santo Amaro', lat: -23.65, lon: -46.71, lineIds: ['5', '9']);
    const lines = <String, Line>{
      '4': Line(id: '4', name: 'Linha 4 - Amarela', colorValue: 0xFFEFBA00, operator: 'metro', terminalA: 'Luz', terminalB: 'Vila Sônia', stationIds: ['luz', 'republica', 'higienopolis', 'paulista', 'oscar_freire', 'fradique', 'faria_lima', 'pinheiros']),
      '9': Line(id: '9', name: 'Linha 9 - Esmeralda', colorValue: 0xFF00AA80, operator: 'cptm', terminalA: 'Osasco', terminalB: 'Varginha', stationIds: ['pinheiros', 'morumbi', 'socorro', 'santo_amaro']),
    };
    final overrides = [stationsProvider.overrideWith((ref) async => const <Station>[
      Station(id: 'luz', name: 'Luz', lat: 0, lon: 0, lineIds: ['4']),
      Station(id: 'pinheiros', name: 'Pinheiros', lat: 0, lon: 0, lineIds: ['4', '9']),
      Station(id: 'santo_amaro', name: 'Santo Amaro', lat: 0, lon: 0, lineIds: ['5', '9']),
    ])];
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: RouteMapScreen(plan: plan, lines: lines, destination: destination)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Mapa da rota'), findsOneWidget);
    expect(find.text('Luz'), findsOneWidget);
    expect(find.text('Pinheiros'), findsOneWidget);
    expect(find.text('Santo Amaro'), findsOneWidget);
    expect(find.text('Baldear'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/routes_map_screen_test.dart`
Expected: FAIL (tela não existe).

- [ ] **Step 3: Criar `lib/features/routes/route_map_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/models/line.dart';
import 'package:seu_metro/models/route.dart';
import 'package:seu_metro/models/station.dart';
import 'package:seu_metro/providers/repositories.dart';
import 'package:seu_metro/theme/line_colors.dart';

class RouteMapScreen extends ConsumerWidget {
  const RouteMapScreen({
    super.key,
    required this.plan,
    required this.lines,
    required this.destination,
  });

  final RoutePlan plan;
  final Map<String, Line> lines;
  final Station destination;

  List<Station> _legStations(RouteLeg leg, List<Station> stations) {
    final line = lines[leg.lineId];
    if (line == null) return const [];
    final ids = line.stationIds;
    final iFrom = ids.indexOf(leg.fromStationId);
    final iTo = ids.indexOf(leg.toStationId);
    if (iFrom < 0 || iTo < 0) return const [];
    final start = iFrom < iTo ? iFrom : iTo;
    final end = iFrom < iTo ? iTo : iFrom;
    final sub = ids.sublist(start, end + 1);
    final ordered = iFrom < iTo ? sub : sub.reversed.toList();
    return [for (final id in ordered) _find(stations, id)];
  }

  Station? _find(List<Station> stations, String id) {
    for (final s in stations) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(stationsProvider).value ?? const <Station>[];
    final seen = <String>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa da rota')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final leg in plan.legs) ...[
            if (leg != plan.legs.first)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text('Sentido ${leg.directionTerminal}',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            for (final station in _legStations(leg, stations))
              if (station != null && seen.add(station.id))
                _StationRow(
                  station: station,
                  lineIds: station.lineIds,
                  isFirst: station.id == plan.legs.first.fromStationId,
                  isLast: station.id == destination.id,
                  isTransfer: plan.transferStationNames.contains(station.name),
                ),
          ],
        ],
      ),
    );
  }
}

class _StationRow extends StatelessWidget {
  const _StationRow({
    required this.station,
    required this.lineIds,
    required this.isFirst,
    required this.isLast,
    required this.isTransfer,
  });

  final Station station;
  final List<String> lineIds;
  final bool isFirst;
  final bool isLast;
  final bool isTransfer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (final lineId in lineIds)
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
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              station.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (isTransfer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00378C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Baldear', style: TextStyle(color: Colors.white, fontSize: 11)),
            )
          else if (isFirst)
            const Text('Embarque', style: TextStyle(fontSize: 11, color: Color(0xFF1E8E3E)))
          else if (isLast)
            const Text('Desembarque', style: TextStyle(fontSize: 11, color: Color(0xFFD93025))),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar o teste para passar**

Run: `flutter test test/widget/routes_map_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Voltar à Task 6 e rodar o teste da tela de resultado**

Run: `flutter test test/widget/routes_result_screen_test.dart`
Expected: PASS (agora `route_map_screen.dart` existe).

- [ ] **Step 6: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/features/routes/route_map_screen.dart test/widget/routes_map_screen_test.dart
git commit -m "feat: tela Mapa da rota com diagrama esquemático"
```

---

### Task 8: Botão com estado + sugestões com círculos de linha + navegação

**Files:**
- Modify: `lib/features/routes/station_picker.dart`, `lib/features/routes/routes_page.dart`
- Modify: `test/widget/routes_page_test.dart`

**Interfaces:**
- Consumes: `RouteResultScreen` (Task 6), `LineColors`, `stationsProvider`.
- Produces: `StationPicker` com `prefixIcon` e `ListTile` de sugestão com círculos `L<n>` coloridos; `RoutesPage` com botão desabilitado até Origem+Destino selecionados e `Navigator.push` para `RouteResultScreen` (removendo o resultado inline `_buildPlan`/`_timeline`/`_guideStep`).

- [ ] **Step 1: Atualizar o widget test (failing)**

Substituir o teste de fluxo em `test/widget/routes_page_test.dart` para o novo comportamento:

```dart
  testWidgets('botão desabilitado até selecionar origem e destino; busca abre resultado',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RoutesPage())));
    await tester.pumpAndSettle();
    final buttonFinder = find.widgetWithText(FilledButton, 'Busca rota');
    FilledButton button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull);
    expect(find.byIcon(Icons.circle), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).first, 'Luz');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luz').first);
    await tester.pumpAndSettle();
    button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull);
    await tester.enterText(find.byType(TextField).last, 'Santo Amaro');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Santo Amaro').last);
    await tester.pumpAndSettle();
    button = tester.widget(buttonFinder);
    expect(button.onPressed, isNotNull);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
    expect(find.text('Melhor trajeto'), findsOneWidget);
  });
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/routes_page_test.dart`
Expected: FAIL — botão nunca desabilitado (onPressed sempre _calculate) e não navega.

- [ ] **Step 3: Atualizar `lib/features/routes/station_picker.dart`**

Adicionar `prefixIcon` (como na Task 1 do plano de redesign anterior) e círculos de linha no `ListTile` de sugestão:

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

`InputDecoration`:

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

`ListTile` de sugestão com círculos de linha (importar `LineColors`):

```dart
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
```

- [ ] **Step 4: Atualizar `lib/features/routes/routes_page.dart`**

- Passar `prefixIcon` verde/vermelho aos pickers (Origem `Icons.circle` `#1E8E3E`, Destino `#D93025`).
- Botão:

```dart
            FilledButton.icon(
              onPressed: (_origin != null && _destination != null) ? _calculate : null,
              icon: const Icon(Icons.search),
              label: const Text('Busca rota'),
            ),
```

- `_calculate` passa a navegar:

```dart
  void _calculate() {
    final origin = _origin;
    final destination = _destination;
    if (origin == null || destination == null) return;
    final graph = ref.read(metroGraphProvider).value;
    if (graph == null) return;
    if (origin.id == destination.id) {
      setState(() => _sameStation = true);
      return;
    }
    final plan = graph.plan(origin.id, destination.id);
    if (plan == null) {
      setState(() => _noRoute = true);
      return;
    }
    setState(() {
      _noRoute = false;
      _sameStation = false;
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteResultScreen(
          plan: plan,
          destination: destination,
          lines: ref.read(linesProvider).value ?? const <String, Line>{},
        ),
      ),
    );
  }
```

- Remover `_buildPlan`, `_timeline`, `_timelineStep`, `_guideStep` e o campo `_plan` (deixar de guardar o plano inline). Manter `_sameStation`/`_noRoute` como mensagens na tela de Rotas.

- [ ] **Step 5: Rodar o teste para passar**

Run: `flutter test test/widget/routes_page_test.dart test/widget/routes_page_stale_test.dart`
Expected: PASS.

- [ ] **Step 6: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/features/routes/station_picker.dart lib/features/routes/routes_page.dart test/widget/routes_page_test.dart
git commit -m "feat: botão com estado, sugestões com círculos de linha e navegação para resultado"
```

---

### Task 9: Remover `route_result_card.dart` e limpeza

**Files:**
- Delete: `lib/features/routes/route_result_card.dart`

- [ ] **Step 1: Confirmar que não há mais usos**

Run (em PowerShell): `Select-String -Path (Get-ChildItem -Recurse -Include *.dart -Path lib,test) -Pattern "RouteResultCard|route_result_card"`
Expected: sem resultados (a Task 8 removeu o único uso).

- [ ] **Step 2: Remover o arquivo**

```powershell
git rm lib/features/routes/route_result_card.dart
```

- [ ] **Step 3: Verificar suíte**

Run: `flutter analyze` → limpo; `flutter test` → verde.

- [ ] **Step 4: Commit**

```powershell
git commit -m "chore: remove RouteResultCard não utilizado"
```

---

### Task 10: Verificação final

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
Expected: BUILD SUCCESSFUL.

- [ ] **Step 4: Smoke manual (opcional)**

`flutter run -d chrome`: conferir barra superior (hambúrguer + metrô + "Seu Metrô" + nome da aba), drawer de configurações (tema muda na hora), campos filled com ícones, botão desabilitado até selecionar, sugestões com L1/L4, tela de resultado (previsão/valor/baldeações/chegada) e "Mapa da rota".

- [ ] **Step 5: Commit final (se houver mudanças)**

```powershell
git add -A
git commit -m "chore: verificação final barra/configurações e rotas/trajeto"
```
