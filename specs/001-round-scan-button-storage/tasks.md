# Tasks: Botão Escanear Redondo + Persistência de Scans

**Input**: Design documents from `/specs/001-round-scan-button-storage/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/, research.md, quickstart.md

**Tests**: Not explicitly requested in spec; no test tasks included.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Maps to user story (US1, US2, US3)
- All paths relative to `projetotcc/` (Flutter project root)

## Path Conventions

- **Mobile Flutter**: `projetotcc/lib/`, `projetotcc/test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependencies

- [x] T001 Add path_provider ^2.1.1 and sqflite ^2.3.0 to projetotcc/pubspec.yaml
- [x] T002 Run flutter pub get in projetotcc/
- [x] T003 [P] Create projetotcc/lib/models/ directory
- [x] T004 [P] Create projetotcc/lib/services/ directory

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core persistence layer that US3 (popup) depends on

**⚠️ CRITICAL**: US3 cannot begin until this phase is complete

- [x] T005 [P] [US2] Create Scan model in projetotcc/lib/models/scan.dart with id, titulo, autor, resumo, dataCriacao, imagePaths
- [x] T006 [US2] Create ScanDatabase in projetotcc/lib/services/scan_database.dart with schema from data-model.md (scans + imagens tables)
- [x] T007 [US2] Implement ScanStorageService.saveScan in projetotcc/lib/services/scan_storage_service.dart: copy images to app dir (path_provider), insert Scan + Imagens in DB, sanitize titulo for folder name
- [x] T008 [US2] Add permission check/request in ScanStorageService before saving (permission_handler storage when applicable)
- [x] T009 [US2] Add error handling in ScanStorageService for permission denied and storage full (FR-009); show clear messages via callback or throw typed exceptions

**Checkpoint**: Persistence layer ready; US1 and US3 can proceed

---

## Phase 3: User Story 1 - Botão Redondo de Escanear (Priority: P1) 🎯 MVP

**Goal**: Botão redondo no centro inferior com ícone livro+, abre TelaGaleria

**Independent Test**: Verificar botão na posição correta, ícone livro+, tocar abre TelaGaleria

### Implementation for User Story 1

- [x] T010 [US1] In projetotcc/lib/tela_principal.dart, remove ElevatedButton.icon "1. Escanear Nova Página"
- [x] T011 [US1] Add FloatingActionButton with Stack of Icons.menu_book + Icons.add (or Icons.add_circle) in projetotcc/lib/tela_principal.dart
- [x] T012 [US1] Set Scaffold.floatingActionButtonLocation to FloatingActionButtonLocation.centerFloat in projetotcc/lib/tela_principal.dart
- [x] T013 [US1] Wire FloatingActionButton onPressed to Navigator.push for TelaGaleria (preserve _simularProcessamentoNaNuvem after return)
- [x] T014 [US1] Keep "2. Abrir Visualizador RA" button and card layout; ensure FAB does not overlap content

**Checkpoint**: User Story 1 complete; botão redondo works independently

---

## Phase 4: User Story 3 - Formulário Popup de Título e Redirecionamento (Priority: P3)

**Goal**: "Gerar Targets de RA" opens popup; título obrigatório; save persists, redirects, SnackBar

**Independent Test**: TelaGaleria com páginas → tocar "Gerar Targets" → popup; salvar sem título bloqueado; preencher título → salvar → redirect + SnackBar

### Implementation for User Story 3

- [x] T015 [US3] In projetotcc/lib/main.dart TelaGaleria, set "GERAR TARGETS DE RA" button to disabled (grey) when _paginasEscaneadas.isEmpty
- [x] T016 [US3] Replace _salvarTargets in projetotcc/lib/main.dart to open showDialog with form: título (TextFormField, required), autor, resumo (optional)
- [x] T017 [US3] Add validation: block Save button or show error when título is empty (FR-006)
- [x] T018 [US3] On popup Save: call ScanStorageService().saveScan(titulo, autor, resumo, _paginasEscaneadas)
- [x] T019 [US3] On save success: Navigator.pop(context) to close TelaGaleria, then ScaffoldMessenger.showSnackBar "Scan guardado com sucesso"
- [x] T020 [US3] On save error (permission, storage full): show SnackBar with error message; do not close popup or lose data
- [x] T021 [US3] On popup Cancel: close dialog, remain in TelaGaleria with _paginasEscaneadas intact

**Checkpoint**: User Story 3 complete; full flow escanear → popup → salvar → redirect works

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases and documentation

- [x] T022 Add WRITE_EXTERNAL_STORAGE for Android <10 in projetotcc/android/app/src/main/AndroidManifest.xml if not present (per quickstart.md)
- [x] T023 [P] Update docs/ARQUITETURA.md if any structure changed during implementation
- [x] T024 Run quickstart.md validation: flutter run, test full flow (botão → scan → popup → save → persist)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup; BLOCKS US3
- **US1 (Phase 3)**: No dependencies on Foundation; can run in parallel with Phase 2
- **US2**: Delivered by Foundation (Phase 2)
- **US3 (Phase 4)**: Depends on Phase 2 (ScanStorageService)
- **Polish (Phase 5)**: Depends on Phases 3–4

### User Story Dependencies

- **US1**: Independent; can start after Setup
- **US2**: Delivered by Foundation (Phase 2)
- **US3**: Depends on Foundation; needs ScanStorageService

### Parallel Opportunities

- T003, T004: Create directories in parallel
- T005: Scan model can run in parallel with T006
- US1 (T010–T014) can run in parallel with Phase 2 if different developer
- T024, T025: Can run in parallel in Polish phase

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 3: User Story 1 (botão redondo)
3. **STOP and VALIDATE**: Test botão redondo independently
4. Deploy/demo

### Incremental Delivery

1. Setup + US1 → MVP (botão redondo)
2. Foundation (Phase 2) → Persistence layer ready
3. US3 (Phase 5) → Full flow: scan → popup → save → persist
4. Polish → Edge cases, docs

### Task Count Summary

| Phase | Tasks | Story |
|-------|-------|-------|
| Setup | T001–T004 | — |
| Foundation | T005–T009 | US2 |
| US1 | T010–T014 | US1 |
| US3 | T015–T021 | US3 |
| Polish | T022–T024 | — |
| **Total** | **24** | — |
