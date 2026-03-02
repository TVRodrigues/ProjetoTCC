# Quickstart: Pipeline de Targets AR para Páginas Escaneadas

**Feature**: 003-ar-target-pipeline  
**Branch**: `003-ar-target-pipeline`

## Pré-requisitos

- Flutter SDK (Dart ^3.11.0)
- Dispositivo Android/iOS com ARCore/ARKit
- Dependências existentes: augen, google_mlkit_text_recognition, sqflite, path_provider

## Visão Geral

1. **Nova tela** `TelaListaPaginas`: entre lista principal e tela RA; mostra páginas do livro com indicadores (amarelo/verde/vermelho/roxo/cinzento)
2. **Migration DB**: adicionar colunas `numero_pagina`, `eh_pagina`, `estado_target`, `qualidade_target` à tabela `imagens`
3. **TargetPipelineService**: processamento em background; análise de imagem + atualização de estado
4. **ImageAnalysisService**: ML Kit para eh_pagina e numero_pagina
5. **TelaAR**: migrar para Image Tracking (ARImageTarget) em vez de apenas plane detection
6. **Tela Rescan**: scanner único para substituir página com estado roxo

## Estrutura de Ficheiros

```
projetotcc/lib/
├── models/
│   ├── scan.dart              # existente
│   └── imagem_page.dart       # novo: ImagemPage + EstadoTarget
├── services/
│   ├── scan_storage_service.dart   # existente — estender para novo schema
│   ├── scan_database.dart          # existente — migration v2
│   ├── target_pipeline_service.dart   # novo
│   └── image_analysis_service.dart    # novo
├── tela_principal.dart         # alterar: ao tocar livro → TelaListaPaginas
├── tela_lista_paginas.dart    # novo
├── tela_ar.dart               # alterar: Image Tracking
├── tela_rescan.dart           # novo (ou modo em TelaGaleria)
└── main.dart                  # TelaGaleria: após save, dispara processScan
```

## Fluxo de Navegação

```
TelaPrincipal (lista livros)
    │ tap livro
    ▼
TelaListaPaginas (páginas do livro, indicadores)
    │ tap página verde
    ▼
TelaAR (image tracking, câmera)

TelaListaPaginas
    │ tap página roxa
    ▼
TelaRescan (scanner única página)
    │ captura
    ▼
volta TelaListaPaginas (imagem substituída, estado = processando)
```

## Passos de Implementação (Resumo)

1. **Migration DB**: `ScanDatabase` — incrementar `_version` para 2, em `onUpgrade` executar `ALTER TABLE imagens ADD COLUMN ...` para cada nova coluna
2. **ImagemPage model**: classe com id, scanId, caminho, ordem, numeroPagina, ehPagina, estadoTarget, qualidadeTarget
3. **ScanDatabase**: métodos `getImagensForScan`, `updateImagemEstado`, `updateImagemPath`, etc.
4. **ImageAnalysisService**: `analyze(path)` → `ImageAnalysisResult`
5. **TargetPipelineService**: `processScan(scanId)`, `retryImage(imagemId)`, `replaceImageForRescan(imagemId, novoPath)`; Stream de updates
6. **TelaListaPaginas**: ListView de páginas; cores por estado; tap verde → TelaAR; tap vermelho → retry; tap roxo → TelaRescan
7. **TelaAR**: carregar targets com `addImageTarget`; `trackedImagesStream`; manter tema escuro
8. **ScanStorageService.saveScan**: ao salvar, inserir imagens com `estado_target = 'processando'`; após inserção, chamar `TargetPipelineService.processScan(scanId)`
9. **TelaRescan**: Document Scanner com `pageLimit: 1`; ao capturar, `replaceImageForRescan` e `Navigator.pop`

## Comandos

```bash
cd projetotcc
flutter pub get
flutter run
```

## Verificações (Checklist T024)

- [ ] Ao abrir livro, aparece TelaListaPaginas com páginas
- [ ] Indicadores amarelos passam a verde/vermelho/cinzento automaticamente
- [ ] Tap em verde abre TelaAR; câmera reconhece página física
- [ ] Tap em vermelho inicia retry; se falhar, fica roxo
- [ ] Tap em roxo abre scanner; captura substitui imagem e volta à lista
- [ ] Páginas cinzentas (não-página) não são clicáveis para RA
