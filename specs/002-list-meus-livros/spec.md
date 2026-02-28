# Feature Specification: Tela Principal - Lista Meus Livros

**Feature Branch**: `002-list-meus-livros`  
**Created**: 2026-02-26  
**Status**: Draft  
**Input**: Tela principal torna-se lista; header "Meus Livros"; itens como botões com título do livro; clique redireciona para visualizador RA; FAB adicionar/escanear mantido.

## Clarifications

### Session 2026-02-26

- Q: Quando a lista está vazia, o que deve ser exibido? → A: Mensagem explícita (ex: "Nenhum livro guardado. Toque no botão + para escanear.")
- Q: Durante o carregamento da lista, deve haver indicador de loading? → A: Sim. Estratégia em 3 fases: (1) Busca da quantidade de livros para saber quantos botões/slots na lista; (2) Skeleton loader animado com N placeholders onde o texto irá aparecer; (3) Busca das informações de cada item da lista por último.
- Q: Quando o utilizador toca num livro cujas imagens foram removidas do storage, o que acontece na UI? → A: Toast breve + remover automaticamente o livro da lista.
- Q: Se o título do livro estiver vazio ou inexistente, o que exibir no item da lista? → A: O modelo garante título sempre preenchido; não tratar este caso.
- Q: Se a busca de quantidade (fase 1) ou de detalhes (fase 3) falhar, o que exibir ao utilizador? → A: Mensagem genérica e manter skeleton até o utilizador reabrir a app.
- Q: Quando o utilizador volta da TelaGaleria após guardar um novo livro, a lista deve ser atualizada automaticamente? → A: Sim, atualizar a lista imediatamente ao voltar (refresh automático).
- Q: O utilizador deve poder atualizar a lista manualmente (ex.: pull-to-refresh)? → A: Sim, incluir pull-to-refresh para atualizar a lista manualmente.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Lista de Livros na Tela Principal (Priority: P1)

O utilizador abre a aplicação e vê a tela principal como uma lista de livros guardados. No topo há um header com o título "Meus Livros". Abaixo, uma lista scrollável onde cada item é um botão que exibe o título do livro guardado na base de dados.

**Why this priority**: Transforma a tela principal no hub de acesso aos livros escaneados; ponto de entrada para visualização em RA.

**Independent Test**: Abrir a app; verificar header "Meus Livros"; verificar skeleton loader durante carregamento; verificar lista com títulos (ou vazia); verificar pull-to-refresh.

**Acceptance Scenarios**:

1. **Given** o utilizador abre a aplicação, **When** a tela principal carrega, **Then** vê um header com o título "Meus Livros"
2. **Given** existem scans guardados na base de dados, **When** a tela principal carrega, **Then** cada scan aparece como um item na lista com o título do livro
3. **Given** não existem scans guardados, **When** a tela principal carrega, **Then** exibe mensagem explícita (ex: "Nenhum livro guardado. Toque no botão + para escanear.")
4. **Given** a lista tem vários itens, **When** o utilizador faz scroll, **Then** a lista é scrollável
5. **Given** o utilizador está na tela principal, **When** faz pull-to-refresh, **Then** a lista é atualizada
6. **Given** a tela principal está a carregar, **When** a quantidade de scans é conhecida, **Then** exibe skeleton loader com N placeholders animados; após carregar detalhes, os placeholders são substituídos pelos títulos

---

### User Story 2 - Navegação para Visualizador RA (Priority: P2)

Ao tocar num item da lista (botão com título do livro), o utilizador é redirecionado para a tela do Visualizador RA (a mesma que era aberta pelo botão "Abrir Visualizador RA").

**Why this priority**: Permite ao utilizador aceder a um livro específico e visualizar em RA.

**Independent Test**: Com pelo menos um livro na lista, tocar no item; verificar que a tela de RA abre.

**Acceptance Scenarios**:

1. **Given** o utilizador está na tela principal com livros na lista, **When** toca num item (botão com título do livro), **Then** é redirecionado para a tela do Visualizador RA
2. **Given** o utilizador está no Visualizador RA, **When** volta (botão ou gesto), **Then** retorna à tela principal (lista)
3. **Given** o utilizador toca num livro cujas imagens foram removidas do storage, **When** o sistema detecta o erro, **Then** exibe toast breve e remove o livro da base de dados e da lista

---

### User Story 3 - FAB Adicionar/Escanear (Priority: P3)

O botão flutuante (FAB) no centro inferior da tela permanece disponível para adicionar/escanear novos livros. Ao tocar, abre a TelaGaleria (Scanner) para captura de páginas.

**Why this priority**: Mantém o fluxo de escaneamento já implementado; consistência com a feature 001.

**Independent Test**: Na tela principal, tocar no FAB; verificar que a TelaGaleria abre.

**Acceptance Scenarios**:

1. **Given** o utilizador está na tela principal, **When** visualiza a tela, **Then** vê o FAB no centro inferior (ícone livro+)
2. **Given** o utilizador está na tela principal, **When** toca no FAB, **Then** a TelaGaleria (Scanner) é aberta
3. **Given** o utilizador está na TelaGaleria, **When** fecha ou volta, **Then** retorna à tela principal (lista); se guardou um novo livro, a lista é atualizada automaticamente

---

### Edge Cases

- Quando a lista está vazia, o sistema MUST exibir mensagem explícita (ex: "Nenhum livro guardado. Toque no botão + para escanear.")
- Durante o carregamento: skeleton loader em 3 fases (count → placeholders → detalhes).
- Se a busca (fase 1 ou 3) falhar: exibir mensagem genérica e manter skeleton até o utilizador reabrir a app.
- A lista é ordenada por data de criação (mais recente primeiro).
- Se o utilizador tocar num livro cujas imagens foram removidas do storage: exibir toast breve e remover automaticamente o livro da base de dados e da lista.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A tela principal MUST exibir um header com o título "Meus Livros"
- **FR-002**: A tela principal MUST exibir uma lista scrollável de livros guardados na base de dados
- **FR-003**: Cada item da lista MUST ser um botão que exibe o título do livro (campo `titulo` do Scan)
- **FR-004**: Ao tocar num item da lista, o sistema MUST redirecionar o utilizador para a tela do Visualizador RA (TelaAR)
- **FR-005**: O FAB de adicionar/escanear MUST permanecer no centro inferior da tela e abrir a TelaGaleria ao tocar
- **FR-006**: A lista MUST ser carregada a partir da base de dados (tabela `scans`); se vazia, exibir mensagem explícita (ex: "Nenhum livro guardado. Toque no botão + para escanear.")
- **FR-007**: A lista MUST ser ordenada por data de criação (mais recente primeiro)
- **FR-008**: O carregamento da lista MUST seguir 3 fases: (1) Busca da quantidade de scans para determinar N slots; (2) Se N > 0, exibição de skeleton loader animado com N placeholders onde o texto irá aparecer; (3) Busca das informações de cada item (id, titulo, etc.) e preenchimento dos placeholders. Se N = 0, exibir diretamente a mensagem de lista vazia.
- **FR-009**: Se o utilizador tocar num livro cujas imagens foram removidas do storage, o sistema MUST exibir um toast breve e remover automaticamente o scan da base de dados e da lista.
- **FR-010**: Se a busca de quantidade (fase 1) ou de detalhes (fase 3) falhar, o sistema MUST exibir mensagem genérica e manter o skeleton até o utilizador reabrir a app.
- **FR-011**: Ao voltar da TelaGaleria para a tela principal, a lista MUST ser atualizada automaticamente (refresh) para refletir livros recém-guardados.
- **FR-012**: A lista MUST suportar pull-to-refresh para permitir atualização manual pelo utilizador.

### Key Entities

- **Scan / Livro**: Já existente (feature 001). Atributos: id, titulo, autor, resumo, data_criacao. Relaciona-se com Imagens.
- **Lista de livros**: Representação na UI dos scans guardados; cada item mapeia para um Scan.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Utilizadores conseguem ver todos os livros guardados na tela principal em menos de 2 segundos após abrir a app
- **SC-002**: Utilizadores conseguem abrir o Visualizador RA de um livro com um único toque no item da lista
- **SC-003**: O FAB permanece visível e acessível em todos os estados da lista (vazia ou com itens)

## Assumptions

- A base de dados e o modelo Scan já existem (feature 001)
- O Visualizador RA (TelaAR) recebe o identificador do livro selecionado para carregar as imagens corretas (ou será adaptado nesta feature)
- A imagem de referência mostra "Página X de Y" em cada item; esta informação pode ser adicionada se o total de páginas existir (count de imagens) — opcional para MVP
- O FAB mantém o mesmo layout (ícone livro+) da feature 001
- O `ScanDatabase` (ou serviço equivalente) precisará de: método para obter contagem de scans (`getScansCount` ou `SELECT COUNT(*)`); método para listar scans ordenados por data (`getScans` ou equivalente) para a fase 3
- O campo `titulo` do Scan é NOT NULL; não é necessário tratar o caso de título vazio ou inexistente
