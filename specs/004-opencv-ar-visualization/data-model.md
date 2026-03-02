# Data Model: Substituição Augen por OpenCV - Visualização AR

**Feature**: 004-opencv-ar-visualization  
**Date**: 2026-02-26

## Visão Geral

Esta feature **não altera** o modelo de dados persistido (scans, imagens). As entidades Scan e Imagem permanecem conforme definido em 003-ar-target-pipeline. A única adição é o conceito de **subconjunto de targets por sessão de RA**, que é derivado em tempo de execução a partir das imagens com estado_target=sucesso.

---

## Entidades (inalteradas)

### Scan

Conforme specs/003-ar-target-pipeline/data-model.md. Atributos: id, titulo, autor, resumo, data_criacao. Relação 1 → N com Imagem.

### Imagem (Página)

Conforme specs/003-ar-target-pipeline/data-model.md. Campos: id, scan_id, caminho, ordem, formato, numero_pagina, eh_pagina, estado_target, qualidade_target. Apenas imagens com **estado_target = 'sucesso'** e **eh_pagina = true** são usadas como referência para reconhecimento OpenCV.

---

## Conceito de Sessão AR (runtime)

Não persiste; usa-se para definir quais imagens carregar como targets numa abertura da tela de RA.

| Campo lógico | Tipo | Descrição |
|--------------|------|-----------|
| scanId | String | Livro aberto |
| imagemId | int? | Página escolhida (opcional); se presente, centro do subconjunto |
| targetPaths | List&lt;String&gt; | Subconjunto de caminhos de imagens (estado sucesso) a carregar: página escolhida + adjacentes (ex.: 3 antes, 3 depois) ou primeiras N páginas, com limite máximo (ex.: 10) |

**Regras**:
- Se imagemId for passado: incluir essa imagem + até N adjacentes por ordem (ex.: 3 antes, 3 depois), respeitando limite máximo.
- Se imagemId não for passado: incluir as primeiras M imagens em sucesso (ordenadas por COALESCE(numero_pagina, ordem), ordem).
- Se targetPaths ficar vazio (zero páginas em sucesso): FR-012 aplica-se — exibir mensagem e voltar à lista de páginas.

---

## Target de RA (em memória)

Representação em tempo de execução para o motor OpenCV: por cada caminho em targetPaths, extrair keypoints e descritores (ORB/AKAZE) e manter em memória para matching com o frame da câmera. Não persiste; recalculado ao abrir a tela de RA.

---

## Referências

- Modelo completo de Scan e Imagem: `specs/003-ar-target-pipeline/data-model.md`
- Base de dados: `ScanDatabase.getImagensForScan(scanId)`; filtrar estado_target='sucesso' e eh_pagina=true; aplicar lógica de subconjunto (adjacentes ou primeiras N).
