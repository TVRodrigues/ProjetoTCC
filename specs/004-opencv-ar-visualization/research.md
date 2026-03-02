# Research: Substituição Augen por OpenCV - Visualização AR

**Feature**: 004-opencv-ar-visualization  
**Date**: 2026-02-26

## 1. Pacote OpenCV para Flutter

**Decision**: Usar **opencv_dart** como dependência principal para processamento de imagem e visão computacional.

**Rationale**:
- Suporte Android e iOS (alinhado com âmbito da feature; Windows suportado pelo pacote mas fora do âmbito 004).
- Bindings OpenCV4 via dart:ffi; módulos relevantes: core, imgproc, features2d (detecção de características, matching), calib3d (homografia/pose).
- Manutenção ativa; compatível com Dart 3.10+ e Flutter atual.
- Alternativa opencv_4 está desatualizada (4 anos).

**Alternatives considered**:
- **opencv_4**: Mais antigo; menos módulos.
- **flutter_pixelmatching**: Focado em similarity score; não expõe homografia/pose de forma direta para ancoragem 3D.
- **Implementação nativa (method channel)**: Maior controle mas mais esforço; opencv_dart reduz necessidade.

**Implementation notes**: Incluir apenas os módulos OpenCV necessários (core, imgproc, features2d, calib3d) para reduzir tamanho do app; documentar em ARQUITETURA.md.

---

## 2. Pipeline de reconhecimento (feature detection + matching + pose)

**Decision**: Pipeline em Dart usando opencv_dart: (1) extrair keypoints e descritores (ORB ou AKAZE) das imagens de referência (targets); (2) por cada frame da câmera, extrair keypoints/descritores e fazer matching (BFMatcher ou FLANN); (3) filtrar com RANSAC e obter homografia; (4) derivar pose 2D→3D (ou homografia 2D) para sobrepor o modelo 3D.

**Rationale**:
- ORB/AKAZE são invariantes a escala/rotação e adequados para imagens de páginas; sem necessidade de SIFT/SURF (licenciamento).
- Homografia (findHomography) permite mapear os quatro cantos da página no frame para coordenadas de referência; suficiente para desenhar overlay 2D ou posicionar modelo 3D com transformação simplificada.
- Se opencv_dart não expor pose 3D completa, usar homografia 2D para posicionar um overlay (quad da página) e ancorar o modelo 3D no centro/plano dessa quad.

**Alternatives considered**:
- ARCore/ARKit Augmented Images: Mantém dependência de motor nativo; spec exige remoção de Augen e uso de OpenCV.
- Aruco markers: Exigiria imprimir marcadores; spec foca em páginas escaneadas como target.

---

## 3. Feed de câmera e renderização

**Decision**: Usar o plugin **camera** (já no projeto) para obter frames; processar frames com opencv_dart (convertendo CameraImage para formato OpenCV); exibir preview via Texture (camera preview) ou widget de preview do plugin; sobreposição 3D via Flutter overlay (Stack com modelo 3D posicionado por transformação baseada na homografia/pose).

**Rationale**:
- Camera já é dependência; evita novo plugin.
- Flutter overlay (Stack + Transform/Positioned) permite desenhar o modelo 3D (ex.: model_viewer ou renderer 3D em Flutter) sobre a região da página detectada; homografia dá os quatro cantos no ecrã.
- Alternativa: superfície nativa (OpenGL/Vulkan) para RA completa — maior complexidade; overlay Flutter é mais simples e alinhado com YAGNI.

**Alternatives considered**:
- Platform view com view nativa de RA: Reintroduzir complexidade similar ao Augen; rejeitado em favor de camera + overlay.
- Renderização 3D nativa (OpenGL): Pode ser considerada em iteração futura se overlay 2D/3D em Flutter for insuficiente.

---

## 4. Subconjunto de targets por sessão

**Decision**: Carregar **página escolhida (imagemId) + até N páginas adjacentes por ordem** (ex.: N=3 antes e 3 depois), com limite máximo total (ex.: 10 targets). Se imagemId não for passado, carregar as primeiras M páginas em sucesso (ex.: M=5).

**Rationale**:
- Equilibra performance (menos descritores e matching) e UX (virar página e reconhecer adjacentes).
- N e M definidos no plano de tarefas (ex.: N=3, M=5, máximo 10).

**Alternatives considered**:
- Apenas uma página: Menor carga mas pior UX ao folhear.
- Todas as páginas em sucesso: Pode degradar em livros grandes; spec pede subconjunto.

---

## 5. Comportamento em Windows

**Decision**: Na plataforma Windows, a tela de RA **não é exibida** (ou é desativada): ao tocar numa página verde a partir de Windows, exibir mensagem "RA disponível apenas em Android e iOS" e não navegar para a tela de RA, ou navegar para uma tela placeholder com a mesma mensagem.

**Rationale**:
- Spec 004 deixa Windows fora do âmbito; opencv_dart suporta Windows mas câmera e UX AR em desktop são secundários.
- Evitar código condicional complexo; decisão explícita simplifica testes e documentação.

---

## Summary Table

| Tópico | Decisão |
|--------|---------|
| Pacote OpenCV | opencv_dart |
| Pipeline | ORB/AKAZE + matching + RANSAC + homografia |
| Câmera | Plugin camera (existente); frames para opencv_dart |
| Renderização 3D | Flutter overlay (Stack) com posição derivada da homografia |
| Subconjunto targets | Página escolhida + N adjacentes (ex.: 3+3); máx. 10; ou primeiras M se sem imagemId |
| Windows | RA desativada; mensagem ao utilizador |
