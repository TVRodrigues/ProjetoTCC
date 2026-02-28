# Implementation Plan: Tela Principal - Lista Meus Livros

**Branch**: `002-list-meus-livros` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/002-list-meus-livros/spec.md`

## Summary

Transformar a TelaPrincipal num hub de lista "Meus Livros": header fixo, lista scrollável de scans guardados (botões com título), skeleton loader em 3 fases (count → placeholders → detalhes), pull-to-refresh, FAB para escanear, navegação para TelaAR com scan_id. Tratamento de edge cases: lista vazia, imagens removidas (toast + delete), falha de BD (mensagem genérica).

## Technical Context

**Language/Version**: Dart ^3.11.0, Flutter SDK  
**Primary Dependencies**: shimmer ^3.0.0 (novo), sqflite, path_provider, permission_handler  
**Storage**: SQLite (sqflite) + ficheiros em path_provider  
**Testing**: flutter_test (recomendado para crítico; não obrigatório para protótipo)  
**Target Platform**: Android (minSdk 24), iOS, Windows  
**Project Type**: Mobile (Flutter)  
**Performance Goals**: Lista visível em <2s (SC-001)  
**Constraints**: Tema escuro (#121212), análise_options.yaml (flutter_lints)  
**Scale/Scope**: Lista local; sem paginação (ListView com todos os itens)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Documentation-First**: shimmer será documentado em docs/ARQUITETURA.md
- **II. Presentation + Services**: Nova lógica em TelaPrincipal (apresentação) e ScanDatabase/ScanStorageService (serviços)
- **III. Flutter Stack**: shimmer é pacote Flutter; sem alteração de stack
- **IV. Simplicity**: Sem Provider/Riverpod; estado local em TelaPrincipal; YAGNI respeitado
- **V. Permissions & Privacy**: Sem novas permissões; tratamento de erro gracioso (toast, mensagem)

## Project Structure

### Documentation (this feature)

```text
specs/002-list-meus-livros/
├── plan.md              # Este ficheiro
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/           # Phase 1
│   ├── scan-database.md
│   └── scan-storage-service.md
└── tasks.md             # Phase 2 (/speckit.tasks)
```

### Source Code (repository root)

```text
projetotcc/
├── lib/
│   ├── main.dart               # TelaGaleria (alterar Navigator.pop)
│   ├── tela_principal.dart      # Refatorar: lista Meus Livros
│   ├── tela_ar.dart             # Adicionar scanId opcional
│   ├── models/
│   │   └── scan.dart
│   └── services/
│       ├── scan_database.dart   # +getScansCount, getScans, deleteScan
│       └── scan_storage_service.dart  # +getScansCount, loadScans, deleteScan
├── pubspec.yaml                 # +shimmer
└── ...
```

**Structure Decision**: Projeto Flutter monolítico; alterações em lib/ conforme ARQUITETURA.md.

## Complexity Tracking

Nenhuma violação; tabela vazia.
