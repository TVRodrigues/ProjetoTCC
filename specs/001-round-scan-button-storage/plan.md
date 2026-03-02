# Implementation Plan: Botão Escanear Redondo + Persistência de Scans

**Branch**: `001-round-scan-button-storage` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-round-scan-button-storage/spec.md`

## Summary

Redesenhar o botão "Escanear nova página" como botão redondo fixo no centro inferior da tela principal, com ícone livro+; substituir o botão retangular atual. Ao tocar, abrir TelaGaleria. Implementar persistência: imagens em diretório privado da app (path_provider), metadados em SQLite (sqflite). O botão "Gerar Targets de RA" abre popup com título obrigatório; após salvar, persiste dados, redireciona e exibe SnackBar de confirmação.

## Technical Context

**Language/Version**: Dart ^3.11.0, Flutter SDK  
**Primary Dependencies**: path_provider ^2.1.x (app directory), sqflite ^2.3.x (SQLite), permission_handler ^11.4.0 (existente), google_mlkit_document_scanner ^0.4.1 (existente)  
**Storage**: path_provider getApplicationDocumentsDirectory para imagens; sqflite para metadados (scans, imagens)  
**Testing**: flutter_test (widget tests para fluxos críticos)  
**Target Platform**: Android minSdk 24, iOS, Windows  
**Project Type**: mobile (Flutter)  
**Performance Goals**: Fluxo escanear→salvar em <1 min para 5 páginas; botão responde em <2s  
**Constraints**: Offline-only; diretório privado da app (sem permissões adicionais em Android 10+ para app dir)  
**Scale/Scope**: ~100 scans por utilizador; até 20 páginas por scan

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify compliance with `.specify/memory/constitution.md`:

- **I. Documentation-First**: ✅ Alterações em ARQUITETURA.md (nova camada de serviços: storage, DB)
- **II. Presentation + Services**: ✅ Lógica de persistência em `lib/services/`; widgets em `lib/`
- **III. Flutter Stack**: ✅ path_provider e sqflite são dependências Flutter padrão; documentar em ARQUITETURA
- **IV. Simplicity**: ✅ Sem Provider/Riverpod; serviço simples de storage; YAGNI aplicado
- **V. Permissions & Privacy**: ✅ Permissão de storage solicitada no momento de guardar; falhas tratadas com mensagem

## Project Structure

### Documentation (this feature)

```text
specs/001-round-scan-button-storage/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (storage interface)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (projetotcc/)

```text
projetotcc/
├── lib/
│   ├── main.dart                    # App, TelaGaleria (refatorar)
│   ├── tela_principal.dart          # Hub: botão redondo FAB, navegação
│   ├── tela_ar.dart                 # (inalterado)
│   ├── models/
│   │   └── scan.dart                # Modelo Scan (título, autor, resumo, imagens)
│   └── services/
│       ├── scan_storage_service.dart # Persistência: imagens + DB
│       └── scan_database.dart       # Inicialização SQLite, CRUD
└── test/
    └── widget/                      # (opcional) testes de fluxo
```

**Structure Decision**: Mobile Flutter single-project. Nova pasta `lib/models/` para entidade Scan; `lib/services/` para lógica de persistência (camada de serviços conforme constituição). TelaPrincipal passa a usar FloatingActionButton centralizado em vez de ElevatedButton.

## Complexity Tracking

> Nenhuma violação; tabela vazia.
