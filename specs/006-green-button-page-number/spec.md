# Feature Specification: Número da página no indicador verde

**Feature Branch**: `006-green-button-page-number`  
**Created**: 2026-02-26  
**Status**: Draft  
**Input**: Apresentar o número da página no botão verde.

## Clarifications

### Session 2026-02-26

- Q: No indicador verde, o número da página deve substituir o ícone (✓) ou aparecer junto com ele? → A: Número junto com o ícone: o círculo verde mostra o número e mantém o ícone (check).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver número da página no indicador verde (Priority: P1)

Na lista de páginas do livro (TelaListaPaginas), cada página é exibida numa linha com uma miniatura, o texto "Página X" e um indicador circular à direita. Quando o estado da página é "sucesso" (pronta para RA), o indicador fica verde. O utilizador deve conseguir ver o **número da página** apresentado no próprio indicador verde **junto com o ícone** (check): o círculo verde mostra o número e mantém o ícone, de forma a identificar rapidamente qual página está pronta para RA sem depender apenas do texto da linha.

**Why this priority**: Melhora a legibilidade e a identificação rápida das páginas prontas para RA; é o único requisito desta feature.

**Independent Test**: Abrir um livro com pelo menos uma página em estado "sucesso" (verde); verificar que o indicador verde exibe o número da página de forma legível.

**Acceptance Scenarios**:

1. **Given** o utilizador está na lista de páginas de um livro, **When** existe pelo menos uma página com estado "sucesso" (indicador verde), **Then** o indicador verde exibe o número da página de forma visível e legível
2. **Given** várias páginas estão em estado "sucesso", **When** o utilizador percorre a lista, **Then** cada indicador verde mostra o número correspondente à respetiva página
3. **Given** uma página está em estado diferente de "sucesso" (amarelo, vermelho, roxo, cinzento), **When** o utilizador visualiza a lista, **Then** o indicador continua a comportar-se como hoje (sem obrigação de mostrar número nesses estados, salvo decisão de desenho)

---

### Edge Cases

- Página sem número atribuído (ex.: ordem ou numero_pagina indefinido): o sistema deve exibir um valor fallback (ex.: ordem da imagem ou "—") para evitar indicador vazio ou erro
- Muitos dígitos (ex.: página 1000): o número deve caber no indicador circular sem quebrar o layout (truncar, reduzir tamanho de fonte ou abreviar conforme desenho)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Na lista de páginas do livro, o indicador circular **verde** (estado "sucesso") MUST exibir o número da página de forma visível e legível para o utilizador, **mantendo o ícone** (check) visível no mesmo indicador
- **FR-002**: O número exibido no indicador verde MUST corresponder à página da respetiva linha (utilizar numero_pagina quando disponível; caso contrário, ordem ou valor fallback consistente)
- **FR-003**: Os indicadores de outros estados (amarelo, vermelho, roxo, cinzento) podem manter o comportamento atual; a alteração MUST aplicar-se pelo menos ao indicador verde

### Key Entities

- **Página / Imagem**: Representa uma página do livro na lista; possui estado (processando, sucesso, falha, rescan, nao_pagina), ordem e, quando disponível, numero_pagina. O indicador verde está associado ao estado "sucesso".

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: O utilizador identifica, em menos de 3 segundos, qual o número da página pronta para RA ao olhar para o indicador verde na lista
- **SC-002**: Em 100% das páginas em estado "sucesso", o número exibido no indicador verde corresponde à página correta (sem trocas entre linhas)

## Assumptions

- O contexto é a TelaListaPaginas existente (lista de páginas do livro com indicadores por estado).
- "Botão verde" refere-se ao indicador circular à direita de cada linha quando o estado é "sucesso".
- O número é apresentado **junto com o ícone** no indicador verde; o desenho exacto (número ao lado do ícone, por cima, ou disposição no círculo) fica ao critério do plano técnico, desde que ambos (número e ícone) permaneçam visíveis e legíveis.
