# Tasks: Substituição Augen por OpenCV - Visualização AR

**Input**: Design documents from `specs/004-opencv-ar-visualization/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Não incluídos (spec não exige; constitution: não obrigatórios para protótipos iniciais).

**Organization**: Tasks agrupadas por user story para implementação e validação independente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode correr em paralelo (ficheiros diferentes, sem dependências)
- **[Story]**: User story (US1, US2, US3)
- Paths relativos a `projetotcc/` (raiz Flutter)

---

## Phase 1: Setup

**Purpose**: Remover Augen e adicionar OpenCV; verificar dependências existentes.

- [ ] T001 Remover dependência augen de projetotcc/pubspec.yaml e executar flutter pub get
- [ ] T002 Adicionar dependência opencv_dart em projetotcc/pubspec.yaml (módulos core, imgproc, features2d, calib3d conforme research.md) e executar flutter pub get
- [ ] T003 [P] Verificar que projetotcc/pubspec.yaml contém camera e permission_handler

---

## Phase 2: Foundation (Blocking)

**Purpose**: Lógica de subconjunto de targets e serviço OpenCV (extração de características, matching). Nenhuma user story pode começar sem esta fase.

**⚠️ CRITICAL**: Nenhuma user story pode começar sem esta fase

- [ ] T004 Implementar lógica de subconjunto de targets em projetotcc/lib/services/ar_opencv_service.dart: dado scanId e imagemId opcional, obter imagens via ScanDatabase.getImagensForScan; filtrar estado_target=sucesso e eh_pagina=true; se imagemId presente retornar essa imagem + até 3 adjacentes antes e 3 depois (máx. 10); senão primeiras 5 (máx. 10); retornar List<String> de caminhos
- [ ] T005 Implementar ArOpencvService em projetotcc/lib/services/ar_opencv_service.dart: inicializar com lista de caminhos de targets; extrair keypoints e descritores (ORB ou AKAZE via opencv_dart) por imagem e guardar em memória; método que recebe frame da câmera e retorna resultado de matching (targetId e homografia/cantos para overlay) conforme contracts/ar-session-opencv.md e research.md

**Checkpoint**: Foundation pronta; implementação das user stories pode começar

---

## Phase 3: User Story 1 - Visualização AR com Reconhecimento de Páginas (Priority: P1) 🎯 MVP

**Goal**: Tela de RA com preview da câmera, reconhecimento de páginas via OpenCV, overlay 3D, hit test na página rastreada, dica aos 5 s, zero targets → pop.

**Independent Test**: Tocar num livro com página verde, abrir tela de RA, apontar câmera para a página física; verificar reconhecimento e ancoragem 3D; toque coloca anotação na página.

- [ ] T006 [US1] Reescrever projetotcc/lib/tela_ar.dart: remover todo o código e imports do Augen; obter subconjunto de targets (via ArOpencvService ou helper); se vazio exibir mensagem e Navigator.pop(context) (FR-012); verificar permissão câmera antes de iniciar preview
- [ ] T007 [US1] Em projetotcc/lib/tela_ar.dart: integrar plugin camera para preview em tempo real e stream de frames; inicializar ArOpencvService com targetPaths; processar frames e quando houver match desenhar overlay 3D (Stack + posição derivada da homografia) conforme contracts/ar-session-opencv.md
- [ ] T008 [US1] Em projetotcc/lib/tela_ar.dart: implementar timer de 5 segundos sem reconhecimento e exibir dica "Aponte para uma página escaneada" (FR-011)
- [ ] T009 [US1] Em projetotcc/lib/tela_ar.dart: implementar hit test apenas quando uma página está rastreada — ao toque, projectar posição na página e adicionar anotação 3D nessa posição (FR-005)
- [ ] T010 [US1] Em projetotcc/lib/tela_ar.dart: manter tema escuro AppBar #1E1E1E e background #121212 (FR-007); em dispose libertar câmera e recursos do ArOpencvService

**Checkpoint**: US1 funcional; fluxo AR com OpenCV operacional

---

## Phase 4: User Story 2 - Integração com Pipeline de Targets Existente (Priority: P2)

**Goal**: Garantir que o fluxo lista de livros → lista de páginas → tela de RA permanece inalterado e que a tela de RA carrega targets a partir do pipeline existente.

**Independent Test**: Escanear página, guardar, ver indicadores na lista de páginas; tocar numa página verde e verificar que a tela de RA abre com targets carregados.

- [ ] T011 [US2] Verificar em projetotcc/lib/tela_lista_paginas.dart que o tap numa página verde navega para TelaAR(scanId: widget.scan.id, imagemId: img.id) sem regressão
- [ ] T012 [US2] Garantir que TargetPipelineService e ScanDatabase não são alterados pela feature 004; TelaAR obtém imagens apenas via getImagensForScan e subconjunto em ArOpencvService

**Checkpoint**: US2 validado; fluxo 003 mantido

---

## Phase 5: User Story 3 - Tratamento de Falhas e Permissões (Priority: P3)

**Goal**: Permissão de câmera verificada antes do preview; mensagem clara se negada; Windows com mensagem "RA disponível apenas em Android e iOS"; falhas de init sem crash.

**Independent Test**: Negar permissão de câmera e abrir tela de RA → mensagem clara. Em Windows tocar numa página verde → mensagem de plataforma.

- [ ] T013 [US3] Em projetotcc/lib/tela_ar.dart: verificar permissão de câmera antes de criar preview; se negada exibir mensagem clara e não entrar em crash (FR-006)
- [ ] T014 [US3] Em projetotcc/lib/tela_lista_paginas.dart ou projetotcc/lib/tela_ar.dart: em Windows, ao invocar abertura da tela de RA exibir mensagem "RA disponível apenas em Android e iOS" e não abrir a tela de RA completa (ou abrir tela placeholder com a mensagem) (FR-009)
- [ ] T015 [US3] Em projetotcc/lib/tela_ar.dart: tratar falha de inicialização da câmera ou do pipeline OpenCV com mensagem explicativa e sem crash

**Checkpoint**: US3 funcional; Tela AR robusta em falhas e em Windows

---

## Phase 6: Polish & Cross-Cutting

**Purpose**: Documentação e validação final

- [ ] T016 [P] Atualizar docs/ARQUITETURA.md: substituir Augen por OpenCV na stack; documentar ArOpencvService; indicar que a tela de RA com OpenCV é suportada apenas em Android e iOS (Constitution I, III)
- [ ] T017 Executar validação do quickstart.md em specs/004-opencv-ar-visualization/quickstart.md (checklist de verificações)
- [ ] T018 Executar flutter analyze em projetotcc/ e corrigir avisos do linter

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Sem dependências
- **Phase 2 (Foundation)**: Depende de Phase 1; **BLOQUEIA** todas as user stories
- **Phase 3 (US1)**: Depende de Phase 2 — MVP completo
- **Phase 4 (US2)**: Depende de Phase 3 (TelaAR já reescrita; verificação de integração)
- **Phase 5 (US3)**: Depende de Phase 3 (tratamento de falhas na TelaAR)
- **Phase 6 (Polish)**: Depende de Phases 3–5

### Within Each User Story

- **US1**: T006–T010 em sequência lógica (T006 reescreve tela; T007 integra pipeline; T008–T010 comportamentos específicos)
- **US2**: T011–T012 verificação; podem ser em paralelo
- **US3**: T013–T015 em projetotcc/lib/tela_ar.dart e tela_lista_paginas.dart

### Parallel Opportunities

- T001 e T003 após leitura do pubspec (T002 depende de T001)
- T011 e T012 (US2) em paralelo
- T016 com T017/T018 em paralelo após stories concluídas

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (remover augen, adicionar opencv_dart)
2. Phase 2: Foundation (ArOpencvService + subconjunto)
3. Phase 3: US1 completo
4. **STOP e VALIDAR**: Abrir livro, página verde, tela AR, reconhecer página, overlay 3D, hit test, dica 5 s, zero targets → pop
5. Deploy/demo se estável

### Incremental Delivery

1. Foundation → US1 → Validar MVP
2. US2 → Validar fluxo 003 intacto
3. US3 → Validar falhas e Windows
4. Polish → Documentação e quickstart

### Suggested Order (Sequential)

```
T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008 → T009 → T010
       → T011 → T012 → T013 → T014 → T015 → T016 → T017 → T018
```

---

## Summary

| Métrica | Valor |
|---------|--------|
| **Total tasks** | 18 |
| **US1 (P1)** | 5 |
| **US2 (P2)** | 2 |
| **US3 (P3)** | 3 |
| **Setup** | 3 |
| **Foundation** | 2 |
| **Polish** | 3 |
| **Parallelizable** | T003, T011, T012, T016 |
| **MVP scope** | Phases 1–3 (T001–T010) |
