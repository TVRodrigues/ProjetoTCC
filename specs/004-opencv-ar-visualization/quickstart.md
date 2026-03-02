# Quickstart: Substituição Augen por OpenCV - Visualização AR

**Feature**: 004-opencv-ar-visualization  
**Branch**: `004-opencv-ar-visualization`

## Pré-requisitos

- Flutter SDK (Dart ^3.11.0)
- Android (minSdk 24) ou iOS para tela de RA; Windows não suportado nesta feature
- Dependências: remover augen; adicionar opencv_dart (ver research.md)

## Visão Geral

1. **Remover** toda a dependência e código do plugin Augen (tela_ar.dart, pubspec.yaml, imports).
2. **Implementar** tela de RA com OpenCV: feed da câmera (plugin camera), extração de características e matching (opencv_dart), overlay 3D (Flutter Stack) sobre a página detectada.
3. **Manter** fluxo: lista de livros → lista de páginas (indicadores) → toque em página verde → tela de RA.
4. **Subconjunto** de targets: página escolhida + adjacentes (ex.: 3+3) ou primeiras N; máximo 10.
5. **Zero targets** ao abrir AR: mensagem e voltar à lista.
6. **Dica** aos 5 s sem reconhecimento: "Aponte para uma página escaneada".
7. **Hit test** apenas quando uma página está rastreada; anotação 3D sobre essa página.

## Estrutura de Ficheiros

```
projetotcc/lib/
├── tela_ar.dart              # Reescrever: camera + OpenCV + overlay (sem Augen)
├── services/
│   └── ar_opencv_service.dart # Opcional: encapsular pipeline (feature detection, matching, pose)
├── main.dart                 # Sem alteração de navegação
├── tela_lista_paginas.dart    # Sem alteração; em Windows pode desativar navegação para AR
└── ...
```

## Fluxo de Implementação (resumo)

1. Remover augen de pubspec.yaml e todo o código que importa ou usa augen em tela_ar.dart.
2. Adicionar opencv_dart (módulos necessários: core, imgproc, features2d, calib3d).
3. Em tela_ar.dart: verificar plataforma (Android/iOS); se Windows, exibir mensagem e não iniciar AR.
4. Verificar permissão de câmera; se negada, mensagem e não crash.
5. Obter subconjunto de targets (getImagensForScan → filtrar sucesso → aplicar lógica adjacentes/N); se vazio, mensagem e Navigator.pop.
6. Iniciar preview da câmera (plugin camera) e obter stream de frames.
7. Pré-carregar keypoints/descritores das imagens target (opencv_dart).
8. Por cada frame: matching, RANSAC, homografia; desenhar overlay 3D (modelo) sobre a região detectada.
9. Timer 5 s sem reconhecimento → exibir dica.
10. GestureDetector onTap: se página rastreada, hit test e adicionar anotação 3D na posição.
11. Dispose: parar câmera e libertar recursos OpenCV.
12. Atualizar docs/ARQUITETURA.md: substituir Augen por OpenCV; plataformas (AR apenas Android/iOS).

## Comandos

```bash
cd projetotcc
flutter pub get
flutter run
# Para AR: usar dispositivo/emulador Android ou iOS
```

## Verificações

- [x] augen removido do projeto (pubspec e código)
- [ ] Em Android/iOS: tocar numa página verde abre tela de RA com preview da câmera *(testar em dispositivo)*
- [ ] Apontar para a página física: reconhecimento e overlay visível *(testar em dispositivo)*
- [x] Após 5 s sem reconhecer: dica "Aponte para uma página escaneada"
- [x] Toque na tela com página rastreada: anotação colocada (SnackBar)
- [x] Zero targets ao abrir: mensagem e volta à lista de páginas
- [x] Sem permissão câmera: mensagem clara, sem crash
- [x] Tema escuro mantido (AppBar #1E1E1E)
- [x] Em Windows: mensagem "RA disponível apenas em Android e iOS"
