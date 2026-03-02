# Feature Specification: Pipeline de Targets AR para Páginas Escaneadas

**Feature Branch**: `003-ar-target-pipeline`  
**Created**: 2026-02-27  
**Status**: Draft  
**Input**: (1) Após escanear, preencher formulário e salvar, a aplicação deve reconhecer a página como target de RA. (2) Analisar imagem para detectar se é página de livro e extrair número da página (capa = 0). (3) Pipeline Vuforia-like: detecção de características, descrição, geração de target, matching em tempo real. (4) Avaliar tela RA atual (Augen) — manter ou reconstruir.

## Clarifications

### Session 2026-02-27

- Q: Quando a imagem não parece uma página de livro, o que deve fazer o sistema? → A: Marcar como "não-página" mas manter no scan; não gerar target.
- Q: Como tratar imagens de baixa qualidade (pouco contraste, desfocadas) que geram targets fracos? → A: Tentar gerar target na mesma; aceitar mesmo com qualidade baixa.
- Q: Quando o processamento de targets falha, o que exibir ao utilizador? → A: Indicador visual na lista de páginas do livro: botão verde para targets que deram certo, vermelho para os que falharam.
- Q: Como ordenar páginas quando o número não é detectável? → A: Deixar numero_pagina como null; ordenar apenas por ordem de escaneamento.
- Q: O processamento de targets deve ser síncrono ou assíncrono? → A: Assíncrono em background. Botão amarelo e não clicável durante processamento; ao terminar, muda automaticamente para verde (sucesso) ou vermelho (falha), sem necessidade de atualizar a tela.
- Q: Onde deve aparecer a lista de páginas do livro com indicadores verde/amarelo/vermelho? → A: Nova tela: ao tocar num livro na lista principal, abre primeiro a lista de páginas; ao tocar numa página verde, abre a tela de RA.
- Q: Imagens "não-página" devem aparecer na lista? Com que indicador? → A: Sim, aparecer com indicador cinzento (não gera target; apenas visualização).
- Q: Quando uma página falha (vermelho), o utilizador deve poder reprocessar? → A: Sim. Ao clicar em vermelho: botão fica amarelo (não clicável), inicia retentativa. Se falhar novamente: botão fica roxo. Ao clicar em roxo: pede ao utilizador para escanear a página novamente, redireciona para tela de escanear; ao capturar, substitui a imagem (ficheiro e path na BD). A página pertence a um livro já agrupado (já tem título).
- Q: Na tela de escanear para rescanear uma página roxa, o utilizador vê apenas o scanner para aquela página ou TelaGaleria completa? → A: Apenas scanner para a página única; ao capturar, substitui a imagem e regressa à lista de páginas.
- Q: Como determinar se uma imagem é a capa do livro (numero_pagina = 0)? → A: Análise de imagem: detecção de layout típico de capa (título grande, autor, etc.).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reconhecimento de Página como Target AR (Priority: P1)

O utilizador escaneia páginas de um livro, preenche o formulário (título, autor, resumo) e guarda. A aplicação processa as imagens e gera targets de RA. Ao tocar num livro na lista principal, abre a lista de páginas (com indicadores verde/amarelo/vermelho/roxo/cinzento). Ao tocar numa página verde, abre a tela de RA; ao apontar a câmera para a página física, permite ancorar anotações 3D.

**Why this priority**: É o fluxo central — sem targets gerados a partir das páginas escaneadas, a RA não funciona com as páginas reais do livro.

**Independent Test**: Escanear uma página, guardar, tocar no livro na lista, verificar lista de páginas com indicadores, tocar numa página verde, apontar a câmera para a página física; verificar reconhecimento e anotação 3D.

**Acceptance Scenarios**:

1. **Given** o utilizador guardou um scan com pelo menos uma página, **When** o processamento de targets termina, **Then** cada página está disponível como target de RA
2. **Given** o utilizador está na tela de RA com um livro aberto, **When** aponta a câmera para uma página escaneada desse livro, **Then** o sistema reconhece a página e permite ancorar conteúdo 3D
3. **Given** o utilizador aponta para uma página não escaneada, **Then** o sistema não reconhece (sem falso positivo)
4. **Given** o utilizador guardou um scan e toca num livro na lista principal, **When** a nova tela de lista de páginas abre, **Then** vê botões amarelos (processando) que atualizam automaticamente para verde ou vermelho ao terminar, sem refresh manual
5. **Given** o utilizador está na lista de páginas de um livro, **When** toca numa página com indicador verde, **Then** abre a tela de RA para aquela página
6. **Given** uma página tem indicador vermelho, **When** o utilizador toca, **Then** botão fica amarelo e inicia retentativa; se falhar novamente, fica roxo
7. **Given** uma página tem indicador roxo, **When** o utilizador toca, **Then** abre scanner apenas para aquela página; ao capturar, substitui a imagem (ficheiro e path na BD) e regressa à lista de páginas

---

### User Story 2 - Análise de Imagem e Número da Página (Priority: P2)

Antes de gerar o target, o sistema analisa cada imagem. Se parecer uma página de livro, extrai o número da página (ex.: "Página 42") e armazena na base de dados. A capa é detectada por análise de layout (título grande, autor, etc.) e recebe numero_pagina = 0.

**Why this priority**: Permite ordenação e identificação correta das páginas; capa tratada de forma especial.

**Independent Test**: Escanear capa e páginas internas; guardar; verificar na base de dados que a capa tem número 0 e as demais têm números extraídos ou estimados.

**Acceptance Scenarios**:

1. **Given** a imagem é reconhecida como capa (layout típico: título grande, autor), **When** o sistema processa, **Then** armazena numero_pagina como 0
2. **Given** a imagem é reconhecida como página interna, **When** o sistema processa, **Then** extrai e armazena o número da página (se detectável)
3. **Given** o número da página não é detectável, **Then** o sistema armazena numero_pagina como null e ordena por ordem de escaneamento

---

### User Story 3 - Tela de RA Funcional (Priority: P3)

A tela de RA, aberta ao tocar num livro na lista, deve funcionar corretamente. O sistema deve avaliar se a implementação atual (Augen) suporta image tracking e, se sim, corrigir ou adaptar. Caso contrário, a solução deve ser reconstruída com tecnologia adequada.

**Why this priority**: Sem tela de RA funcional, o utilizador não consegue usar a funcionalidade central do app.

**Independent Test**: Tocar num livro na lista; verificar que a tela de RA abre, a câmera funciona e o reconhecimento de páginas/targets opera conforme esperado.

**Acceptance Scenarios**:

1. **Given** o utilizador toca num livro na lista, **When** a lista de páginas abre, **Then** vê as páginas com indicadores; ao tocar numa verde, a tela de RA abre com câmera pronta para reconhecer targets
2. **Given** o utilizador está na tela de RA, **When** aponta para uma página escaneada, **Then** o conteúdo 3D pode ser ancorado na posição correta
3. **Given** falha de permissão ou hardware não suportado, **Then** o sistema exibe mensagem clara e não entra em crash

---

### Edge Cases

- Quando a imagem não parece uma página de livro: marcar como "não-página", manter no scan, não gerar target; aparecer na lista com indicador cinzento.
- Imagens de baixa qualidade: tentar gerar target na mesma; aceitar mesmo com qualidade baixa.
- Processamento em background: botão amarelo (não clicável) durante processamento; ao terminar, verde (sucesso) ou vermelho (falha). Vermelho: ao clicar → amarelo, retentativa. Se falhar de novo → roxo. Roxo: ao clicar → pede rescanear, redireciona para escanear; ao capturar, substitui a imagem (ficheiro e path na BD); página pertence a livro já agrupado.
- Quando o número não é detectável: numero_pagina fica null; ordenação por ordem de escaneamento.
- Quando a detecção de capa (layout) não identifica nenhuma imagem como capa: tratar como null ou ordem de escaneamento; decisão no plano técnico.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Após o utilizador guardar um scan (formulário preenchido), o sistema MUST processar cada imagem escaneada para gerar um target de RA utilizável
- **FR-002**: O sistema MUST reconhecer páginas escaneadas em tempo real quando a câmera aponta para a página física, permitindo ancorar conteúdo 3D
- **FR-003**: O sistema MUST analisar cada imagem para determinar se é capa (número 0) ou página interna; a capa é detectada por análise de layout típico (título grande, autor, etc.); extrair o número da página quando possível
- **FR-004**: O número da página MUST ser armazenado na base de dados associado a cada imagem (int; 0 = capa, null quando não detectável); ordenação por ordem de escaneamento
- **FR-005**: O pipeline de geração de targets MUST incluir: extração de características da imagem, criação de descritores invariantes a escala/rotação, geração de banco de targets, e matching em tempo real entre câmera e targets (cf. Assumptions — satisfeito por ARCore/ARKit quando a imagem é usada como referência)
- **FR-006**: O sistema MUST avaliar a qualidade da distribuição de pontos de interesse na imagem; targets com distribuição inadequada devem ser sinalizados ou rejeitados
- **FR-010**: Imagens de baixa qualidade (pouco contraste, desfocadas) MUST gerar target na mesma; o sistema aceita targets mesmo com qualidade baixa
- **FR-011**: O processamento de targets MUST ocorrer em background (assíncrono) após guardar
- **FR-012**: Na lista de páginas do livro, o sistema MUST exibir indicador visual por página: amarelo (processando, não clicável), verde (sucesso), vermelho (falha, clicável para retry), roxo (falha após retry, clicável para rescan); atualização automática sem refresh manual
- **FR-013**: Imagens "não-página" MUST aparecer na lista com indicador cinzento (apenas visualização; não gera target)
- **FR-014**: Páginas com indicador vermelho (falha): ao clicar, botão MUST ficar amarelo (não clicável) e iniciar retentativa. Se falhar novamente, botão MUST ficar roxo
- **FR-015**: Páginas com indicador roxo (falha após retentativa): ao clicar, MUST abrir apenas o scanner para aquela página única; ao capturar, substituir a imagem (ficheiro e path na BD) e regressar à lista de páginas do livro
- **FR-007**: Ao tocar num livro na lista principal, o sistema MUST abrir uma nova tela com a lista de páginas do livro (indicadores verde/amarelo/vermelho/roxo/cinzento); ao tocar numa página verde, MUST abrir a tela de RA para aquela página
- **FR-008**: A solução de RA MUST suportar image tracking para páginas escaneadas; a decisão de manter Augen ou adotar alternativa será documentada no plano técnico
- **FR-009**: Quando a imagem não for reconhecida como página de livro, o sistema MUST marcá-la como "não-página", mantê-la no scan e NÃO gerar target para ela

### Key Entities

- **Scan / Livro**: Já existente. Atributos: id, titulo, autor, resumo, data_criacao, imagens.
- **Imagem / Página**: Cada imagem de um scan. Novos atributos: numero_pagina (int?, 0 = capa, null = não detectável; ordenação por ordem de escaneamento), qualidade_target (opcional), caminho da imagem usada como referência (a própria imagem serve de target; sem ficheiro de target separado), eh_pagina (bool; false = "não-página", sem target gerado).
- **Target de RA**: Representação processada de uma imagem para reconhecimento em tempo real; armazena características extraídas e metadados de qualidade.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Utilizadores conseguem apontar a câmera para uma página escaneada e ver o reconhecimento em menos de 3 segundos
- **SC-002**: Pelo menos 80% das páginas escaneadas (com qualidade mínima) geram targets utilizáveis
- **SC-003**: O número da página é corretamente identificado (capa = 0, ou número extraído) em pelo menos 70% dos casos quando o texto é legível
- **SC-004**: A tela de RA abre e opera sem crash em dispositivos compatíveis (ARCore/ARKit)

## Assumptions

- O pipeline Vuforia-like (detecção de características, descrição, target DB, matching) é o modelo conceptual; a implementação concreta pode usar bibliotecas existentes (ARCore Augmented Images, Vuforia, OpenCV, etc.). **FR-005 é satisfeito quando ARCore/ARKit realizam extração de características, descritores e matching em tempo real a partir da imagem de referência** (sem pipeline customizado).
- Augen suporta Image Tracking (conforme documentação); a avaliação determinará se a implementação atual pode ser adaptada
- O processamento de targets pode ser feito localmente no dispositivo ou em backend; a decisão será tomada no plano técnico
- A base de dados atual (scans, imagens) será estendida para incluir numero_pagina e metadados; a imagem em `caminho` serve diretamente como referência para AR (sem ficheiro de target separado)
