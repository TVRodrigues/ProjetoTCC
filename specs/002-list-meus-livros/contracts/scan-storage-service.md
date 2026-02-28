# Contract: ScanStorageService

**Feature**: 002-list-meus-livros | **Layer**: Services

## Métodos Existentes

| Método | Assinatura | Descrição |
|--------|------------|-----------|
| saveScan | `Future<Scan> saveScan({required String titulo, String? autor, String? resumo, required List<String> imagePaths})` | Persiste scan (já implementado) |

## Métodos Novos (Feature 002)

### getScansCount

```dart
/// Delega a ScanDatabase.getScansCount().
Future<int> getScansCount()
```

---

### loadScans

```dart
/// Carrega todos os scans com imagePaths, ordenados por data_criacao DESC.
/// Usado na fase 3 do carregamento da lista e para validação ao abrir TelaAR.
Future<List<Scan>> loadScans()
```

**Implementação**:
1. Chamar `ScanDatabase.getScans()` para metadados
2. Para cada scan, obter paths da tabela `imagens` (ou JOIN)
3. Retornar `List<Scan>` com `Scan.fromMap` + paths

**Erros**: Propaga exceções do ScanDatabase

---

### deleteScan

```dart
/// Remove um scan: ficheiros da pasta + registos na BD.
/// Usado quando as imagens foram removidas do storage (FR-009).
Future<void> deleteScan(String id)
```

**Implementação**:
1. Obter caminho da pasta do scan (ex.: `{documents}/scans/{folderName}`)
2. Remover ficheiros da pasta (se existir)
3. Chamar `ScanDatabase.deleteScan(id)`

**Erros**: Propaga exceções; falhas em delete de ficheiros não devem impedir delete na BD
