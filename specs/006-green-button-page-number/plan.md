# Implementation Plan: Número da página no indicador verde

**Branch**: `006-green-button-page-number` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `specs/006-green-button-page-number/spec.md`

## Summary

Na lista de páginas do livro (TelaListaPaginas), o indicador circular **verde** (estado "sucesso") passa a exibir o **número da página** junto com o ícone de check, para que o utilizador identifique rapidamente qual página está pronta para RA. Os demais estados (amarelo, vermelho, roxo, cinzento) mantêm o comportamento atual. Sem alteração de modelo de dados nem de serviços; apenas ajuste de UI no widget do indicador.

## Technical Context

- **Linguagem/Framework**: Dart ^3.11.0, Flutter (projetotcc/).
- **Ficheiro alvo**: `projetotcc/lib/tela_lista_paginas.dart` — ListView.builder, célula por página com indicador à direita.
- **Modelo existente**: `ImagemPage` já expõe `numeroPagina` (int?) e `ordem` (int); o número a mostrar será `numeroPagina ?? ordem`, com fallback para um valor de reserva (ex.: "—") se ambos forem nulos.
- **UI**: Tema escuro; o indicador é um `Container` com `decoration: BoxDecoration(shape: BoxShape.circle, color: cor.withValues(alpha: 0.3))` e `child: Icon(...)`. Para o estado "sucesso", o `child` passa a incluir ícone e número.

## Constitution Check

- **Documentação**: Alteração apenas de apresentação na TelaListaPaginas; sem mudança de modelo de dados ou de stack. Atualizar `docs/ARQUITETURA.md` apenas se houver referência explícita ao aspecto do indicador (opcional).
- **Apresentação/Serviços**: Toda a alteração fica na camada de apresentação (widget); nenhum serviço novo.
- **Simplicidade**: Uma única alteração localizada no widget do indicador.

## Project Structure

### Documentation (this feature)

```text
specs/006-green-button-page-number/
├── spec.md
├── plan.md               # Este ficheiro
├── quickstart.md         # (opcional) Passos de validação manual
└── tasks.md              # Tasks (gerado por /speckit.tasks)
```

### Source Code

```text
projetotcc/lib/
└── tela_lista_paginas.dart   # Alterar apenas o widget do indicador (estado "sucesso")
```

Nenhum ficheiro novo; nenhuma alteração em modelos ou serviços.

## Design do indicador verde (estado "sucesso")

- **Requisito**: Mostrar número da página **junto com** o ícone (check), ambos visíveis e legíveis.
- **Proposta**: O `child` do `Container` do indicador, quando `img.estadoTarget == 'sucesso'`, deixa de ser apenas `Icon(Icons.check_circle, ...)` e passa a ser um **Column** (ou Row) com:
  - **Ícone** (Icons.check_circle, size 24, cor verde) — mantido.
  - **Texto** com o número: `numeroPagina ?? ordem`; se ambos nulos, exibir "—". Fonte pequena (ex.: 10–12 px), cor verde (ou branco para contraste no fundo semi-transparente), centralizado.
- **Layout**: Column com mainAxisSize.min e mainAxisAlignment.center: ícone em cima, número em baixo. Assim o círculo continua a conter os dois elementos sem aumentar muito o tamanho; para muitos dígitos, usar `FittedBox` ou `Text(..., overflow: TextOverflow.clip, maxLines: 1)` e reduzir fontSize se necessário (edge case spec).
- **Tamanho do Container**: O círculo pode precisar de um tamanho mínimo (ex.: width/height 40 ou 44) para caber ícone + número; hoje usa apenas padding 8 e o ícone 24. Aumentar ligeiramente se o número ficar cortado.

## Phases & Milestones

### Phase 1: Indicador verde com número (única fase)

**Objetivo**: No estado "sucesso", o indicador circular exibe o número da página junto com o ícone.

- Em `tela_lista_paginas.dart`, no `itemBuilder` do ListView.builder, localizar o `Container` que desenha o indicador (decoration circle + child Icon).
- Para `img.estadoTarget == 'sucesso'`, substituir o `child: Icon(...)` por um widget composto (ex.: Column) que inclua:
  - O mesmo `Icon(Icons.check_circle, color: cor, size: 24)`.
  - Um `Text` com o valor de página: `img.numeroPagina ?? img.ordem`; se ambos forem nulos, usar "—". Estilo: fontSize 10 ou 11, color cor (ou Colors.white), fontWeight adequado.
- Garantir que o número corresponde à linha (já garantido por ser o mesmo `img`).
- Edge case: número com muitos dígitos — envolver o Text em `FittedBox` ou usar um fontSize que permita 2–3 dígitos no círculo; acima disso, reduzir ligeiramente ou abreviar (ex.: "99+").
- Os outros estados continuam com `child: Icon(...)` apenas, sem número.

**Checkpoint**: Abrir um livro com pelo menos uma página em "sucesso"; o indicador verde mostra o ícone e o número da página; outras cores mantêm-se iguais.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| (Nenhuma) | — | — |

## Implementation Strategy

- **Única alteração**: Um único ficheiro (`tela_lista_paginas.dart`), um único bloco (o widget do indicador). Pode ser feito em uma task.
- **Ordem**: Implementar Phase 1; validar manualmente com livro que tenha páginas em estado "sucesso".
