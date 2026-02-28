# Contract: AR Session (Image Tracking)

**Feature**: 003-ar-target-pipeline  
**Type**: Integração com Augen (Flutter)

## Overview

A `TelaAR` deve configurar a sessão Augen para **Image Tracking** em vez de (ou além de) plane detection. Ao abrir para um livro, carrega as imagens com `estado_target = 'sucesso'` e `eh_pagina = true` como targets.

## Configuração

### ARSessionConfig

Manter `planeDetection`, `lightEstimation`, `autoFocus` como atual. Adicionar:

- `imageTracking: true` (ou equivalente via `setImageTrackingEnabled(true)` após init)

### ARImageTarget

Para cada imagem de página válida:

```dart
final target = ARImageTarget(
  id: 'pagina_${imagemId}',
  name: 'Pagina $numeroPagina',
  imagePath: caminho,  // path local da imagem
  physicalSize: const ImageTargetSize(0.21, 0.297),  // A5 em metros
);
await controller.addImageTarget(target);
```

### trackedImagesStream

Escutar `controller.trackedImagesStream`; quando `trackedImage.isTracked && trackedImage.isReliable`, adicionar modelo 3D com `addNodeToTrackedImage`.

---

## Fluxo

1. `TelaAR(scanId, imagemId?)` — imagemId opcional para focar numa página
2. Carregar imagens do scan com estado `sucesso`
3. `addImageTarget` para cada uma
4. `setImageTrackingEnabled(true)`
5. `trackedImagesStream.listen` → ao detectar, oferecer ancorar modelo (ou ancorar automaticamente)
6. Hit test: manter para fallback em superfícies planas se desejado

---

## Dependencies

- `augen`: ^1.0.2
- `ARImageTarget`, `ImageTargetSize`, `trackedImagesStream`, `addNodeToTrackedImage`

## Implementation Notes

- Limite de ~20 imagens rastreadas em simultâneo (ARCore); para livros com muitas páginas, carregar apenas as N mais relevantes ou a página selecionada + adjacentes
- Tema escuro: manter AppBar e overlay conforme Constitution
