# Feature Specification: Substituição Augen por OpenCV - Visualização AR

**Feature Branch**: `004-opencv-ar-visualization`  
**Created**: 2026-02-26  
**Status**: Draft  
**Input**: "exclua toda a implementação do Augen e crie todo o fluxo de visualização de realidade aumentada usando o OpenCV."

## Clarifications

### Session 2026-02-26

- Q: Em que contexto o utilizador pode tocar na tela para colocar uma anotação 3D (hit test)? → A: Apenas quando uma página está a ser rastreada; o toque coloca a anotação 3D sobre essa página. Sem detecção de planos genéricos (chão/paredes).
- Q: Para a feature 004, o suporte a Windows deve estar no âmbito ou fora? → A: Fora do âmbito para 004 — apenas Android e iOS; Windows fica explícito como não suportado nesta feature.
- Q: Quantas páginas (targets) podem estar ativas para reconhecimento em simultâneo numa sessão de RA? → A: Um subconjunto (ex.: a página escolhida + adjacentes ou as N mais recentes) para equilibrar performance.
- Q: A dica "Aponte para uma página escaneada" deve ser exibida após um tempo sem reconhecimento? Se sim, após quantos segundos? → A: Sim; exibir dica após 5 segundos sem reconhecimento de nenhum target.
- Q: Se a tela de RA for aberta e não houver nenhum target carregado (zero páginas em sucesso), o que deve acontecer? → A: Redirecionar: ao abrir, se não houver targets, mostrar mensagem e voltar automaticamente à lista de páginas.

## Summary

Substituir completamente o motor de Realidade Aumentada atual (Augen) por uma solução baseada em OpenCV. O utilizador mantém o mesmo fluxo: escanear páginas, guardar livro, abrir lista de páginas com indicadores, tocar numa página verde e ver a tela de RA que reconhece a página física e permite ancorar conteúdo 3D. A diferença está na tecnologia subjacente (OpenCV em vez de Augen).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Visualização AR com Reconhecimento de Páginas (Priority: P1)

O utilizador abre um livro na lista principal, vê a lista de páginas com indicadores, toca numa página verde e abre a tela de RA. Ao apontar a câmera para a página física escaneada, o sistema reconhece a página em tempo real e permite ancorar modelos 3D (anotações) sobre ela.

**Why this priority**: É o fluxo central do aplicativo; sem reconhecimento e sobreposição em tempo real, a funcionalidade de RA não existe.

**Independent Test**: Tocar num livro com pelo menos uma página verde, abrir a tela de RA, apontar a câmera para a página física; verificar que o conteúdo 3D é ancorado corretamente na posição da página.

**Acceptance Scenarios**:

1. **Given** o utilizador está na tela de RA com um livro aberto, **When** aponta a câmera para uma página escaneada desse livro, **Then** o sistema reconhece a página e permite ancorar conteúdo 3D
2. **Given** o utilizador aponta para uma superfície que não é uma página escaneada, **Then** o sistema não reconhece (evitar falsos positivos)
3. **Given** o utilizador aponta para a página escaneada, **When** o sistema reconhece, **Then** o modelo 3D (anotação) aparece ancorado à posição e orientação da página física
4. **Given** o utilizador toca na tela (hit test), **When** uma página está a ser rastreada, **Then** permite colocar anotação 3D sobre essa página

---

### User Story 2 - Integração com Pipeline de Targets Existente (Priority: P2)

O fluxo existente (lista de livros → lista de páginas com indicadores → tela de RA) permanece inalterado. O sistema continua a usar imagens com estado_target=sucesso como referência para reconhecimento. O processamento em background (TargetPipelineService, ImageAnalysisService) e a base de dados não são alterados.

**Why this priority**: Garante que a troca de Augen por OpenCV não quebra o fluxo já implementado (feature 003).

**Independent Test**: Escanear uma página, guardar, verificar que indicadores aparecem na lista de páginas; tocar numa página verde e abrir a tela de RA; verificar que a tela abre e opera.

**Acceptance Scenarios**:

1. **Given** existe um scan com páginas em estado sucesso, **When** o utilizador toca numa página verde, **Then** a tela de RA abre com as imagens do scan carregadas como targets
2. **Given** o utilizador está na tela de RA, **Then** a câmera exibe o feed em tempo real e os targets são reconhecidos a partir das imagens persistidas

---

### User Story 3 - Tratamento de Falhas e Permissões (Priority: P3)

A tela de RA deve tratar graciosamente falha de permissão de câmera e hardware não suportado. Mensagens claras ao utilizador; sem crash.

**Why this priority**: Conformidade com boas práticas e políticas de loja (Constitution V).

**Independent Test**: Negar permissão de câmera e abrir tela de RA; verificar mensagem clara. Em dispositivo sem suporte a AR, verificar mensagem adequada.

**Acceptance Scenarios**:

1. **Given** o utilizador negou permissão de câmera, **When** abre a tela de RA, **Then** o sistema exibe mensagem clara e não entra em crash
2. **Given** o dispositivo ou ambiente não suporta a funcionalidade AR, **When** o utilizador abre a tela de RA, **Then** o sistema exibe mensagem explicativa e não entra em crash

---

### Edge Cases

- Quando nenhum target é reconhecido durante 5 segundos: manter feed da câmera visível e exibir dica ("Aponte para uma página escaneada")
- Quando a iluminação é muito fraca: o reconhecimento pode falhar; o sistema deve continuar a exibir o feed e tentar reconhecer; não crash
- Quando o utilizador sai da tela de RA (back): liberar recursos da câmera e do processamento OpenCV
- Plataformas: OpenCV e a tela de RA são suportados apenas em Android e iOS para esta feature; Windows fica fora do âmbito (não suportado na 004)
- Se a tela de RA for aberta sem nenhum target (zero páginas em sucesso no subconjunto): exibir mensagem e voltar automaticamente à lista de páginas do livro

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST remover toda a dependência e código relacionado ao plugin Augen
- **FR-002**: O sistema MUST implementar o fluxo de visualização AR (câmera em tempo real + reconhecimento de imagens + sobreposição de modelos 3D) usando OpenCV
- **FR-003**: O sistema MUST reconhecer páginas escaneadas (imagens com estado_target=sucesso) em tempo real quando a câmera aponta para a página física, permitindo ancorar conteúdo 3D na posição e orientação corretas
- **FR-004**: O sistema MUST manter o fluxo de navegação existente: lista de livros → lista de páginas (indicadores) → tela de RA ao tocar numa página verde
- **FR-005**: O sistema MUST manter suporte a hit test para colocar anotações 3D apenas quando uma página está a ser rastreada; o toque coloca a anotação sobre essa página (sem detecção de planos genéricos)
- **FR-006**: O sistema MUST verificar permissão de câmera antes de inicializar o visualizador AR; em caso de negação ou hardware não suportado, exibir mensagem clara e não entrar em crash
- **FR-007**: O sistema MUST manter o tema escuro (AppBar #1E1E1E, background #121212) na tela de RA conforme Constitution
- **FR-008**: A solução OpenCV MUST suportar detecção de características da imagem, matching em tempo real entre o frame da câmera e as imagens de referência (targets), e estimativa de pose para ancoragem 3D
- **FR-009**: O suporte à tela de RA com OpenCV é obrigatório apenas para Android e iOS; Windows está fora do âmbito (não suportado na 004)
- **FR-010**: O sistema MUST carregar para reconhecimento um subconjunto de páginas do livro (ex.: página escolhida + adjacentes ou as N mais recentes), e não obrigatoriamente todas, para equilibrar performance
- **FR-011**: Quando nenhum target for reconhecido durante 5 segundos, o sistema MUST exibir a dica "Aponte para uma página escaneada" (mantendo o feed da câmera visível)
- **FR-012**: Se a tela de RA for aberta e não houver nenhum target carregado (zero páginas em sucesso), o sistema MUST exibir mensagem ao utilizador e voltar automaticamente à lista de páginas do livro

### Key Entities

- **Scan / Livro**: Inalterado. Atributos: id, titulo, autor, resumo, data_criacao, imagens.
- **Imagem / Página**: Inalterado. Atributos: numero_pagina, eh_pagina, estado_target, qualidade_target, caminho. As imagens com estado_target=sucesso servem como referência para o reconhecimento OpenCV.
- **Target de RA**: Representação usada pelo motor OpenCV para matching; derivada da imagem em caminho (extração de características, descritores). Sem ficheiro de target separado.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Utilizadores conseguem apontar a câmera para uma página escaneada e ver o reconhecimento e ancoragem 3D em menos de 5 segundos após apontar corretamente
- **SC-002**: A tela de RA abre e opera sem crash em dispositivos compatíveis; falhas de permissão ou suporte são tratadas graciosamente
- **SC-003**: O fluxo completo (lista de livros → lista de páginas → tela de RA) permanece funcional após a substituição
- **SC-004**: Nenhuma dependência ou código residual do Augen permanece no projeto

## Assumptions

- OpenCV será integrado via pacote Flutter (opencv_*, opencv_dart, ou similar) ou canal de método com implementação nativa; a decisão técnica será documentada no plano
- Em cada sessão de RA são carregadas apenas um subconjunto de targets (ex.: página escolhida + adjacentes ou N mais recentes); o critério exato (N, adjacentes) fica para o plano técnico
- O feed da câmera será obtido via camera ou similar; OpenCV processa os frames para detecção e matching; a renderização 3D pode usar Flutter (Overlay) ou solução nativa conforme viabilidade
- A Constituição (III) menciona augen nas dependências; esta feature altera o stack e MUST ser documentada em docs/ARQUITETURA.md antes do merge
- Plataformas alvo: Android e iOS apenas; Windows está fora do âmbito da feature 004 (não suportado)
