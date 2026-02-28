# Contract: Image Analysis Service

**Feature**: 003-ar-target-pipeline  
**Type**: Internal service contract (Flutter, camada de serviços)

## Overview

O `ImageAnalysisService` analisa uma imagem para determinar se é página de livro (`eh_pagina`), extrair o número da página (`numero_pagina`), e estimar qualidade para target AR.

## Operations

### analyze

Analisa uma imagem e retorna metadados para persistência.

**Input**:
- `imagePath`: String — caminho local da imagem (JPEG/PNG)

**Output**: `Future<ImageAnalysisResult>`

```dart
class ImageAnalysisResult {
  final bool ehPagina;       // false = "não-página"
  final int? numeroPagina;   // 0 = capa, null = não detectável
  final int? qualidadeTarget; // 0-100, opcional
}
```

**Logic**:
1. Usar `google_mlkit_text_recognition` para extrair texto
2. **eh_pagina**: heurística — se pouquíssimo ou nenhum texto → false
3. **numero_pagina**:
   - Se layout sugere capa (primeiro bloco grande, central) → 0
   - Caso contrário: regex sobre texto para padrões "42", "Pág. 42", "— 42 —", etc.; extrair primeiro número encontrado
   - Se não detectável → null
4. **qualidade_target**: heurística de contraste/nitidez/densidade de texto; 0–100

**Errors**:
- `FileNotFoundException`: imagem não existe
- Retornar `ehPagina: false` se análise falhar (erro de ML Kit)

---

## Dependencies

- `google_mlkit_text_recognition`: já no projeto
- `dart:io` File: leitura da imagem

## Implementation Notes

- Capa: bloco de texto com área > threshold, posicionado no terço superior; título + autor típico
- Regex para número: `RegExp(r'\b(\d{1,4})\b')` ou similar; filtrar números inválidos (ex.: anos)
- Qualidade: histograma de contraste; Laplacian para nitidez se disponível
