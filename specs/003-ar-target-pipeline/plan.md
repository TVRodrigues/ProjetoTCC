# Implementation Plan: Pipeline de Targets AR para Páginas Escaneadas

**Branch**: `003-ar-target-pipeline` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-ar-target-pipeline/spec.md`

## Summary

Pipeline local para gerar targets AR a partir de páginas escaneadas. Após guardar um scan, o sistema processa imagens em background (análise ML Kit: eh_pagina, numero_pagina), atualiza estado por página (amarelo→verde/vermelho/roxo/cinzento), e usa Augen Image Tracking para reconhecimento em tempo real. FR-005 é satisfeito via ARCore/ARKit (imagem como referência; extração/matching internos). Nova tela de lista de páginas entre lista principal e tela RA; fluxo de rescan substitui imagem (ficheiro + path na BD) para páginas que falham após retry.

## Technical Context

**Language/Version**: Dart ^3.11.0  
**Primary Dependencies**: Flutter SDK, augen ^1.0.2, google_mlkit_text_recognition ^0.15.1, sqflite ^2.3.0  
**Storage**: SQLite (sqflite), path_provider (ficheiros locais)  
**Testing**: flutter_test (recomendado para serviços críticos; não obrigatório para protótipo)  
**Target Platform**: Android (minSdk 24, targetSdk 36), iOS 13+, Windows  
**Project Type**: mobile  
**Performance Goals**: Reconhecimento AR em <3s (SC-001), 80% targets utilizáveis (SC-002)  
**Constraints**: Offline-capable, processamento local, sem backend  
**Scale/Scope**: ~5–10 telas, livros com até 20 páginas por scan  

## Constitution Check

*GATE: Passed. Re-verified after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Documentation-First** | ✅ | ARQUITETURA.md será atualizado com nova tela, serviços TargetPipeline/ImageAnalysis, migração DB |
| **II. Presentation + Services** | ✅ | TelaListaPaginas, TelaRescan = apresentação; TargetPipelineService, ImageAnalysisService = serviços |
| **III. Flutter Stack** | ✅ | Sem novas dependências; augen e ML Kit já no projeto |
| **IV. Simplicity** | ✅ | Sem Provider/Riverpod; Stream local; processamento local (sem backend) |
| **V. Permissions & Privacy** | ✅ | Câmera na TelaAR e TelaRescan; verificação antes de iniciar; falha graciosa |

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
projetotcc/
├── lib/
│   ├── main.dart
│   ├── tela_principal.dart      # alterar: tap livro → TelaListaPaginas
│   ├── tela_lista_paginas.dart # novo
│   ├── tela_ar.dart            # alterar: Image Tracking
│   ├── tela_rescan.dart        # novo (ou modo em TelaGaleria)
│   ├── models/
│   │   ├── scan.dart
│   │   └── imagem_page.dart    # novo
│   └── services/
│       ├── scan_storage_service.dart
│       ├── scan_database.dart   # migration v2
│       ├── target_pipeline_service.dart  # novo
│       └── image_analysis_service.dart   # novo
├── android/
├── ios/
└── pubspec.yaml
```

**Structure Decision**: Projeto Flutter monolítico (Option 3: mobile). Código em `projetotcc/lib/`. Nenhum backend; processamento local.

## Complexity Tracking

Nenhuma violação. Secção vazia.
