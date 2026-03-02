# Data Model: Pipeline de Targets AR

**Feature**: 003-ar-target-pipeline  
**Data**: 2026-02-26

## Visão Geral

O modelo estende as entidades existentes (Scan, Imagem) e introduce o conceito de estado de processamento por imagem.

---

## Entidades

### Scan (existente — estendido)

| Campo        | Tipo   | Obrigatório | Descrição                              |
|--------------|--------|-------------|----------------------------------------|
| id           | String | Sim         | UUID do scan                           |
| titulo       | String | Sim         | Título do livro                        |
| autor        | String?| Não         | Autor                                  |
| resumo       | String?| Não         | Resumo                                 |
| data_criacao | int    | Sim         | Timestamp Unix                         |

**Relações**: 1 scan → N imagens.

---

### Imagem (estendida)

Tabela `imagens` existente com novos campos (migration de schema).

| Campo           | Tipo   | Obrigatório | Descrição                                      |
|-----------------|--------|-------------|------------------------------------------------|
| id              | int    | Sim         | PK, AUTOINCREMENT                              |
| scan_id         | String | Sim         | FK → scans(id) ON DELETE CASCADE              |
| caminho         | String | Sim         | Path local da imagem                           |
| ordem           | int    | Sim         | Ordem de escaneamento (para ordenação)         |
| formato         | String | Sim         | Ex.: "jpeg"                                   |
| **numero_pagina**| int?   | Não         | 0 = capa; null = não detectável               |
| **eh_pagina**   | bool   | Sim         | Default true; false = "não-página"             |
| **estado_target**| String | Sim        | "processando" \| "sucesso" \| "falha" \| "rescan" \| "nao_pagina" |
| **qualidade_target**| int? | Não        | Score 0–100 (opcional)                        |

**Validações**:
- `numero_pagina`: null ou >= 0
- `estado_target`: enum restrito
- Ordenação: `ORDER BY COALESCE(numero_pagina, ordem), ordem`

---

### Estado de Target (Domain)

Não persiste como tabela; deriva de `estado_target`:

| Estado       | Cor UI   | Significado                                      |
|-------------|----------|--------------------------------------------------|
| processando | Amarelo  | Em processamento; não clicável                  |
| sucesso     | Verde    | Target gerado; clicável → tela RA                |
| falha       | Vermelho | Falhou; clicável → retry                         |
| rescan      | Roxo     | Falhou após retry; clicável → abrir scanner      |
| nao_pagina  | Cinzento | Não é página; não gera target; apenas visualizar |

---

## Transições de Estado

```
[processando] ──sucesso──► [sucesso]
[processando] ──falha────► [falha]
[falha]      ──click────► [processando] (retry)
[processando] ──falha────► [rescan]     (após retry)
[rescan]     ──captura──► substitui imagem, [processando]
[processando] ──eh_pagina=false─► [nao_pagina]
```

---

## Target de RA (Runtime)

Não persiste estrutura de dados de target. Augen usa `ARImageTarget(imagePath: caminho, physicalSize: ImageTargetSize(0.21, 0.297))`. O `caminho` da imagem é a referência; ARCore/ARKit fazem o matching em tempo real.

Metadados opcionais (`qualidade_target`) ficam em `imagens`.

---

## Migration SQL

```sql
-- Migration v2: adicionar colunas a imagens
ALTER TABLE imagens ADD COLUMN numero_pagina INTEGER;
ALTER TABLE imagens ADD COLUMN eh_pagina INTEGER NOT NULL DEFAULT 1;
ALTER TABLE imagens ADD COLUMN estado_target TEXT NOT NULL DEFAULT 'processando';
ALTER TABLE imagens ADD COLUMN qualidade_target INTEGER;

-- Índice para listagem por scan + ordenação
CREATE INDEX idx_imagens_scan_ordem ON imagens(scan_id, COALESCE(numero_pagina, 9999), ordem);
```

*Nota: SQLite não suporta ALTER ADD múltiplas colunas numa única instrução; executar em passos ou usar migration wrapper.*

---

## Modelo Dart (Scan, ImagemPage)

```dart
// Extensão de Scan — sem alteração de campos; imagens com metadados
class ImagemPage {
  final int id;
  final String scanId;
  final String caminho;
  final int ordem;
  final String formato;
  final int? numeroPagina;    // 0 = capa, null = não detectável
  final bool ehPagina;
  final String estadoTarget;  // processando|sucesso|falha|rescan|nao_pagina
  final int? qualidadeTarget;

  // ...
}

enum EstadoTarget { processando, sucesso, falha, rescan, naoPagina }
```
