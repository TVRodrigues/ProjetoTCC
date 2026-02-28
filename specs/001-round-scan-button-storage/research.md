# Research: Botão Escanear Redondo + Persistência de Scans

**Feature**: 001-round-scan-button-storage  
**Date**: 2026-02-26

## 1. Storage Local para Imagens (path_provider)

**Decision**: Usar `path_provider` com `getApplicationDocumentsDirectory()` para guardar imagens em diretório privado da aplicação.

**Rationale**:
- Diretório privado não requer permissões adicionais em Android 10+ (scoped storage)
- Em iOS, corresponde a NSDocumentDirectory
- Dados persistem entre sessões e sobrevivem a updates da app
- Não visível na galeria do sistema (conforme spec)

**Alternatives considered**:
- `getExternalStorageDirectory()`: Requer permissões em Android; rejeitado
- `getTemporaryDirectory()`: Pode ser limpo pelo sistema; rejeitado

---

## 2. Base de Dados Local (SQLite)

**Decision**: Usar `sqflite` para SQLite em Flutter.

**Rationale**:
- Pacote mais usado para SQLite em Flutter (pub.dev)
- Suporta Android, iOS, Windows
- Permite queries e migrações
- Compatível com path_provider para localização do ficheiro .db

**Alternatives considered**:
- `drift`: Mais features, mas mais complexo; YAGNI
- `hive`: NoSQL; spec exige estrutura relacional (scan → imagens)
- `shared_preferences`: Apenas key-value; insuficiente para múltiplos scans com listas de imagens

---

## 3. Permissões de Armazenamento

**Decision**: Solicitar permissão de storage apenas no momento de guardar imagens (Android <10 ou cenários específicos). Em Android 10+, `getApplicationDocumentsDirectory()` não requer permissão.

**Rationale**:
- Constituição: "Permissões MUST ser solicitadas no momento de uso"
- permission_handler já existe no projeto
- Tratar cenário de permissão negada com mensagem clara (FR-009)

**Alternatives considered**:
- Solicitar ao iniciar app: Rejeitado; viola princípio de momento de uso

---

## 4. Ícone Livro com Símbolo "+"

**Decision**: Usar `Icon(Icons.menu_book)` ou `Icon(Icons.auto_stories)` com overlay de `Icon(Icons.add)` ou `Icon(Icons.add_circle)`. Alternativa: `Stack` com `Icon(Icons.menu_book)` e `Positioned` com `Icon(Icons.add)` no canto.

**Rationale**:
- Material Icons já incluído; sem assets adicionais
- Spec permite "ícones da biblioteca ou asset customizado"
- `Icons.menu_book` representa livro; `Icons.add` representa adicionar

**Alternatives considered**:
- Asset customizado: Mais trabalho; não necessário para MVP
- `Icons.document_scanner`: Mantém consistência com scanner; mas spec pede "livro com +"

---

## 5. Sanitização de Título para Nomes de Ficheiro

**Decision**: Sanitizar título ao gerar nomes de ficheiro: remover caracteres inválidos (`/`, `\`, `:`, `*`, `?`, `"`, `<`, `>`, `|`), substituir espaços por underscore ou hífen, truncar a 100 caracteres.

**Rationale**:
- Edge case da spec: "caracteres especiais ou nomes longos"
- Evita erros de I/O ao criar ficheiros
- 100 chars é suficiente para títulos de livros

---

## 6. Estrutura do Ficheiro de Imagem

**Decision**: Guardar imagens em subpasta `scans/{scan_id}/` com nomes `page_001.jpg`, `page_002.jpg`, etc. O `scan_id` é UUID ou timestamp para unicidade.

**Rationale**:
- Organização por scan; fácil de limpar ou migrar
- Nomes previsíveis; evita colisões
- Formato JPEG mantido do Document Scanner (já produz JPEG)
