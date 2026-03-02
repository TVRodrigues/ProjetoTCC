# Implementation Plan: Substituição Augen por OpenCV - Visualização AR

**Branch**: `004-opencv-ar-visualization` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `specs/004-opencv-ar-visualization/spec.md`

## Summary

Remover toda a dependência e código do plugin Augen e implementar o fluxo de visualização AR (câmera em tempo real, reconhecimento de imagens, sobreposição de modelos 3D) usando OpenCV. Manter o fluxo de navegação existente (lista de livros → lista de páginas → tela de RA). Plataformas: Android e iOS apenas (Windows fora do âmbito). Hit test apenas sobre página rastreada; subconjunto de targets por sessão; dica aos 5 s sem reconhecimento; zero targets → redirecionar à lista.

## Technical Context

**Language/Version**: Dart ^3.11.0, Flutter SDK  
**Primary Dependencies**: camera, permission_handler, opencv_dart (ou equivalente — ver research.md); remoção de augen  
**Storage**: N/A (usa scan_database e path_provider existentes)  
**Testing**: flutter test (recomendado para crítico; não obrigatório para protótipo)  
**Target Platform**: Android (minSdk 24), iOS; Windows fora do âmbito para esta feature  
**Project Type**: mobile (Flutter app em projetotcc/)  
**Performance Goals**: Reconhecimento e ancoragem 3D em &lt;5 s após apontar; feed câmera fluido  
**Constraints**: Tema escuro (AppBar #1E1E1E, #121212); permissão câmera no momento de uso; sem crash em falha  
**Scale/Scope**: Subconjunto de targets por sessão (ex.: página escolhida + adjacentes ou N); limite de ordem de dezenas de imagens por livro

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Documentation-First**: Alteração de stack (augen → OpenCV) MUST ser refletida em `docs/ARQUITETURA.md` antes do merge
- **II. Presentation + Services**: TelaAR permanece na camada de apresentação; lógica OpenCV (detecção, matching, pose) em serviço ou plugin
- **III. Flutter Stack**: Nova dependência OpenCV MUST ser documentada em ARQUITETURA.md; augen removido
- **IV. Simplicity**: Sem plane detection; hit test só em página rastreada; subconjunto de targets para evitar complexidade
- **V. Permissions & Privacy**: Verificação de permissão câmera antes do visualizador; mensagem clara em falha; sem crash

## Project Structure

### Documentation (this feature)

```text
specs/004-opencv-ar-visualization/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/           # Phase 1 (ar-session-opencv contract)
└── tasks.md             # Phase 2 (/speckit.tasks)
```

### Source Code (repository root)

```text
projetotcc/
├── lib/
│   ├── main.dart
│   ├── tela_principal.dart
│   ├── tela_lista_paginas.dart
│   ├── tela_ar.dart         # Reescrever: remover Augen, integrar OpenCV + camera
│   ├── tela_rescan.dart
│   ├── models/
│   │   ├── scan.dart
│   │   └── imagem_page.dart
│   └── services/
│       ├── scan_database.dart
│       ├── scan_storage_service.dart
│       ├── target_pipeline_service.dart
│       ├── image_analysis_service.dart
│       └── (novo) ar_opencv_service.dart  # ou equivalente: detecção, matching, pose
├── pubspec.yaml            # Remover augen; adicionar opencv_* conforme research
└── ...
```

**Structure Decision**: Projeto Flutter existente (projetotcc/). A tela de RA (tela_ar.dart) é reescrita; novo serviço opcional para encapsular pipeline OpenCV (feature detection, matching, pose). Contratos em specs/004-opencv-ar-visualization/contracts/.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| (Nenhuma violação identificada) | — | — |
