# Contract: ScanDatabase

**Feature**: 002-list-meus-livros | **Layer**: Services

## Métodos Existentes

| Método | Assinatura | Descrição |
|--------|------------|-----------|
| insertScan | `Future<void> insertScan({required String id, required String titulo, String? autor, String? resumo, required int dataCriacao, required List<Map<String, dynamic>> imagens})` | Insere scan e imagens (já implementado) |

## Métodos Novos (Feature 002)

### getScansCount

```dart
/// Retorna o número total de scans na base de dados.
/// Usado na fase 1 do carregamento da lista.
Future<int> getScansCount()
```

**Implementação**: `SELECT COUNT(*) FROM scans`

**Erros**: Propaga exceções do sqflite (ex.: DatabaseException)

---

### getScans

```dart
/// Retorna todos os scans ordenados por data_criacao DESC (mais recente primeiro).
/// Usado na fase 3 do carregamento da lista.
Future<List<Map<String, dynamic>>> getScans()
```

**Retorno**: Lista de maps com chaves: `id`, `titulo`, `autor`, `resumo`, `data_criacao`

**Implementação**: `SELECT id, titulo, autor, resumo, data_criacao FROM scans ORDER BY data_criacao DESC`

**Erros**: Propaga exceções do sqflite

---

### deleteScan

```dart
/// Remove um scan e as suas imagens da base de dados (CASCADE).
/// Usado quando as imagens do scan foram removidas do storage.
Future<void> deleteScan(String id)
```

**Implementação**: `DELETE FROM scans WHERE id = ?` (CASCADE remove imagens)

**Erros**: Propaga exceções do sqflite
