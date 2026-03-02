# Tasks: Número da página no indicador verde

**Input**: Design documents from `specs/006-green-button-page-number/`  
**Prerequisites**: spec.md, plan.md

**Tests**: Não obrigatórios pela spec; validação manual conforme quickstart (opcional).

**Organization**: Uma user story (US1); tasks sequenciais no mesmo ficheiro.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode correr em paralelo (ficheiros diferentes, sem dependências).
- **[Story]**: User story (US1).
- Paths relativos a `projetotcc/` (raiz Flutter).

---

## Phase 1: User Story 1 - Ver número da página no indicador verde (Priority: P1)

**Goal**: No estado "sucesso", o indicador circular verde exibe o número da página junto com o ícone (check), de forma visível e legível.

**Independent Test**: Abrir um livro com pelo menos uma página em estado "sucesso"; verificar que o indicador verde mostra o ícone e o número da página.

- [X] T001 [US1] Em `lib/tela_lista_paginas.dart`: quando `img.estadoTarget == 'sucesso'`, substituir o `child: Icon(...)` do `Container` do indicador por um widget composto (ex.: `Column` com `mainAxisSize: min`, `mainAxisAlignment: center`) contendo o mesmo `Icon(Icons.check_circle, color: cor, size: 24)` e um `Text` com o número da página — valor `img.numeroPagina ?? img.ordem`; se ambos nulos usar "—". Estilo do texto: fontSize 10 ou 11, color cor (ou branco), legível. Manter os outros estados (amarelo, vermelho, roxo, cinzento) com `child: Icon(...)` apenas.
- [X] T002 [US1] Em `lib/tela_lista_paginas.dart`: garantir edge cases — fallback "—" quando não houver numeroPagina nem ordem utilizável; para muitos dígitos, envolver o `Text` do número em `FittedBox` ou usar `maxLines: 1` e fontSize reduzido para o número caber no círculo sem quebrar o layout. Ajustar tamanho mínimo do `Container` do indicador (ex.: width/height 40–44) se necessário para caber ícone + número.

**Checkpoint**: Lista de páginas com pelo menos uma em "sucesso" exibe número + ícone no indicador verde; outros estados inalterados; sem overflow ou erro com fallback.

---

## Phase 2: Polish (opcional)

**Purpose**: Validação e documentação.

- [X] T003 [P] Criar ou atualizar `specs/006-green-button-page-number/quickstart.md` com passos de validação manual (lista com página verde → ver número no indicador).
- [X] T004 Executar `flutter analyze` em `projetotcc/` e corrigir avisos ligados às alterações em `lib/tela_lista_paginas.dart`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (US1)**: Sem dependências; alteração única em `tela_lista_paginas.dart`.
- **Phase 2 (Polish)**: Depende de Phase 1 concluída.

### Within Phase 1

- T001 → T002 (T002 aplica refinamentos e edge cases após o layout base em T001).

### Parallel Opportunities

- T003 e T004 podem correr em paralelo após Phase 1.

---

## Implementation Strategy

### MVP (recomendado)

1. Completar T001 e T002.
2. Validar manualmente: livro com página verde → indicador mostra número + ícone.
3. Opcional: T003 (quickstart), T004 (analyze).

### Suggested Order

```
T001 → T002 → [T003, T004 em paralelo ou sequencial]
```

---

## Summary

| Métrica            | Valor |
|--------------------|-------|
| **Total tasks**    | 4     |
| **US1 (P1)**       | 2     |
| **Polish**         | 2     |
| **Parallelizable** | T003, T004 |
| **MVP scope**      | T001–T002 |
