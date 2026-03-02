# Tasks: Pipeline de Targets AR para Páginas Escaneadas

**Input**: Design documents from `/specs/003-ar-target-pipeline/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Não incluídos (spec não exige; constitution: "não obrigatórios para protótipos iniciais").

**Organization**: Tasks agrupadas por user story para implementação e validação independente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode correr em paralelo (ficheiros diferentes, sem dependências)
- **[Story]**: User story (US1, US2, US3)
- Paths relativos a `projetotcc/` (raiz Flutter)

---

## Phase 1: Setup

**Purpose**: Verificar dependências existentes; sem novas dependências (Constitution III)

- [x] T001 [P] Verificar que `projetotcc/pubspec.yaml` contém augen, google_mlkit_text_recognition, sqflite, path_provider

---

## Phase 2: Foundation (Blocking)

**Purpose**: Schema DB, model ImagemPage, extensões ScanDatabase e ScanStorageService

**⚠️ CRITICAL**: Nenhuma user story pode começar sem esta fase

- [x] T002 Implementar migration v2 em `projetotcc/lib/services/scan_database.dart`: incrementar `_version` para 2; em `onUpgrade` executar ALTER TABLE imagens ADD COLUMN para numero_pagina, eh_pagina, estado_target, qualidade_target; criar índice idx_imagens_scan_ordem
- [x] T003 [P] Criar model `ImagemPage` e enum `EstadoTarget` em `projetotcc/lib/models/imagem_page.dart` conforme data-model.md
- [x] T004 Estender `ScanDatabase`: adicionar `getImagensForScan(scanId)` retornando `List<ImagemPage>` ordenado por COALESCE(numero_pagina, ordem), ordem; `updateImagemEstado`, `updateImagemPath`, `updateImagemMetadata`; adaptar `insertScan` para aceitar novas colunas (estado_target, eh_pagina, numero_pagina, qualidade_target)
- [x] T005 Estender `ScanStorageService` em `projetotcc/lib/services/scan_storage_service.dart`: ao inserir imagens via `insertScan`, incluir `estado_target: 'processando'`, `eh_pagina: 1` (default) nos mapas de imagens

**Checkpoint**: Foundation pronta; implementação das user stories pode começar

---

## Phase 3: User Story 1 - Reconhecimento de Página como Target AR (Priority: P1) 🎯 MVP

**Goal**: Fluxo completo: ao guardar scan, processar imagens em background; lista de páginas com indicadores (amarelo/verde/vermelho/roxo/cinzento); tap verde → TelaAR com Image Tracking; tap vermelho → retry; tap roxo → TelaRescan.

**Independent Test**: Escanear página, guardar, tocar no livro; verificar lista com indicadores; tap verde → TelaAR reconhece página física; tap vermelho inicia retry; tap roxo abre scanner único.

- [x] T006 [P] [US1] Criar `ImageAnalysisService` em `projetotcc/lib/services/image_analysis_service.dart`: `analyze(path)` → `ImageAnalysisResult` (ehPagina, numeroPagina?, qualidadeTarget?); usar ML Kit text recognition para heurística eh_pagina; MVP: numeroPagina=null para todas
- [x] T007 [US1] Criar `TargetPipelineService` em `projetotcc/lib/services/target_pipeline_service.dart`: `processScan(scanId)`, `retryImage(imagemId)`, `replaceImageForRescan(imagemId, novoPath)`; `Stream<ImagemPageUpdate> pageUpdates`; integrar ImageAnalysisService e ScanDatabase conforme contracts/target-pipeline-service.md
- [x] T008 [US1] Criar `TelaListaPaginas` em `projetotcc/lib/tela_lista_paginas.dart`: recebe Scan; carrega imagens via `getImagensForScan`; ListView com indicadores por estado (amarelo/verde/vermelho/roxo/cinzento); tap verde → `Navigator.push(TelaAR(scanId, imagemId))`; tap vermelho → `retryImage`; tap roxo → `Navigator.push(TelaRescan(...))`; inscrever em `pageUpdates` para rebuild automático
- [x] T009 [US1] Alterar `TelaPrincipal` em `projetotcc/lib/tela_principal.dart`: em `_abrirLivro`, navegar para `TelaListaPaginas(scan: scan)` em vez de `TelaAR(scanId: scan.id)`
- [x] T010 [US1] Alterar `TelaAR` em `projetotcc/lib/tela_ar.dart`: adicionar Image Tracking conforme contracts/ar-session-contract.md; carregar imagens com estado_target=sucesso e eh_pagina=true; `addImageTarget` para cada; `setImageTrackingEnabled(true)`; `trackedImagesStream` para ancorar modelo 3D com `addNodeToTrackedImage`
- [x] T011 [US1] Criar `TelaRescan` em `projetotcc/lib/tela_rescan.dart`: recebe scanId e imagemId; Document Scanner com `pageLimit: 1`; ao capturar, chamar `TargetPipelineService.replaceImageForRescan(imagemId, novoCaminho)` e `Navigator.pop(context, true)`
- [x] T012 [US1] Alterar `TelaGaleria` em `projetotcc/lib/main.dart`: após `saveScan` sucesso, chamar `TargetPipelineService().processScan(scanId)` antes de `Navigator.pop(context, true)`
- [x] T013 [US1] Em `TelaListaPaginas`: garantir que páginas com estado `nao_pagina` (cinzento) não abrem TelaAR ao toque; apenas visualização

**Checkpoint**: US1 funcional; fluxo completo de reconhecimento e rescan

---

## Phase 4: User Story 2 - Análise de Imagem e Número da Página (Priority: P2)

**Goal**: Extrair numero_pagina (0=capa, null se não detectável); detecção de capa por layout; ordenação correta na lista.

**Independent Test**: Escanear capa e páginas internas; guardar; verificar na BD que capa tem numero_pagina=0 e demais têm números ou null.

- [x] T014 [US2] Estender `ImageAnalysisService.analyze`: implementar extração de numero_pagina via regex sobre texto ML Kit (padrões "42", "Pág. 42", "— 42 —"); retornar null se não detectável
- [x] T015 [US2] Estender `ImageAnalysisService.analyze`: implementar detecção de capa por heurística de layout (bloco de texto grande, central, no terço superior) → numero_pagina=0
- [x] T016 [US2] Estender `ImageAnalysisService.analyze`: calcular qualidade_target (0–100) por heurística de contraste/densidade de texto conforme research.md
- [x] T017 [US2] Garantir que `ScanDatabase.getImagensForScan` ordena por `COALESCE(numero_pagina, 9999), ordem` conforme data-model.md
- [x] T018 [US2] Garantir que `TargetPipelineService` persiste numero_pagina, qualidade_target do ImageAnalysisResult ao atualizar imagens

**Checkpoint**: US2 funcional; capa e números de página extraídos e ordenados

---

## Phase 5: User Story 3 - Tela de RA Funcional (Priority: P3)

**Goal**: Tela AR com falha graciosa (permissão, hardware não suportado); ancoragem correta de conteúdo 3D em targets rastreados.

**Independent Test**: Tocar livro → lista → tap verde; TelaAR abre; sem permissão ou AR não suportado → mensagem clara, sem crash; com permissão → apontar para página e ancorar modelo 3D.

- [x] T019 [US3] Em `TelaAR`: verificar permissão câmera antes de criar AugenView; exibir mensagem clara se negada (Constitution V)
- [x] T020 [US3] Em `TelaAR`: manter tratamento existente de `isARSupported`; mensagem "Serviço ARCore desatualizado" ou equivalente; não crash
- [x] T021 [US3] Em `TelaAR`: assegurar que `addNodeToTrackedImage` ancore o modelo 3D (Astronaut.glb ou equivalente) na posição correta quando `trackedImage.isTracked && trackedImage.isReliable`
- [x] T022 [US3] Em `TelaAR`: manter tema escuro (AppBar #1E1E1E, background #121212) conforme Constitution

**Checkpoint**: US3 funcional; Tela AR robusta e operacional

---

## Phase 6: Polish & Cross-Cutting

**Purpose**: Documentação e validação final

- [x] T023 [P] Atualizar `docs/ARQUITETURA.md`: adicionar TelaListaPaginas, TelaRescan, TargetPipelineService, ImageAnalysisService; atualizar fluxo de navegação; referenciar migration DB v2
- [ ] T024 Executar validação do quickstart.md: checklist de verificações (lista páginas, indicadores, tap verde/vermelho/roxo, reconhecimento AR, rescan)
- [x] T025 Executar `flutter analyze` em projetotcc/ e corrigir avisos do linter

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Sem dependências
- **Phase 2 (Foundation)**: Depende de Phase 1; **BLOQUEIA** todas as user stories
- **Phase 3 (US1)**: Depende de Phase 2 — MVP completo
- **Phase 4 (US2)**: Depende de Phase 2 e 3 (ImageAnalysisService já existe; estender)
- **Phase 5 (US3)**: Depende de Phase 3 (TelaAR já alterada; polish)
- **Phase 6 (Polish)**: Depende de Phases 3–5

### Within Each User Story

- **US1**: T006, T007 antes de T008–T013; T007 usa T006; T008 usa T007; T010 depende de T008
- **US2**: T014–T016 em paralelo (após T006); T017, T018 depois
- **US3**: T019–T022 podem ser feitos em paralelo após T010

### Parallel Opportunities

- T002 e T003 em paralelo (após T001)
- T014, T015, T016 em paralelo (US2)
- T019, T020, T021, T022 em paralelo (US3)
- T023 e T024 podem correr em paralelo

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (verificar deps)
2. Phase 2: Foundation (DB migration, ImagemPage, ScanDatabase, ScanStorageService)
3. Phase 3: US1 completo
4. **STOP e VALIDAR**: Escanear, guardar, abrir livro, ver indicadores, tap verde, reconhecer página, retry, rescan
5. Deploy/demo se estável

### Incremental Delivery

1. Foundation → US1 → Validar MVP
2. US2 → Validar análise de capa/número
3. US3 → Validar Tela AR robusta
4. Polish → Documentação e quickstart

### Suggested Order (Sequential)

```
T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008 → T009 → T010 → T011 → T012 → T013
       → T014 → T015 → T016 → T017 → T018 → T019 → T020 → T021 → T022 → T023 → T024 → T025
```

---

## Summary

| Métrica | Valor |
|---------|-------|
| **Total tasks** | 25 |
| **US1 (P1)** | 8 |
| **US2 (P2)** | 5 |
| **US3 (P3)** | 4 |
| **Setup** | 1 |
| **Foundation** | 4 |
| **Polish** | 3 |
| **Parallelizable** | T001, T003, T014–T016, T019–T022, T023 |
| **MVP scope** | Phases 1–3 (T001–T013) |
