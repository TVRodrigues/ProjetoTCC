# Contract: Scan Storage Service Interface

**Feature**: 001-round-scan-button-storage  
**Type**: Internal service contract (mobile app, no REST API)

## Overview

O `ScanStorageService` é responsável por persistir scans (imagens + metadados) no dispositivo. Esta interface define o contrato que a implementação deve cumprir.

## Operations

### saveScan

Persiste um scan com imagens e metadados.

**Input**:
- `titulo`: String (obrigatório, não vazio)
- `autor`: String? (opcional)
- `resumo`: String? (opcional)
- `imagePaths`: List<String> — caminhos temporários das imagens escaneadas (do Document Scanner)

**Output**: `Future<Scan>` — o Scan persistido com IDs e caminhos finais

**Errors**:
- `StoragePermissionDeniedException`: Permissão de storage negada
- `StorageFullException`: Espaço insuficiente no dispositivo
- `ValidationException`: Título vazio

**Side effects**:
- Copia ficheiros de `imagePaths` para diretório privado da app
- Insere registos em `scans` e `imagens` na base de dados
- Gera ID único para o Scan (UUID ou timestamp-based)

---

### getScans (futuro, fora de âmbito)

Lista todos os scans guardados. **Não implementar nesta feature** (apenas persistir).

---

## Dependencies

- `path_provider`: Obter diretório da app
- `sqflite`: Acesso à base de dados
- `permission_handler`: Verificar/solicitar permissão de storage (quando aplicável)
- `dart:io` File: Copiar ficheiros

## Implementation Notes

- Usar transação ao guardar: inserir Scan + Imagens atomicamente
- Em caso de falha após copiar imagens mas antes de inserir DB: limpar ficheiros copiados (ou deixar orphan; preferir rollback completo)
- Sanitizar título ao criar nome da pasta do scan
