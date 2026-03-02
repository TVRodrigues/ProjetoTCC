# Data Model: Botão Escanear Redondo + Persistência de Scans

**Feature**: 001-round-scan-button-storage  
**Date**: 2026-02-26

## Entity Relationship

```
┌─────────────────┐         ┌─────────────────┐
│      Scan       │ 1    N  │     Imagem      │
├─────────────────┤─────────├─────────────────┤
│ id (PK)         │         │ id (PK)         │
│ titulo          │         │ scan_id (FK)    │
│ autor           │         │ caminho         │
│ resumo          │         │ ordem           │
│ data_criacao    │         │ formato         │
└─────────────────┘         └─────────────────┘
```

## Entities

### Scan

Representa uma sessão de escaneamento guardada.

| Campo        | Tipo     | Obrigatório | Descrição                                      |
|--------------|----------|-------------|------------------------------------------------|
| id           | TEXT     | Sim         | UUID ou string único (PK)                      |
| titulo       | TEXT     | Sim         | Título do livro (obrigatório)                 |
| autor        | TEXT     | Não         | Autor do livro                                |
| resumo       | TEXT     | Não         | Resumo ou notas                               |
| data_criacao  | INTEGER  | Sim         | Timestamp (millisecondsSinceEpoch)            |

**Regras**:
- Título não pode ser vazio (validação no formulário)
- Múltiplos scans podem ter o mesmo título (cada scan é independente)
- Ordem de imagens preservada via campo `ordem` em Imagem

### Imagem

Representa um ficheiro de imagem associado a um Scan.

| Campo    | Tipo    | Obrigatório | Descrição                              |
|----------|---------|-------------|----------------------------------------|
| id       | INTEGER | Sim         | Auto-increment PK                       |
| scan_id  | TEXT    | Sim         | FK para Scan                           |
| caminho  | TEXT    | Sim         | Caminho absoluto no dispositivo       |
| ordem    | INTEGER | Sim         | Ordem da página (1, 2, 3...)          |
| formato  | TEXT    | Sim         | "jpg" ou "png"                         |

**Regras**:
- Cada imagem pertence a um único Scan
- Caminho aponta para ficheiro em diretório privado da app
- Ordem determina sequência de páginas

## Schema SQLite

```sql
CREATE TABLE scans (
  id TEXT PRIMARY KEY,
  titulo TEXT NOT NULL,
  autor TEXT,
  resumo TEXT,
  data_criacao INTEGER NOT NULL
);

CREATE TABLE imagens (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scan_id TEXT NOT NULL,
  caminho TEXT NOT NULL,
  ordem INTEGER NOT NULL,
  formato TEXT NOT NULL,
  FOREIGN KEY (scan_id) REFERENCES scans(id) ON DELETE CASCADE
);

CREATE INDEX idx_imagens_scan_id ON imagens(scan_id);
CREATE INDEX idx_scans_data_criacao ON scans(data_criacao DESC);
```

## State Transitions

- **Scan**: Criado ao guardar (formulário confirmado) → Persistido (não há edição/eliminação nesta feature)
- **Imagem**: Criada ao copiar ficheiro do scanner para storage → Associada ao Scan via insert na tabela imagens

## Validation Rules (from Spec)

- FR-006: Título obrigatório → Bloquear submit se vazio; mostrar mensagem no popup
- Título sanitizado para nomes de pasta: remover caracteres inválidos, truncar 100 chars
