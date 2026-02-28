# Research: Pipeline de Targets AR para Páginas Escaneadas

**Feature**: 003-ar-target-pipeline  
**Data**: 2026-02-26  
**Status**: Concluído

## 1. Augen e Image Tracking

**Decision**: Manter Augen e usar a API nativa de Image Tracking (`ARImageTarget`, `addImageTarget`, `trackedImagesStream`, `addNodeToTrackedImage`).

**Rationale**:
- Augen v1.0.2 suporta explicitamente Image Tracking (documentação pub.dev).
- API: `ARImageTarget(id, name, imagePath, physicalSize)` com `addImageTarget`, `setImageTrackingEnabled(true)`, `trackedImagesStream`.
- ARCore (Android) e RealityKit/ARKit (iOS) nativos fazem o matching — não é necessário pipeline Vuforia-like customizado.
- A tela atual usa plane detection + hit test; migrar para image tracking usa a mesma sessão Augen.

**Alternatives considered**:
- Vuforia SDK: requer licença e integração nativa; complexidade desnecessária.
- ARCore Augmented Images direto (sem Augen): Augen já abstrai ARCore; duplicaria código.

---

## 2. Geração de Targets — Local vs Backend

**Decision**: Processamento local no dispositivo. As imagens escaneadas (JPEG) são usadas diretamente como referência; não existe "geração de target" separada no sentido Vuforia (banco de features). ARCore/ARKit fazem a detecção em tempo real a partir da imagem.

**Rationale**:
- ARImageTarget do Augen recebe `imagePath` e `physicalSize`; a imagem já pronta serve como referência.
- Constitution IV (Simplicity): evitar backend sem requisito explícito.
- FR-011 exige processamento assíncrono — interpretamos como: análise de imagem (eh_pagina, numero_pagina) + registo de targets na sessão AR em background; sem chamadas HTTP.
- Qualidade de target (FR-006): avaliar com heurísticas locais (contraste, nitidez, distribuição de texto) antes de aceitar; targets fracos aceites conforme FR-010.

**Alternatives considered**:
- Backend para gerar "target database": adicionaria latência, dependência de rede, violaria YAGNI.
- arcoreimg para pré-processar imagens: possível futuro; para MVP, usar imagem direta.

---

## 3. Análise de Imagem — Página vs Não-página

**Decision**: google_mlkit_text_recognition (já no projeto) para extrair texto; heurística de layout:
- Página: densidade de texto razoável, linhas reconhecíveis.
- Capa: título proeminente (bloco de texto grande central), possível autor; heurística de posição e tamanho de bloco.
- Não-página: pouquíssimo ou nenhum texto; marcar `eh_pagina = false`.

**Rationale**:
- ML Kit já disponível (ARQUITETURA.md); evitar nova dependência.
- Detecção de layout "típico de capa" via regras simples (posição do primeiro bloco, tamanho relativo).
- Se não detectável: `numero_pagina = null`; ordenação por `ordem` de escaneamento.

**Alternatives considered**:
- TensorFlow Lite / modelo customizado: overkill; adiciona peso e complexidade.
- OCR externo: desnecessário; ML Kit suficiente.

---

## 4. Extração do Número da Página

**Decision**: ML Kit Text Recognition; regex sobre o texto reconhecido para padrões como "42", "Pág. 42", "42.", "— 42 —", etc. Capa: lógica separada (layout) → `numero_pagina = 0`.

**Rationale**:
- FR-003 e FR-004 exigem numero_pagina; 70% de acerto em SC-003 é alcançável com regex em texto legível.
- Número não detectável → null; ordenar por ordem de escaneamento.

**Alternatives considered**:
- Modelo de NLP: desnecessário para extração de número.
- Ignorar número: viola FR-004.

---

## 5. Physical Size para ARImageTarget

**Decision**: Usar tamanho padrão estimado para páginas de livro: `ImageTargetSize(0.21, 0.297)` (A5 em metros) como default. Opcional: permitir calibração futura por utilizador.

**Rationale**:
- Augen requer `physicalSize`; ARCore recomenda dimensão física para melhor detecção.
- A5 é tamanho comum de livro; suficiente para MVP.

**Alternatives considered**:
- Detectar dimensão via câmera: complexo; adiar.
- Fixo A4: A5 mais próximo de livro de bolso.

---

## 6. Qualidade de Target

**Decision**: Heurísticas simples locais: contraste (histograma), nitidez (Laplacian blur detection se disponível via ML Kit ou similar), densidade de features (número de blocos de texto). Score 0–100; abaixo de 50: aceitar na mesma (FR-010), mas sinalizar para UI opcional.

**Rationale**:
- FR-006 exige avaliar distribuição; sem biblioteca específica, heurísticas são suficientes.
- FR-010: aceitar targets de baixa qualidade; não bloquear fluxo.

**Alternatives considered**:
- arcoreimg eval-img: ferramenta CLI, não integrada ao Flutter; usar em fase de teste manual.
- Ignorar qualidade: violaria FR-006.

---

## 7. Fluxo de Rescan (Indicador Roxo)

**Decision**: Tela dedicada de scanner único (sem galeria completa); ao capturar, substituir imagem na BD, atualizar `imagens` (DELETE + INSERT ou UPDATE), regressar à lista de páginas. Manter `scan_id` e metadados do livro.

**Rationale**:
- FR-015: scanner apenas para aquela página; fluxo explícito na spec.
- Reutilizar Document Scanner; nova rota ou parâmetro `rescanParaImagemId`.

**Alternatives considered**:
- Abrir TelaGaleria em modo especial: possível, mas spec pede "apenas scanner"; tela dedicada mais clara.

---

## 8. Atualização em Background e UI

**Decision**: `Stream` ou `ValueNotifier` no serviço de processamento; widgets escutam e reconstroem. Sem Provider/Riverpod; state local na TelaListaPaginas com callback de refresh.

**Rationale**:
- Constitution IV: não introduzir estado global sem requisito.
- FR-012: atualização automática; Stream/Notifier suficientes.

**Alternatives considered**:
- Riverpod: violaria YAGNI.
- Polling: menos elegante; Stream preferível.
