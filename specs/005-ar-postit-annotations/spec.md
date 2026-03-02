# Feature Specification: Post-it e anotações ancoradas na tela de RA

**Feature Branch**: `005-ar-postit-annotations`  
**Created**: 2026-02-26  
**Status**: Draft  
**Input**: Botão redondo com ícone de nota na tela de RA; mira vermelha no centro; objeto 3D em forma de post-it ancorado ao target quando o utilizador clica no botão com a mira dentro da área do target; post-it clicável abre balão de anotação (editar/guardar); anotações e posições persistidas para reaparecer ao reabrir a página.

## Clarifications

### Session 2026-02-26

- Q: Onde as anotações devem ser guardadas e em que âmbito são visíveis? → A: As anotações são guardadas apenas localmente neste dispositivo; ao reabrir a mesma página no mesmo aparelho, os post-its reaparecem, mas não são partilhados entre dispositivos.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Colocar post-it no target (Priority: P1)

O utilizador abre a tela de RA (ao tocar numa página verde). Na tela aparecem um botão redondo com ícone de nota na parte inferior e uma mira vermelha translúcida no centro do ecrã. Quando o utilizador toca no botão de nota e a mira está dentro da área do target reconhecido, o sistema coloca um objeto 3D em forma de post-it exactamente no ponto onde a mira está. O objeto fica ancorado ao target: se o utilizador rodar o livro ou mover o telemóvel, o post-it permanece no mesmo ponto relativo ao target.

**Why this priority**: É o gesto central para anotar; sem colocação ancorada não há anotações espaciais.

**Independent Test**: Abrir RA com um target reconhecido; verificar botão e mira; tocar no botão com a mira sobre o target e verificar que um post-it 3D aparece e permanece ancorado ao mover o dispositivo.

**Acceptance Scenarios**:

1. **Given** o utilizador está na tela de RA com um target reconhecido, **When** a tela está visível, **Then** vê um botão redondo com ícone de nota na parte inferior e uma mira vermelha translúcida no centro do ecrã
2. **Given** a mira está dentro da área do target, **When** o utilizador toca no botão de nota, **Then** um objeto 3D em forma de post-it aparece no ponto da mira e fica ancorado ao target
3. **Given** um post-it foi colocado no target, **When** o utilizador roda o target ou move o telemóvel, **Then** o post-it permanece fixo no mesmo ponto do target
4. **Given** a mira está fora da área do target, **When** o utilizador toca no botão de nota, **Then** nenhum post-it é criado (ou o sistema indica que deve apontar para o target)

---

### User Story 2 - Escrever e editar anotação no post-it (Priority: P2)

O objeto 3D post-it é clicável. Ao tocar nele, abre-se um balão (ou ecrã modal) de anotação com um campo de texto e um botão "OK". O utilizador escreve a anotação e toca em OK; a anotação fica guardada e o balão fecha, voltando à vista de RA com o post-it ainda visível e ancorado. Se o utilizador tocar novamente no post-it, o balão abre de novo mostrando o texto já guardado e permitindo editar; ao tocar OK a anotação actualizada é guardada.

**Why this priority**: Sem texto associado ao post-it, o objecto 3D não entrega o valor de "anotação".

**Independent Test**: Colocar um post-it, tocar nele, escrever texto e OK; verificar que ao tocar de novo o mesmo texto aparece e pode ser editado.

**Acceptance Scenarios**:

1. **Given** existe um post-it ancorado no target, **When** o utilizador toca no post-it, **Then** abre um balão de anotação com campo de texto e botão OK
2. **Given** o balão está aberto, **When** o utilizador escreve texto e toca OK, **Then** a anotação é guardada, o balão fecha e o utilizador volta à vista de RA com o post-it visível
3. **Given** o post-it já tem anotação guardada, **When** o utilizador toca no post-it, **Then** o balão abre com o conteúdo anterior e o utilizador pode editar e guardar com OK

---

### User Story 3 - Persistência e restauro das anotações (Priority: P3)

As anotações e a posição de cada post-it são guardadas na base de dados e associadas à página (target) e ao livro. Quando o utilizador acede novamente à mesma página no futuro (abre o livro, toca na página verde, entra na tela de RA e o target é reconhecido), o sistema mostra os objetos 3D post-it nas posições guardadas, com as anotações correspondentes. O utilizador pode continuar a ver, tocar para editar ou colocar novos post-its.

**Why this priority**: Sem persistência, as anotações perdem-se ao sair; o valor da funcionalidade depende de as anotações reaparecerem na próxima visita.

**Independent Test**: Colocar um ou mais post-its com anotações, sair da RA e fechar o app; reabrir, abrir o mesmo livro e a mesma página em RA; verificar que os post-its e textos reaparecem nas posições correctas.

**Acceptance Scenarios**:

1. **Given** o utilizador colocou post-its com anotações numa página, **When** guarda e sai da tela de RA (ou da app), **Then** os dados (posição e texto) ficam persistidos
2. **Given** existem anotações guardadas para uma página, **When** o utilizador abre essa página em RA e o target é reconhecido, **Then** os objetos 3D post-it aparecem nas posições guardadas com as anotações visíveis (ou acessíveis ao toque)
3. **Given** o utilizador está a ver post-its restaurados, **When** toca num post-it, **Then** pode ver e editar a anotação como na User Story 2

---

### Edge Cases

- Se o utilizador tocar no botão de nota sem nenhum target reconhecido: o sistema não deve criar post-it; pode mostrar mensagem breve (ex.: "Aponte para a página para colocar uma anotação")
- Se o utilizador tocar no botão com a mira no limite da área do target: o sistema deve considerar "dentro" ou "fora" de forma consistente (ex.: considerar dentro se o centro da mira estiver dentro do polígono do target)
- Múltiplos post-its na mesma página: o sistema deve permitir vários post-its; cada um com a sua posição e anotação persistidas
- Tamanho máximo do texto da anotação: definir um limite razoável (ex.: 500 ou 1000 caracteres) para evitar abusos e problemas de armazenamento
- Ao eliminar ou alterar uma imagem/página no livro (ex.: rescan): as anotações associadas a essa página podem ser mantidas ou removidas conforme política; [assumir: manter referência por identificador de imagem; se a imagem for substituída, as anotações dessa "página" podem continuar associadas ao mesmo slot ou ser marcadas como órfãs]

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Na tela de RA, o sistema MUST exibir um botão redondo com ícone de nota na parte inferior do ecrã
- **FR-002**: Na tela de RA, o sistema MUST exibir uma mira vermelha translúcida (tipo laser) fixa no centro do ecrã
- **FR-003**: O sistema MUST permitir colocar um objeto 3D em forma de post-it no target apenas quando o utilizador toca no botão de nota e a mira está dentro da área do target reconhecido; a posição do post-it MUST ser o ponto correspondente à mira no target
- **FR-004**: O objeto 3D post-it MUST ficar ancorado ao target de forma que, ao rotacionar o target ou mover o dispositivo, o post-it permaneça no mesmo ponto relativo ao target
- **FR-005**: O post-it 3D MUST ser clicável; ao toque MUST abrir um balão (ou modal) de anotação com campo de texto e botão OK
- **FR-006**: Ao tocar OK no balão, o sistema MUST guardar o texto da anotação, fechar o balão e voltar à vista de RA
- **FR-007**: Ao tocar novamente num post-it que já tem anotação, o sistema MUST abrir o balão com o conteúdo anterior e permitir editar e guardar com OK
- **FR-008**: O sistema MUST persistir, em base de dados local no dispositivo, por cada post-it: a anotação (texto), a posição do objeto no target, e a associação à página/livro
- **FR-009**: Quando o utilizador aceder novamente à mesma página em RA e o target for reconhecido, o sistema MUST restaurar e exibir os post-its nas posições guardadas, com as anotações disponíveis (visíveis ou ao toque)
- **FR-010**: O sistema MUST impor um limite máximo de caracteres por anotação (ex.: 1000 caracteres) para evitar abusos

### Key Entities

- **Anotação (post-it)**: Representa um marcador espacial numa página. Atributos: texto da anotação, posição no target (coordenadas ou transformação que permita desenhar o objeto no sítio certo), referência à página/imagem e ao livro (scan). Permite múltiplas anotações por página.
- **Target reconhecido**: A região (área) do frame da câmera que corresponde à página escaneada; a "área do target" é usada para decidir se a mira está dentro e para ancorar a posição do post-it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: O utilizador consegue colocar um post-it no target em menos de 10 segundos após o target ser reconhecido (botão + mira visíveis, um toque no botão com mira sobre o target)
- **SC-002**: As anotações e posições dos post-its persistem após fechar a app; ao reabrir a mesma página em RA no mesmo dispositivo, 100% dos post-its guardados reaparecem nas posições correctas
- **SC-003**: O utilizador consegue editar uma anotação existente (tocar no post-it, alterar texto, OK) e a alteração fica guardada e visível na próxima abertura
- **SC-004**: O post-it permanece visualmente estável e ancorado ao target quando o utilizador move o dispositivo ou roda a página (sem deriva visível em condições de uso normais)

## Assumptions

- A tela de RA actual (reconhecimento de target via OpenCV e overlay) permanece; esta feature acrescenta o botão, a mira, o objeto 3D post-it e a persistência de anotações
- "Posição no target" pode ser representada de forma que permita restauro (ex.: coordenadas normalizadas no quadrilátero do target ou matriz de transformação); a decisão técnica fica para o plano
- O aspecto visual do post-it 3D (cor, tamanho, forma) pode ser definido no desenho de UI; assume-se um formato tipo post-it reconhecível
- Plataforma: Android e iOS (consistente com a tela de RA existente); Windows fora do âmbito
- Não é obrigatório suportar eliminação de um post-it nesta feature; pode ser escopo futuro
- As anotações são persistidas apenas localmente neste dispositivo; não há sincronização em nuvem ou entre dispositivos nesta feature
