# Contract: Target Pipeline Service

**Feature**: 003-ar-target-pipeline  
**Type**: Internal service contract (Flutter, camada de serviços)

## Overview

O `TargetPipelineService` processa imagens de um scan em background, determina `eh_pagina` e `numero_pagina`, registra targets para Augen, e atualiza o estado (`estado_target`) na base de dados. A UI escuta um `Stream` de atualizações.

## Operations

### processScan

Inicia o processamento assíncrono de todas as imagens de um scan.

**Input**:
- `scanId`: String

**Output**: `Future<void>`

**Side effects**:
- Para cada imagem com `estado_target = 'processando'`:
  1. Chama `ImageAnalysisService.analyze(caminho)` → `eh_pagina`, `numero_pagina`, `qualidade_target`
  2. Se `eh_pagina == false` → atualiza DB: `estado_target = 'nao_pagina'`, emite no Stream
  3. Se `eh_pagina == true`: registra target (imagem já serve como referência; nenhum ficheiro adicional)
  4. Atualiza DB: `numero_pagina`, `eh_pagina`, `qualidade_target`, `estado_target = 'sucesso'`; emite no Stream
  5. Em falha: `estado_target = 'falha'`; emite no Stream

**Stream de atualizações**:
- `Stream<ImagemPageUpdate> get pageUpdates` — emite quando uma imagem muda de estado
- `ImagemPageUpdate`: `{ scanId, imagemId, estadoTarget, ... }`

---

### retryImage

Reprocessa uma imagem que falhou (estado `falha`).

**Input**:
- `imagemId`: int

**Output**: `Future<void>`

**Side effects**:
- Atualiza `estado_target = 'processando'`
- Repete análise + registro; se falhar novamente → `estado_target = 'rescan'`
- Emite no Stream

---

### replaceImageForRescan

Substitui uma imagem (estado `rescan`) por nova captura.

**Input**:
- `imagemId`: int
- `novoCaminho`: String — path da nova imagem capturada pelo scanner

**Output**: `Future<void>`

**Side effects**:
- Substitui ficheiro no filesystem (ou copia para path final)
- Atualiza `imagens.caminho`, `estado_target = 'processando'`
- Reinicia processamento para essa imagem
- Emite no Stream

---

## Dependencies

- `ScanDatabase`: CRUD de imagens
- `ImageAnalysisService`: análise de layout e número da página
- `google_mlkit_text_recognition`: OCR
- `path_provider`, `dart:io`: gestão de ficheiros

## Implementation Notes

- Executar processamento em `compute()` ou `Isolate` para não bloquear UI
- Augen não requer pré-processamento; a imagem em `caminho` é usada diretamente como `ARImageTarget`
- Physical size padrão: `ImageTargetSize(0.21, 0.297)` (A5)
