# Feature Specification: Botão Escanear Redondo + Persistência de Scans

**Feature Branch**: `001-round-scan-button-storage`  
**Created**: 2026-02-26  
**Status**: Draft  
**Input**: Botão "Escanear nova página" redondo com ícone livro+; storage para imagens; banco de dados para metadados; popup título obrigatório; redirecionamento após salvar.

## Clarifications

### Session 2026-02-26

- Q: Quando o utilizador toca em "Gerar Targets de RA" sem ter escaneado nenhuma página, qual deve ser o comportamento? → A: Botão desativado (cinzento) quando não há páginas escaneadas
- Q: O sistema deve permitir múltiplos scans com o mesmo título de livro? → A: Sim, permitir (cada scan é independente)
- Q: Editar ou eliminar scans guardados deve fazer parte desta feature? → A: Não nesta feature (apenas guardar e persistir)
- Q: Onde devem ficar guardadas as imagens no dispositivo? → A: Diretório privado da aplicação (não visível na galeria)
- Q: Após o salvamento e redirecionamento, deve haver feedback visual de confirmação? → A: Sim, mostrar mensagem de confirmação (ex: SnackBar ou toast)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Botão Redondo de Escanear (Priority: P1)

O utilizador vê na tela principal um botão redondo, fixo no centro inferior da tela, com ícone de livro e símbolo de mais (+). Ao tocar no botão, a aplicação abre a TelaGaleria (Scanner) para captura de páginas.

**Why this priority**: Melhora imediata da experiência de uso; ponto de entrada principal para o fluxo de escaneamento.

**Independent Test**: Verificar que o botão aparece na posição correta, possui o ícone descrito, e que ao tocar abre a TelaGaleria.

**Acceptance Scenarios**:

1. **Given** o utilizador está na tela principal, **When** visualiza a tela, **Then** vê um botão redondo no centro inferior com ícone de livro e símbolo "+"
2. **Given** o utilizador está na tela principal, **When** toca no botão redondo, **Then** a TelaGaleria (Scanner) é aberta
3. **Given** o utilizador está na TelaGaleria, **When** fecha ou volta, **Then** retorna à tela principal

---

### User Story 2 - Persistência de Imagens e Metadados (Priority: P2)

Após escanear páginas, o utilizador pode guardar as imagens no dispositivo. As imagens físicas (.jpg, .png) são armazenadas em storage local. Os metadados (título do livro, autor, resumo) e o caminho que aponta para cada imagem são guardados numa base de dados local.

**Why this priority**: Permite que os scans persistam entre sessões; base para funcionalidades futuras (listar livros, recuperar targets RA).

**Independent Test**: Escanear páginas, preencher metadados, salvar; fechar a aplicação; reabrir e verificar que os dados persistem.

**Acceptance Scenarios**:

1. **Given** o utilizador escaneou uma ou mais páginas na TelaGaleria, **When** preenche o formulário e confirma, **Then** as imagens são guardadas em storage local no dispositivo
2. **Given** as imagens foram guardadas, **When** o sistema persiste os metadados, **Then** a base de dados guarda título, autor, resumo e caminho(s) para cada imagem
3. **Given** o utilizador fechou a aplicação, **When** reabre a aplicação, **Then** os scans guardados permanecem disponíveis (imagens e metadados)

---

### User Story 3 - Formulário Popup de Título e Redirecionamento (Priority: P3)

O botão "Gerar Targets de RA" na TelaGaleria abre um formulário popup que solicita o título do livro (obrigatório). O utilizador pode também preencher autor e resumo. Após pressionar salvar, o sistema persiste os dados e redireciona o utilizador para a tela principal.

**Why this priority**: Garante que cada scan tenha identificação mínima (título); completa o fluxo de salvamento com feedback claro.

**Independent Test**: Na TelaGaleria com páginas escaneadas, tocar em "Gerar Targets de RA"; verificar que o popup aparece; tentar salvar sem título (deve bloquear); preencher título e salvar (deve redirecionar).

**Acceptance Scenarios**:

1. **Given** o utilizador tem páginas escaneadas na TelaGaleria, **When** toca em "Gerar Targets de RA", **Then** um formulário popup é exibido solicitando o título do livro
2. **Given** o popup está aberto, **When** o utilizador tenta salvar sem preencher o título, **Then** o sistema impede o salvamento e indica que o título é obrigatório
3. **Given** o utilizador preencheu o título (e opcionalmente autor e resumo), **When** toca em salvar, **Then** os dados são persistidos, o utilizador é redirecionado para a tela principal e vê mensagem de confirmação (ex: SnackBar ou toast)
4. **Given** o utilizador está no popup, **When** cancela ou fecha sem salvar, **Then** permanece na TelaGaleria com as páginas escaneadas intactas

---

### Edge Cases

- O botão "Gerar Targets de RA" MUST estar desativado (cinzento) quando não há páginas escaneadas.
- Como o sistema trata falha de permissão de armazenamento ao guardar imagens? Deve informar o utilizador e não perder os dados em memória até que a permissão seja concedida.
- O que acontece se o dispositivo ficar sem espaço ao guardar imagens? O sistema deve informar o utilizador e permitir retry ou cancelamento.
- Como o sistema trata caracteres especiais ou nomes de ficheiro longos no título do livro? Deve sanitizar ou truncar conforme necessário para evitar erros de storage.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O botão "Escanear nova página" MUST ser redondo, posicionado no centro inferior da tela principal, com ícone de livro e símbolo "+"
- **FR-002**: Ao tocar no botão de escanear, o sistema MUST abrir a TelaGaleria (Scanner)
- **FR-003**: O sistema MUST persistir imagens escaneadas (.jpg, .png) em storage local no dispositivo, em diretório privado da aplicação (não visível na galeria do sistema)
- **FR-004**: O sistema MUST utilizar uma base de dados local para guardar metadados: título do livro, autor, resumo e caminho(s) que apontam para as imagens guardadas
- **FR-005**: O botão "Gerar Targets de RA" na TelaGaleria MUST estar desativado quando não há páginas escaneadas e MUST abrir um formulário popup (quando há páginas) com campo de título do livro (obrigatório) e campos opcionais para autor e resumo
- **FR-006**: O sistema MUST impedir o salvamento quando o título do livro não for preenchido
- **FR-007**: Após o utilizador confirmar o salvamento no popup, o sistema MUST persistir os dados, redirecionar para a tela principal e exibir mensagem de confirmação (ex: SnackBar ou toast)
- **FR-008**: O sistema MUST solicitar permissão de armazenamento no momento de guardar imagens, quando aplicável
- **FR-009**: O sistema MUST tratar falhas de persistência (permissão negada, espaço insuficiente) com mensagem clara ao utilizador

### Key Entities

- **Scan / Livro**: Representa uma sessão de escaneamento. Atributos: título (obrigatório), autor, resumo, data de criação. Relaciona-se com uma ou mais imagens. O sistema permite múltiplos scans com o mesmo título (cada scan é independente).
- **Imagem**: Ficheiro de imagem (.jpg, .png) guardado em diretório privado da aplicação. Atributos: caminho no dispositivo, formato. Cada imagem pertence a um Scan.
- **Registo de Metadados**: Entrada na base de dados que associa título, autor, resumo ao caminho de cada imagem do scan.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Utilizadores conseguem iniciar o fluxo de escaneamento com um único toque no botão redondo em menos de 2 segundos
- **SC-002**: 100% dos scans guardados com título preenchido persistem após fechar e reabrir a aplicação
- **SC-003**: Utilizadores conseguem completar o fluxo completo (escanear → preencher título → salvar → ver tela principal) em menos de 1 minuto para uma sessão típica de 5 páginas
- **SC-004**: Falhas de permissão ou espaço são comunicadas ao utilizador em todas as situações relevantes, sem crash da aplicação

## Assumptions

- Editar ou eliminar scans guardados está fora do âmbito desta feature; apenas guardar e persistir.
- O ícone "livro com +" pode ser implementado com ícones disponíveis na biblioteca do projeto (Material Icons, Cupertino) ou um asset customizado; o utilizador referenciou um ícone anexo como referência visual
- Autor e resumo são campos opcionais; apenas o título é obrigatório
- O storage local e a base de dados são exclusivos ao dispositivo (sem sincronização em nuvem nesta feature)
- O fluxo de "processamento na nuvem" (simulação atual) permanece após o redirecionamento para a tela principal; esta feature foca na persistência e no novo fluxo do botão/formulário
