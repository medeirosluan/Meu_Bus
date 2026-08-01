# Visual Azul Metrô + Integração Direto dos Trens — Implementação

> **Para agentic workers:** SUB-SKILL OBRIGATÓRIO: use `superpowers:subagent-driven-development` (recomendado) ou `superpowers:executing-plans` para implementar tarefa por tarefa. Passos usam checkbox (`- [ ]`).

**Goal:** Polir o visual do app para a direção "Azul Metrô" (tema, cartões de Status com bloco de cor, barra de navegação azul) e adicionar o recurso de Histórico de status via API Direto dos Trens (estrutura pronta para receber token).

**Architecture:** Estilização pontual do `ThemeData`, da `StatusPage` e da `HomeShell` (5 abas) + nova camada de dados paralela à existente: `DiretoStatus` (modelo), `DiretoApiClient` (dio, token em query via `ApiConfig.diretoToken`), `DiretoStatusRepository` (IDs + detalhes com concorrência limitada) e `HistoryPage` (linha + ano → lista de ocorrências), tudo seguindo o padrão de repositórios + Riverpod do app.

**Tech Stack:** Flutter 3.44+, Riverpod, `dio`, `geolocator` (mantido), testes com `flutter_test`.

## Global Constraints

- UI em **pt-BR**; sem comentários no código.
- Cores: primary/barra de navegação **`#00378C`**; fundo do tema claro **`#F6F7FB`**; escuro mantém padrão (superfícies `#1E1E1E`).
- Ordem das abas: **0=Rotas, 1=Status, 2=Horários, 3=Favoritos, 4=Histórico** (`Tabs` em `lib/providers/navigation.dart`).
- Token da API Direto dos Trens em **`lib/config/api_config.dart`** (`ApiConfig.diretoToken`, vazio por padrão). Testes ao vivo são pulados quando o token está vazio (padrão `skipLiveApi` já usado no app).
- Base da API Direto dos Trens: **`https://a.diretodostrens.com.br`**.
- `flutter analyze` sem erros e `flutter test` verde a cada tarefa.
- Specs de referência: `docs/superpowers/specs/2026-08-01-visual-azul-metro-design.md` e `docs/superpowers/specs/2026-08-01-integracao-direto-dos-trens-design.md`.

---

### Task 1: Tema "Azul Metrô"

**Files:**
- Modify: `lib/main.dart`
- Test: `test/widget/theme_test.dart` (novo)

**Interfaces:**
- Produces: `SeuMetroApp` com `theme` claro (fundo `#F6F7FB`, seed `#00378C`, AppBar transparente com título bold w800 22px, títulos `titleLarge`/`titleMedium` w700) e `darkTheme` (seed `#00378C`, superfícies `#1E1E1E`, AppBar escuro). `useMaterial3: true`.

- [ ] **Step 1: Escrever o teste (failing)**

`test/widget/theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/main.dart';

void main() {
  testWidgets('tema claro usa fundo F6F7FB', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SeuMetroApp()));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).first);
    final theme = Theme.of(context);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF6F7FB));
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/theme_test.dart`
Expected: FAIL (`scaffoldBackgroundColor` é o default do `ColorScheme.fromSeed`, não `#F6F7FB`).

- [ ] **Step 3: Substituir `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_shell.dart';

void main() {
  runApp(const ProviderScope(child: SeuMetroApp()));
}

ThemeData _buildLightTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00378C)),
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

ThemeData _buildDarkTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00378C),
      brightness: Brightness.dark,
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

class SeuMetroApp extends StatelessWidget {
  const SeuMetroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seu Metrô',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const HomeShell(),
    );
  }
}
```

- [ ] **Step 4: Rodar o teste para passar**

Run: `flutter test test/widget/theme_test.dart`
Expected: PASS.

- [ ] **Step 5: Rodar a suíte completa**

Run: `flutter analyze` → limpo; `flutter test` → verde (o teste do tema + os existentes).

- [ ] **Step 6: Commit**

```powershell
git add lib/main.dart test/widget/theme_test.dart
git commit -m "feat: tema Azul Metrô com fundo F6F7FB e títulos em negrito"
```

---

### Task 2: Cartões de Status com bloco de cor no topo

**Files:**
- Modify: `lib/features/status/status_page.dart` (método `_statusTile`)
- Modify: `test/widget/status_page_test.dart`

**Interfaces:**
- Consumes: `LineStatus { lineId, statusLabel, statusColor, updatedAt, description }`, `LineColors.colorFor(lineId)`.
- Produces: cartão por linha com cabeçalho colorido (cor oficial, nome da linha + "Linha <id>") e rodapé com "atualizado há X min" + chip de status.

- [ ] **Step 1: Atualizar o widget test (failing)**

`test/widget/status_page_test.dart` — manter o override e adicionar asserções do novo cartão:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/status/status_page.dart';
import 'package:seu_metro/models/line_status.dart';
import 'package:seu_metro/providers/status_provider.dart';

void main() {
  testWidgets('StatusPage mostra cartões com bloco de cor e chip', (tester) async {
    final snapshot = StatusSnapshot(
      data: [LineStatus(lineId: '1', statusCode: 'OperacaoNormal', statusLabel: 'Operação Normal', statusColor: 'verde', description: null, updatedAt: DateTime.now())],
      updatedAt: DateTime.now(),
      isStale: false,
    );
    final override = statusProvider.overrideWith((ref) => Future.value(snapshot));
    await tester.pumpWidget(ProviderScope(overrides: [override], child: const MaterialApp(home: StatusPage())));
    await tester.pumpAndSettle();
    expect(find.textContaining('Operação Normal'), findsWidgets);
    expect(find.text('Linha 1'), findsOneWidget);
    expect(find.textContaining('atualizado'), findsWidgets);
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/status_page_test.dart`
Expected: FAIL — o tile atual não exibe "Linha 1" nem "atualizado" fixos (`description` null e `updatedAt` só aparece no cabeçalho da lista).

- [ ] **Step 3: Substituir `_statusTile` em `lib/features/status/status_page.dart`**

```dart
  Widget _statusTile(LineStatus status, Map<String, Line>? lines) {
    final lineColor = Color(LineColors.colorFor(status.lineId));
    final statusColor = _statusColor(status.statusColor);
    final chipTextColor =
        ThemeData.estimateBrightnessForColor(statusColor) == Brightness.dark
            ? Colors.white
            : Colors.black87;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: lineColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _lineName(status.lineId, lines),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Linha ${status.lineId}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _updatedLabel(status.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.statusLabel,
                    style: TextStyle(
                      color: chipTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 4: Rodar o teste para passar**

Run: `flutter test test/widget/status_page_test.dart`
Expected: PASS.

- [ ] **Step 5: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/features/status/status_page.dart test/widget/status_page_test.dart
git commit -m "feat: cartões de status com bloco de cor no topo"
```

---

### Task 3: Barra de navegação azul

**Files:**
- Modify: `lib/features/home/home_shell.dart`
- Modify: `test/widget/home_shell_test.dart`

**Interfaces:**
- Consumes: `selectedTabProvider`, 4 páginas atuais (Histórico chega na Task 6).
- Produces: `NavigationBar` com `backgroundColor: Color(0xFF00378C)`, `indicatorColor: Colors.white24`, `labelTextStyle` branco (ativo `w700`/branco, inativo `white70`), ícones claros; 4 destinos por ora.

- [ ] **Step 1: Atualizar o widget test (failing)**

Em `test/widget/home_shell_test.dart`, adicionar ao teste existente (que já verifica 4 destinos e 'Origem'):

```dart
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.backgroundColor, const Color(0xFF00378C));
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/home_shell_test.dart`
Expected: FAIL (`navBar.backgroundColor` é null/default).

- [ ] **Step 3: Substituir o `bottomNavigationBar` de `lib/features/home/home_shell.dart`**

```dart
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
        ],
      ),
```

- [ ] **Step 4: Rodar o teste para passar**

Run: `flutter test test/widget/home_shell_test.dart`
Expected: PASS.

- [ ] **Step 5: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/features/home/home_shell.dart test/widget/home_shell_test.dart
git commit -m "feat: barra de navegação azul com indicador translúcido"
```

---

### Task 4: Direto dos Trens — config e modelo

**Files:**
- Create: `lib/config/api_config.dart`, `lib/models/direto_status.dart`
- Test: `test/models/direto_status_test.dart` (novo)

**Interfaces:**
- Produces:
  - `class ApiConfig { static const String diretoToken = ''; }`
  - `class DiretoStatus { int codigo; String situacao; String? descricao; DateTime criado; DateTime? modificado; int id; }` com `factory DiretoStatus.fromJson(Map<String, dynamic>)`.

- [ ] **Step 1: Escrever o teste (failing)**

`test/models/direto_status_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/models/direto_status.dart';

void main() {
  test('DiretoStatus.fromJson parseia os campos', () {
    final status = DiretoStatus.fromJson({
      'codigo': 1,
      'situacao': 'Operação Reduzida',
      'descricao': 'Trens circulando com intervalos maiores',
      'criado': '2026-07-31T08:30:00Z',
      'modificado': '2026-07-31T09:00:00Z',
      'id': 42,
    });
    expect(status.codigo, 1);
    expect(status.situacao, 'Operação Reduzida');
    expect(status.descricao, 'Trens circulando com intervalos maiores');
    expect(status.criado.isUtc, isTrue);
    expect(status.modificado, isNotNull);
    expect(status.id, 42);
  });

  test('DiretoStatus.fromJson tolera descricao/modificado ausentes', () {
    final status = DiretoStatus.fromJson({
      'codigo': 2,
      'situacao': 'Operação Normal',
      'criado': '2026-07-31T10:00:00Z',
      'id': 7,
    });
    expect(status.descricao, isNull);
    expect(status.modificado, isNull);
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/models/direto_status_test.dart`
Expected: FAIL (classes não existem).

- [ ] **Step 3: Criar os arquivos**

`lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String diretoToken = '';
}
```

`lib/models/direto_status.dart`:

```dart
class DiretoStatus {
  final int codigo;
  final String situacao;
  final String? descricao;
  final DateTime criado;
  final DateTime? modificado;
  final int id;

  const DiretoStatus({
    required this.codigo,
    required this.situacao,
    required this.descricao,
    required this.criado,
    required this.modificado,
    required this.id,
  });

  factory DiretoStatus.fromJson(Map<String, dynamic> json) {
    return DiretoStatus(
      codigo: (json['codigo'] as num).toInt(),
      situacao: json['situacao'] as String,
      descricao: json['descricao'] as String?,
      criado: DateTime.parse(json['criado'] as String),
      modificado: json['modificado'] == null
          ? null
          : DateTime.parse(json['modificado'] as String),
      id: (json['id'] as num).toInt(),
    );
  }
}
```

- [ ] **Step 4: Rodar o teste para passar**

Run: `flutter test test/models/direto_status_test.dart`
Expected: PASS.

- [ ] **Step 5: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/config/api_config.dart lib/models/direto_status.dart test/models/direto_status_test.dart
git commit -m "feat: config de token e modelo DiretoStatus"
```

---

### Task 5: Direto dos Trens — cliente e repositório

**Files:**
- Create: `lib/data/direto/direto_api_client.dart`, `lib/data/repositories/direto_status_repository.dart`
- Test: `test/data/direto_status_repository_test.dart` (novo)

**Interfaces:**
- Consumes: `DiretoStatus`, `ApiConfig.diretoToken`.
- Produces:
  - `class DiretoApiClient { static const baseUrl; final String token; DiretoApiClient({Dio? dio, this.token = ApiConfig.diretoToken, int timeoutSeconds = 10}); Future<List<DiretoStatus>> getLastStatuses(); Future<List<int>> getLineStatusIds(int linha, {int? ano}); Future<DiretoStatus> getStatusById(int id); }`
  - `class DiretoStatusRepository { DiretoStatusRepository({required DiretoApiClient client}); Future<List<DiretoStatus>> getHistory(int linha, int ano); }` — busca IDs e detalhes com concorrência limitada (4 por vez) e ordena por `criado` decrescente.

- [ ] **Step 1: Escrever o teste (failing)**

`test/data/direto_status_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/data/direto/direto_api_client.dart';
import 'package:seu_metro/data/repositories/direto_status_repository.dart';
import 'package:seu_metro/models/direto_status.dart';

DiretoStatus _st(int id, DateTime criado) => DiretoStatus(
      codigo: 1, situacao: 'S', descricao: null, criado: criado,
      modificado: null, id: id,
    );

class _FakeClient implements DiretoApiClient {
  int detailCalls = 0;
  @override
  String get token => 'fake';
  @override
  Future<List<DiretoStatus>> getLastStatuses() async => [];
  @override
  Future<List<int>> getLineStatusIds(int linha, {int? ano}) async => [3, 1, 2];
  @override
  Future<DiretoStatus> getStatusById(int id) async {
    detailCalls++;
    return _st(id, DateTime.utc(2026, 7, id));
  }
}

void main() {
  test('getHistory busca IDs, detalhes e ordena por criado decrescente', () async {
    final fake = _FakeClient();
    final repo = DiretoStatusRepository(client: fake);
    final history = await repo.getHistory(1, 2026);
    expect(history.map((s) => s.id).toList(), [3, 2, 1]);
    expect(fake.detailCalls, 3);
  });

  test('getHistory com lista vazia retorna lista vazia', () async {
    final fake = _EmptyClient();
    final repo = DiretoStatusRepository(client: fake);
    expect(await repo.getHistory(1, 2026), isEmpty);
  });
}

class _EmptyClient implements DiretoApiClient {
  @override
  String get token => '';
  @override
  Future<List<DiretoStatus>> getLastStatuses() async => [];
  @override
  Future<List<int>> getLineStatusIds(int linha, {int? ano}) async => [];
  @override
  Future<DiretoStatus> getStatusById(int id) async =>
      throw StateError('não deveria ser chamado');
}
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/data/direto_status_repository_test.dart`
Expected: FAIL (classes não existem).

- [ ] **Step 3: Criar o cliente**

`lib/data/direto/direto_api_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:seu_metro/config/api_config.dart';
import 'package:seu_metro/models/direto_status.dart';

class DiretoApiClient {
  static const baseUrl = 'https://a.diretodostrens.com.br';

  final Dio _dio;
  final String token;

  DiretoApiClient({
    Dio? dio,
    this.token = ApiConfig.diretoToken,
    int timeoutSeconds = 10,
  }) : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: Duration(seconds: timeoutSeconds),
              receiveTimeout: Duration(seconds: timeoutSeconds),
            ));

  Future<dynamic> _get(String path) async {
    final query = token.isEmpty ? null : {'token': token};
    final response = await _dio.get<dynamic>(path, queryParameters: query);
    return response.data;
  }

  List<dynamic> _expectList(dynamic data) {
    if (data is! List) {
      throw const FormatException('Resposta inesperada da API Direto dos Trens');
    }
    return data;
  }

  Future<List<DiretoStatus>> getLastStatuses() async {
    final data = _expectList(await _get('/status'));
    return data
        .map((e) => DiretoStatus.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<int>> getLineStatusIds(int linha, {int? ano}) async {
    final path =
        ano == null ? '/status/codigo/$linha' : '/status/codigo/$linha/$ano';
    final data = _expectList(await _get(path));
    return data
        .map((e) => (e as Map<String, dynamic>)['id'] as int)
        .toList();
  }

  Future<DiretoStatus> getStatusById(int id) async {
    final data = await _get('/status/id/$id');
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Resposta inesperada da API Direto dos Trens');
    }
    return DiretoStatus.fromJson(data);
  }
}
```

- [ ] **Step 4: Criar o repositório**

`lib/data/repositories/direto_status_repository.dart`:

```dart
import 'package:seu_metro/data/direto/direto_api_client.dart';
import 'package:seu_metro/models/direto_status.dart';

class DiretoStatusRepository {
  final DiretoApiClient client;

  DiretoStatusRepository({required this.client});

  Future<List<DiretoStatus>> getHistory(int linha, int ano) async {
    final ids = await client.getLineStatusIds(linha, ano: ano);
    final results = <DiretoStatus>[];
    for (var i = 0; i < ids.length; i += 4) {
      final batch = ids.skip(i).take(4);
      results.addAll(await Future.wait(batch.map(client.getStatusById)));
    }
    results.sort((a, b) => b.criado.compareTo(a.criado));
    return results;
  }
}
```

- [ ] **Step 5: Rodar o teste para passar**

Run: `flutter test test/data/direto_status_repository_test.dart`
Expected: PASS.

- [ ] **Step 6: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/data/direto/direto_api_client.dart lib/data/repositories/direto_status_repository.dart test/data/direto_status_repository_test.dart
git commit -m "feat: cliente e repositório da API Direto dos Trens"
```

---

### Task 6: Direto dos Trens — providers, tela Histórico e 5ª aba

**Files:**
- Create: `lib/providers/direto_providers.dart`, `lib/features/history/history_page.dart`
- Modify: `lib/providers/navigation.dart` (adicionar `Tabs.history = 4`), `lib/features/home/home_shell.dart` (adicionar `HistoryPage` e destino)
- Test: `test/widget/history_page_test.dart` (novo), `test/widget/home_shell_test.dart`

**Interfaces:**
- Consumes: `DiretoStatusRepository`, `DiretoStatus`, `ApiConfig.diretoToken`.
- Produces:
  - `diretoStatusRepositoryProvider` (`Provider<DiretoStatusRepository>`), `diretoTokenConfiguredProvider` (`Provider<bool>`), `historyProvider = FutureProvider.family<List<DiretoStatus>, ({int linha, int ano})>`.
  - `HistoryPage` (ConsumerStatefulWidget): dropdowns Linha (1-15) e Ano (atual, atual-1, atual-2) + `FilledButton('Ver histórico')`; estados: sem token (aviso + botão desabilitado), carregando, erro ("Não foi possível carregar o histórico. Verifique o token da API."), vazio ("Sem ocorrências registradas para essa linha/ano."), lista de cartões (cabeçalho com cor da linha, `situacao`, data formatada pt-BR e `descricao`).
  - `HomeShell`: 5ª aba (Histórico) com `Tabs.history`.

- [ ] **Step 1: Escrever o teste da tela (failing)**

`test/widget/history_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/history/history_page.dart';
import 'package:seu_metro/models/direto_status.dart';
import 'package:seu_metro/providers/direto_providers.dart';

void main() {
  testWidgets('HistoryPage sem token mostra aviso e botão desabilitado',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: HistoryPage())));
    await tester.pumpAndSettle();
    expect(find.textContaining('Configure o token'), findsOneWidget);
    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Ver histórico'));
    expect(button.onPressed, isNull);
  });

  testWidgets('HistoryPage com dados mostra cartões', (tester) async {
    final status = DiretoStatus(
      codigo: 1, situacao: 'Operação Reduzida', descricao: 'Intervalo maior',
      criado: DateTime.utc(2026, 7, 31, 8, 30), modificado: null, id: 1,
    );
    final token = diretoTokenConfiguredProvider.overrideWith((ref) => true);
    final history = historyProvider.overrideWith(
        (ref, arg) => Future.value([status]));
    await tester.pumpWidget(ProviderScope(
      overrides: [token, history],
      child: const MaterialApp(home: HistoryPage()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ver histórico'));
    await tester.pumpAndSettle();
    expect(find.text('Operação Reduzida'), findsOneWidget);
    expect(find.textContaining('Intervalo maior'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

Run: `flutter test test/widget/history_page_test.dart`
Expected: FAIL (providers e página não existem).

- [ ] **Step 3: Criar `lib/providers/direto_providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seu_metro/config/api_config.dart';
import 'package:seu_metro/data/direto/direto_api_client.dart';
import 'package:seu_metro/data/repositories/direto_status_repository.dart';
import 'package:seu_metro/models/direto_status.dart';

final diretoStatusRepositoryProvider = Provider<DiretoStatusRepository>(
    (ref) => DiretoStatusRepository(client: DiretoApiClient()));

final diretoTokenConfiguredProvider =
    Provider<bool>((ref) => ApiConfig.diretoToken.isNotEmpty);

final historyProvider =
    FutureProvider.family<List<DiretoStatus>, ({int linha, int ano})>(
  (ref, arg) => ref
      .watch(diretoStatusRepositoryProvider)
      .getHistory(arg.linha, arg.ano),
);
```

- [ ] **Step 4: Criar `lib/features/history/history_page.dart`**

```dart
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

  @override
  Widget build(BuildContext context) {
    final tokenConfigured = ref.watch(diretoTokenConfiguredProvider);
    final query = _query;
    final historyAsync =
        query == null ? null : ref.watch(historyProvider(query));
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
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
                    for (var i = 1; i <= 15; i++)
                      DropdownMenuItem(value: i, child: Text('Linha $i')),
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
```

- [ ] **Step 5: Adicionar a 5ª aba**

Em `lib/providers/navigation.dart`, dentro da classe `Tabs`:

```dart
  static const history = 4;
```

Em `lib/features/home/home_shell.dart`: importar `../history/history_page.dart`, adicionar `HistoryPage()` a `_pages` e o destino:

```dart
          NavigationDestination(
            icon: Icon(Icons.history, color: Colors.white70),
            selectedIcon: Icon(Icons.history, color: Colors.white),
            label: 'Histórico',
          ),
```

- [ ] **Step 6: Atualizar `test/widget/home_shell_test.dart`**

No teste existente, adicionar:

```dart
    expect(find.descendant(of: navBar, matching: find.text('Histórico')),
        findsOneWidget);
```

- [ ] **Step 7: Rodar os testes até passar**

Run: `flutter test test/widget/history_page_test.dart test/widget/home_shell_test.dart`
Expected: PASS (ambos). Se `DropdownButtonFormField.initialValue` não for o nome do parâmetro na versão instalada, use o parâmetro equivalente e registre no relatório.

- [ ] **Step 8: Suíte completa + commit**

Run: `flutter analyze` → limpo; `flutter test` → verde.
```powershell
git add lib/providers/direto_providers.dart lib/features/history/history_page.dart lib/providers/navigation.dart lib/features/home/home_shell.dart test/widget/history_page_test.dart test/widget/home_shell_test.dart
git commit -m "feat: aba Histórico com a API Direto dos Trens"
```

---

### Task 7: Verificação final

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

`flutter run -d chrome`: conferir tema Azul Metrô, cartões de Status com bloco de cor, barra azul, aba Histórico com o aviso de token.

- [ ] **Step 5: Commit final**

```powershell
git add -A
git commit -m "chore: verificação final visual e histórico"
```
