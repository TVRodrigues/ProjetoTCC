# Tasks: Tela Principal - Lista Meus Livros

**Input**: Design documents from `/specs/002-list-meus-livros/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Não incluídos (spec não exige; constitution: "não obrigatórios para protótipos iniciais").

**Organization**: Tasks agrupadas por user story para implementação e validação independente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode correr em paralelo (ficheiros diferentes, sem dependências)
- **[Story]**: User story (US1, US2, US3)
- Paths relativos a `projetotcc/` (raiz Flutter)

---

## Phase 1: Setup

**Purpose**: Dependências e configuração inicial

- [x] T001 [P] Adicionar `shimmer: ^3.0.0` a `projetotcc/pubspec.yaml` e executar `flutter pub get`
- [x] T002 [P] Confirmar que `docs/ARQUITETURA.md` documenta shimmer na stack (já adicionado no plan)

---

## Phase 2: Foundation (Blocking)

**Purpose**: Serviços que bloqueiam todas as user stories

**⚠️ CRITICAL**: Nenhuma user story pode começar sem esta fase

- [x] T003 [US1] Implementar `getScansCount()`, `getScans()`, `deleteScan(String id)` em `projetotcc/lib/services/scan_database.dart` conforme `contracts/scan-database.md`
- [x] T004 [US1] Implementar `getScansCount()`, `loadScans()`, `deleteScan(String id)` em `projetotcc/lib/services/scan_storage_service.dart` conforme `contracts/scan-storage-service.md`

**Checkpoint**: Serviços prontos; implementação das user stories pode começar

---

## Phase 3: User Story 1 - Lista de Livros na Tela Principal (Priority: P1) 🎯 MVP

**Goal**: Tela principal como lista "Meus Livros" com header, skeleton loader em 3 fases, lista scrollável ou mensagem vazia, pull-to-refresh.

**Independent Test**: Abrir app; verificar header "Meus Livros"; skeleton durante carregamento; lista com títulos ou vazia; pull-to-refresh.

- [x] T005 [US1] Refatorar `projetotcc/lib/tela_principal.dart`: substituir body atual por estrutura com AppBar título "Meus Livros", body para lista/empty/skeleton
- [x] T006 [US1] Implementar carregamento em 3 fases em TelaPrincipal: (1) getScansCount → N; (2) se N>0 exibir N placeholders shimmer; (3) loadScans → preencher lista. Se N=0, exibir mensagem vazia (FR-006, FR-008)
- [x] T007 [US1] Criar widget de skeleton loader com shimmer (Shimmer.fromColors) para cada item da lista; cores compatíveis com tema escuro (#121212)
- [x] T008 [US1] Exibir mensagem "Nenhum livro guardado. Toque no botão + para escanear." quando lista vazia (FR-006)
- [x] T009 [US1] Envolver lista em RefreshIndicator; onRefresh chama lógica de carregamento das 3 fases (FR-012)
- [x] T010 [US1] Tratamento de erro (FR-010): se getScansCount ou loadScans falhar, exibir mensagem genérica e manter skeleton

**Checkpoint**: US1 funcional; lista carrega, skeleton, empty, pull-to-refresh

---

## Phase 4: User Story 2 - Navegação para Visualizador RA (Priority: P2)

**Goal**: Tocar num item da lista redireciona para TelaAR com scan_id; tratamento de imagens removidas (toast + delete).

**Independent Test**: Com livro na lista, tocar no item; TelaAR abre. Simular imagens removidas; toast + livro removido.

- [x] T011 [US2] Adicionar parâmetro opcional `String? scanId` a `projetotcc/lib/tela_ar.dart`; manter comportamento atual quando null
- [x] T012 [US2] Em TelaPrincipal, ao tocar num item da lista, navegar para `TelaAR(scanId: scan.id)` (FR-004)
- [x] T013 [US2] Em TelaAR (ou no fluxo de abertura): ao receber scanId, carregar Scan e verificar se imagePaths existem; se não, exibir toast breve, chamar ScanStorageService.deleteScan(id), Navigator.pop e (na TelaPrincipal) refresh da lista (FR-009)

**Checkpoint**: US1 + US2 funcionais; navegação e tratamento de imagens removidas

---

## Phase 5: User Story 3 - FAB Adicionar/Escanear (Priority: P3)

**Goal**: FAB mantido; ao voltar da TelaGaleria com livro guardado, lista atualizada automaticamente.

**Independent Test**: Tocar no FAB; TelaGaleria abre. Guardar livro; voltar; lista mostra o novo livro.

- [x] T014 [US3] Em `projetotcc/lib/main.dart` (TelaGaleria): alterar `Navigator.pop(ctx)` para `Navigator.pop(ctx, true)` quando saveScan tem sucesso; `Navigator.pop(ctx)` (sem valor) quando cancelar (FR-011)
- [x] T015 [US3] Em TelaPrincipal: ao abrir TelaGaleria com `Navigator.push(...).then((result) => ...)`, se `result == true` chamar refresh da lista (FR-011)
- [x] T016 [US3] Garantir FAB visível no centro inferior (FloatingActionButtonLocation.centerFloat), ícone livro+ (FR-005)

**Checkpoint**: Todas as user stories funcionais

---

## Phase 6: Polish

**Purpose**: Validação e ajustes finais

- [x] T017 [P] Executar validação do quickstart.md: abrir app, escanear/guardar, tocar livro, pull-to-refresh
- [x] T018 Verificar conformidade com analysis_options.yaml (flutter analyze)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Sem dependências
- **Phase 2 (Foundation)**: Depende de Phase 1; **BLOQUEIA** todas as user stories
- **Phase 3 (US1)**: Depende de Phase 2
- **Phase 4 (US2)**: Depende de Phase 2 e 3 (TelaPrincipal já tem lista)
- **Phase 5 (US3)**: Depende de Phase 2 e 3
- **Phase 6 (Polish)**: Depende de Phases 3–5

### Within Each User Story

- T005 antes de T006–T010 (estrutura base)
- T006 depende de T003, T004 (loadScans)
- T011 antes de T012, T013 (TelaAR precisa de scanId)
- T014, T015 antes de T016 (fluxo de refresh)

### Parallel Opportunities

- T001 e T002 em paralelo
- T003 e T004 em paralelo (após Phase 1)
- T007, T008 podem ser feitos em paralelo após T006

---

## Implementation Strategy

### MVP First (US1 Only)

1. Phase 1: Setup
2. Phase 2: Foundation
3. Phase 3: US1 (T005–T010)
4. **STOP e VALIDAR**: Lista carrega, skeleton, empty, pull-to-refresh

### Incremental Delivery

1. Setup + Foundation → Base pronta
2. US1 → Lista "Meus Livros" funcional (MVP)
3. US2 → Navegação para RA + tratamento imagens removidas
4. US3 → Refresh ao voltar da TelaGaleria
5. Polish → Validação final
