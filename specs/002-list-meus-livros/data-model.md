# Data Model: Feature 002 - Lista Meus Livros

**Branch**: `002-list-meus-livros` | **Date**: 2026-02-26

## Entidades Existentes (Feature 001)

### Scan / Livro

| Campo       | Tipo   | Obrigatório | Descrição                          |
|-------------|--------|-------------|------------------------------------|
| id          | String | Sim         | Identificador único (timestamp)    |
| titulo      | String | Sim         | Título do livro (NOT NULL na BD)   |
| autor       | String?| Não         | Autor                              |
| resumo      | String?| Não         | Resumo ou notas                    |
| data_criacao| int    | Sim         | Unix timestamp (ms)                |
| imagePaths  | List<String> | Sim    | Caminhos das imagens (carregado separadamente) |

**Relacionamentos**: Um Scan tem N Imagens (tabela `imagens` com `scan_id`).

**Validação**: `titulo` nunca vazio (garantido pelo modelo e validação no formulário).

---

## Operações de Dados (Novas para Feature 002)

### ScanDatabase

| Método | Assinatura | Descrição |
|--------|------------|-----------|
| getScansCount | `Future<int> getScansCount()` | Retorna `SELECT COUNT(*) FROM scans` |
| getScans | `Future<List<Map<String, dynamic>>> getScans()` | Retorna scans ordenados por `data_criacao DESC`; colunas: id, titulo, autor, resumo, data_criacao |
| deleteScan | `Future<void> deleteScan(String id)` | Remove scan e imagens (CASCADE); usado quando imagens faltam |

### ScanStorageService (ou extensão)

| Método | Assinatura | Descrição |
|--------|------------|-----------|
| getScansCount | `Future<int> getScansCount()` | Delega a ScanDatabase.getScansCount |
| loadScans | `Future<List<Scan>> loadScans()` | Carrega scans com imagePaths; delega a ScanDatabase + path resolution |
| deleteScan | `Future<void> deleteScan(String id)` | Remove ficheiros da pasta do scan + chama ScanDatabase.deleteScan |

### Carregamento de imagePaths

Para a lista "Meus Livros", apenas `id` e `titulo` são necessários para exibir os itens. O `loadScans` pode carregar imagePaths para validação ao abrir TelaAR (verificar se ficheiros existem). Alternativa: carregar imagePaths sob demanda ao navegar para TelaAR.

**Decisão**: `getScans()` retorna apenas metadados (id, titulo, autor, resumo, data_criacao). O `Scan.fromMap` para lista usa `imagePaths: []` ou carrega paths da tabela imagens se necessário para validação. Para MVP: `loadScans` carrega tudo (metadados + paths) para permitir verificação de existência ao abrir RA.

---

## Estados da UI (TelaPrincipal)

| Estado | Descrição | UI |
|--------|-----------|-----|
| loading_count | Fase 1: a buscar quantidade | Skeleton genérico ou spinner breve |
| loading_skeleton | Fase 2: N placeholders com shimmer | N itens skeleton |
| loading_details | Fase 3: a buscar detalhes | Placeholders animados (mesmos N) |
| loaded | Lista com dados | Itens com títulos |
| empty | N = 0 | Mensagem "Nenhum livro guardado..." |
| error | Falha na fase 1 ou 3 | Mensagem genérica + skeleton mantido (FR-010) |

---

## Transições

```
[init] → loading_count
loading_count (N=0) → empty
loading_count (N>0) → loading_skeleton
loading_skeleton → loading_details
loading_details → loaded
loading_count | loading_details (erro) → error (skeleton mantido)
[refresh] → loading_count (reinicia ciclo)
```
