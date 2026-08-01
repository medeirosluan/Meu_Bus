# Design — Integração com a API "Direto dos Trens" (Histórico de status)

- **Data**: 2026-08-01
- **Status**: Aprovado
- **Escopo**: Nova funcionalidade no app "Seu Metrô" — cliente da API Direto dos Trens + tela de Histórico de status por linha/ano.

## Resumo

Integrar a API **Direto dos Trens** (`https://a.diretodostrens.com.br`, spec em `https://static.diretodostrens.com.br/swagger/api.json`) para adicionar o recurso de **histórico de status** por linha e ano. Os endpoints principais exigem um **token** (`?token=...`) que o usuário solicitará ao desenvolvedor; a integração fica pronta com o token em um config editável (`lib/config/api_config.dart`), plugável depois.

## Endpoints da API (OpenAPI 3.1.2)

- `GET /status` — últimos status de todas as linhas. **Exige token.**
- `GET /status/codigo/{linha}` — últimos IDs de status de uma linha. **Exige token.**
- `GET /status/codigo/{linha}/{ano}` — todos os IDs de status de uma linha num ano. **Exige token.**
- `GET /status/id/{id}` — detalhes de um status. **Aberto (sem token).**

Formato do `Status`: `{ codigo (int, linha), situacao (string), descricao (string?, max 1500), criado (date-time), modificado (date-time?), id (int) }`.

O token é `apiKey` **em query**, parâmetro `token`.

## Escopo

### Incluído

- **Config de token**: `lib/config/api_config.dart` com `class ApiConfig { static const String diretoToken = ''; }` — o usuário cola o token quando recebê-lo. O cliente injeta `?token=<diretoToken>` apenas se não-vazio.
- **Modelo**: `lib/models/direto_status.dart` — `DiretoStatus { int codigo; String situacao; String? descricao; DateTime criado; DateTime? modificado; int id; }` com `fromJson` (parse de date-time ISO).
- **Cliente**: `lib/data/direto/direto_api_client.dart` — dio, base `https://a.diretodostrens.com.br`, timeout 10s, `get(String path)` que adiciona o token em query. Lança `FormatException` se a resposta não for a esperada.
- **Repositório**: `lib/data/repositories/direto_status_repository.dart` — mesmo padrão dos repositórios existentes:
  - `Future<List<DiretoStatus>> getLastStatuses()`
  - `Future<List<int>> getLineStatusIds(int linha)` e `Future<List<int>> getLineStatusIds(int linha, int ano)`
  - `Future<DiretoStatus> getStatusById(int id)`
- **Nova aba "Histórico"** (5ª aba: Rotas, Status, Horários, Favoritos, **Histórico**), com ícone `Icons.history`:
  - Seletor de **linha** (1 a 15) e **ano** (padrão: ano atual) + botão "Ver histórico".
  - Resultado: lista cronológica de ocorrências da linha no ano — cada item com `situacao`, data/hora (`criado`, formatada pt-BR) e `descricao` (quando existir).
  - Fluxo: `getLineStatusIds(linha, ano)` → IDs → `getStatusById(id)` por id (paralelo com limite de concorrência, ex.: 4 por vez) → lista ordenada por `criado` decrescente.
  - Estados: carregando; erro ("Não foi possível carregar o histórico. Verifique o token da API."); vazio ("Sem ocorrências registradas para essa linha/ano."); **sem token** (aviso "Configure o token da API em `lib/config/api_config.dart`." e não busca).
- **Providers**: `diretoStatusRepositoryProvider`, `diretoTokenConfiguredProvider` (`bool`, true se `ApiConfig.diretoToken` não-vazio), e `historyProvider` — `FutureProvider.family<List<DiretoStatus>, ({int linha, int ano})>` que usa o repositório (IDs + detalhes por id com concorrência limitada). Seguindo o padrão Riverpod do app.
- **Testes**: parsing do `DiretoStatus.fromJson` com fixture; repositório com fake client; a tela com override do provider. O teste ao vivo é pulado quando `diretoToken` está vazio (padrão `skipLiveApi` já usado no app).

### Fora do escopo

- Usar o Direto dos Trens como fonte do status ao vivo atual (a aba Status continua usando a API do Metrô SP).
- Mostrar descrições detalhadas na aba Status atual.
- Histórico entre linhas ou agregações (ex.: "piores dias da semana").
- Token em variável de ambiente/secret (v1: constante no config; se mais tarde for sensível, mover).

## Comportamento

- Sem token (`diretoToken` vazio): a aba Histórico mostra o aviso de configurar o token e o botão "Ver histórico" fica desabilitado ou mostra o aviso ao tocar.
- Com token: seleciona linha+ano, toca "Ver histórico", carrega os IDs e busca cada detalhe (concorrência limitada), exibindo a lista.
- Falha de rede/token inválido: estado de erro com mensagem pt-BR.
- Sem ocorrências: estado vazio.

## Arquivos

**Criar:**
- `lib/config/api_config.dart`
- `lib/models/direto_status.dart`
- `lib/data/direto/direto_api_client.dart`
- `lib/data/repositories/direto_status_repository.dart`
- `lib/providers/direto_providers.dart`
- `lib/features/history/history_page.dart`
- Testes: `test/models/direto_status_test.dart`, `test/data/direto_api_client_test.dart`, `test/data/direto_status_repository_test.dart`, `test/widget/history_page_test.dart`

**Modificar:**
- `lib/features/home/home_shell.dart` — adicionar 5ª aba (Histórico) com `HistoryPage`.
- `lib/providers/navigation.dart` — `Tabs.history = 4`.
- `test/widget/home_shell_test.dart` — 5 destinos.

## Verificação

- `flutter analyze` sem erros.
- `flutter test` verde (contagem aumenta com os novos testes; testes ao vivo pulados sem token).
- `flutter build web` ok (o usuário testa no Chrome).
- Sem token configurado, o app abre normalmente e a aba Histórico mostra o aviso.

## Decisões Registradas

- Estrutura pronta para receber o token depois (config constante editável).
- Apenas o detalhe por id é aberto sem token; a lista (e, portanto, o histórico) precisa do token.
- Nova aba própria para Histórico (recurso independente).
