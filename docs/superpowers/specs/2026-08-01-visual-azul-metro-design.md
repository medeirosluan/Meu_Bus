# Design — Visual "Azul Metrô" (polimento do layout geral)

- **Data**: 2026-08-01
- **Status**: Aprovado
- **Escopo**: Redesign visual do app "Seu Metrô" — tema, tela de Status e barra de navegação.

## Resumo

Polir o visual geral do app mantendo a direção **Azul Metrô** (Material 3, azul oficial `#00378C`, claro/institucional). Decisões validadas com mockups: cartões de Status com **bloco de cor no topo** e **barra de navegação azul escura**.

## Escopo

### Incluído

**1. Tema (`lib/main.dart` + `lib/theme/`)**
- Modo claro: fundo `#F6F7FB` (cinza-azulado suave), superfícies brancas, `colorScheme` com seed `#00378C`, Material 3.
- Modo escuro: mantém o padrão atual (fundo escuro, superfícies `#1E1E1E`, cores das linhas vibrantes).
- Tipografia: títulos com peso `bold`/`w700` via `textTheme`; espaçamentos consistentes (`ThemeData`).

**2. Tela de Status (`lib/features/status/status_page.dart`)**
- Cada linha vira um cartão com a **cor oficial como cabeçalho**: bloco colorido (cor da linha) com o nome da linha em texto branco.
- Abaixo do bloco: "atualizado há X min" + chip de status (verde/amarelo/vermelho/cinza) mapeado do `statusColor` (mesma lógica atual).
- Mantém: banner offline, estados de erro/loading, pull-to-refresh, card "Estação mais próxima".

**3. Barra de navegação (`lib/features/home/home_shell.dart`)**
- Barra inferior em **`#00378C`** (modo claro), ícones e rótulos claros; item ativo com pill translúcido (ex.: `Colors.white24`).
- Modo escuro: mesma cor `#00378C` para identidade de marca (texto claro), com adaptação de contraste.
- 5 abas: **Rotas, Status, Horários, Favoritos, Histórico** (a aba Histórico vem da integração Direto dos Trens).

**4. Demais telas**
- Rotas, Horários, Favoritos, Histórico: mantêm estrutura funcional, alinhados ao tema (AppBar com título, mesma linguagem de cartões e espaçamentos).
- `RouteResultCard`, pickers e listas mantêm comportamento; ajustes apenas visuais onde o tema exigir.

### Fora do escopo

- Mudar lógica de negócio, pathfinding, dados ou a arquitetura.
- Renomear launcher/branding (ficou como item separado).
- Criar componentes de design system novos (ex.: biblioteca de widgets de tema) — apenas estilização nas telas existentes.

## Arquivos

**Modificar:**
- `lib/main.dart` — `ThemeData` claro (fundo `#F6F7FB`, seed `#00378C`) e escuro (aprimorado), `textTheme` com títulos bold.
- `lib/features/home/home_shell.dart` — barra de navegação azul `#00378C`, pill translúcido no ativo; adicionar 5ª aba (Histórico) — depende do spec Direto dos Trens.
- `lib/features/status/status_page.dart` — cartões com bloco de cor no topo.
- `lib/providers/navigation.dart` — `Tabs.history = 4` (vem do spec Direto).
- Testes afetados (`test/widget/status_page_test.dart`, `test/widget/home_shell_test.dart`).

**Manter:**
- `lib/theme/line_colors.dart` (cores oficiais), `geolocator`, `nearest_station.dart`.

## Verificação

- `flutter analyze` sem erros.
- `flutter test` verde (testes existentes ajustados para o novo layout e a 5ª aba).
- `flutter build web` ok.

## Decisões Registradas

- Direção "Azul Metrô" (Material 3 azul) com polimento, validada por mockups.
- Cartão de Status com bloco de cor no topo (opção 3).
- Barra de navegação azul escura `#00378C` (opção 3), mesma cor nos dois temas.
