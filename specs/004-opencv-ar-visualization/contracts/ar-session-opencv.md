# Contract: AR Session (OpenCV)

**Feature**: 004-opencv-ar-visualization  
**Type**: Integração OpenCV + Camera para visualização AR

## Overview

A TelaAR deve usar OpenCV para reconhecimento de imagens e overlay 3D, em substituição ao Augen. Fluxo: (1) obter subconjunto de targets (página escolhida + adjacentes ou primeiras N); (2) se zero targets, exibir mensagem e Navigator.pop à lista de páginas; (3) pedir permissão de câmera; (4) iniciar feed da câmera; (5) por cada frame, extrair características, fazer matching com targets, obter homografia/pose e desenhar overlay 3D sobre a página detectada; (6) hit test apenas quando uma página está rastreada — toque coloca anotação 3D sobre essa página.

## Pré-condições

- Plataforma: Android ou iOS (Windows: não abrir tela de RA ou exibir placeholder com mensagem).
- Permissão de câmera concedida antes de iniciar preview (senão mensagem clara, sem crash).
- Pelo menos uma imagem com estado_target=sucesso no subconjunto; senão FR-012 (mensagem + pop).

## Subconjunto de targets

- Entrada: scanId, imagemId (opcional).
- Obter imagens do scan com estado_target=sucesso e eh_pagina=true (ordenadas por numero_pagina/ordem).
- Se imagemId presente: incluir essa imagem + até N adjacentes (ex.: 3 antes, 3 depois), limite máximo (ex.: 10).
- Se imagemId ausente: incluir as primeiras M imagens (ex.: M=5), limite máximo (ex.: 10).
- Resultado: lista de caminhos (targetPaths) para carregar no motor OpenCV.

## Pipeline OpenCV (por frame)

1. Pré-carga: Para cada imagem em targetPaths, extrair keypoints e descritores (ORB ou AKAZE) e guardar em memória.
2. Por frame da câmera: Converter frame para formato opencv_dart; extrair keypoints e descritores; matching (BFMatcher ou FLANN) com cada target; filtrar com RANSAC; findHomography.
3. Pose/Overlay: A partir da homografia, obter os quatro cantos da página no ecrã e posicionar o modelo 3D sobre a página.
4. Hit test: Quando uma página está rastreada, ao toque projectar na página e adicionar anotação 3D nessa posição.

## UI e comportamento

- Tema escuro: AppBar #1E1E1E, background #121212 (Constitution).
- Após 5 segundos sem reconhecimento: exibir dica "Aponte para uma página escaneada" (FR-011).
- Ao sair da tela (back): libertar recursos da câmera e do processamento OpenCV (dispose).
- Zero targets ao abrir: SnackBar ou diálogo com mensagem; Navigator.pop(context) para voltar à lista de páginas (FR-012).

## Dependências

- Remover: augen.
- Adicionar: opencv_dart (módulos: core, imgproc, features2d, calib3d).
- Existente: camera (preview + frames), permission_handler.

## Referências

- research.md: opencv_dart, ORB/AKAZE, homografia, overlay Flutter.
- data-model.md: subconjunto de targets, targetPaths.
