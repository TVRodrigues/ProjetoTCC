# Tasks: Post-it e anotações ancoradas na tela de RA

**Input**: Design documents from `specs/005-ar-postit-annotations/`  
**Prerequisites**: spec.md, plan.md, (opcionais: data-model.md, quickstart.md)

**Tests**: Não obrigatórios pela spec; recomendados testes manuais guiados por quickstart.

**Organization**: Tasks agrupadas por fase e user story para implementação e validação independente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode correr em paralelo (ficheiros diferentes, sem dependências diretas).  
- **[Story]**: User story (US1, US2, US3).  
- Paths relativos a `projetotcc/` (raiz Flutter).

---

## Phase 1: Data Model & Database (Blocking)

**Purpose**: Introduzir o modelo de anotação/post-it e persistência local sem quebrar o app.

- [ ] T001 [US3] Criar modelo `AnotacaoPostit` em `lib/models/anotacao_postit.dart` com campos: `id`, `scanId`, `imagemId`, `u`, `v`, `texto`, `createdAt`, `updatedAt`.
- [ ] T002 [US3] Estender `lib/services/scan_database.dart` para adicionar tabela `anotacoes_postit` (migration nova versão): colunas conforme modelo, índices por `(scanId, imagemId)`.
- [ ] T003 [P][US3] Implementar em `scan_database.dart` os métodos: `getAnotacoesForImagem(String scanId, int imagemId)`, `insertAnotacao(AnotacaoPostit a)`, `updateAnotacao(AnotacaoPostit a)`.

**Checkpoint**: App inicia sem erros de migration; é possível inserir e ler anotações via código de teste (ex.: função temporária ou debug).

---

## Phase 2: RA Overlay & Placement (User Story 1 - P1)

**Purpose**: Adicionar mira central, botão de nota e criação de post-it ancorado (posição apenas).

- [ ] T004 [US1] Em `lib/tela_ar.dart`: adicionar mira vermelha translúcida fixa no centro da tela (widget circular/semi-transparente em `Stack` sobre `CameraPreview`).
- [ ] T005 [US1] Em `lib/tela_ar.dart`: adicionar botão redondo com ícone de nota na parte inferior (por ex. `FloatingActionButton` centralizado horizontalmente), respeitando o tema escuro.
- [ ] T006 [US1] Em `lib/tela_ar.dart`: implementar método `_isPointInsideTargetPolygon(Offset p, List<Offset> corners)` reutilizando a mesma escala/offset de `_OverlayPainter` para verificar se o centro da tela (mira) está dentro do polígono do target atual.
- [ ] T007 [US1] Em `lib/tela_ar.dart`: no `onPressed` do botão de nota, se `_matchAtual != null` e a mira estiver dentro do target, calcular a posição correspondente no target (coordenadas normalizadas `u`, `v`) a partir da homografia atual (utilizando helper em `ArOpencvService` ou lógica local) e criar um objeto `AnotacaoPostit` em memória (texto vazio).
- [ ] T008 [US1] Em `lib/tela_ar.dart`: persistir a nova anotação criada em `ScanDatabase.insertAnotacao` e manter uma lista `_anotacoes` no estado da tela; se a mira estiver fora ou sem target, mostrar SnackBar “Aponte para a página para colocar uma anotação”.

**Checkpoint**: Ao apontar para uma página verde e tocar no botão de nota com a mira dentro do target, pelo menos um post-it (sem texto) é criado, persistido e a posição é lembrada.

---

## Phase 3: Annotation Dialog & Editing (User Story 2 - P2)

**Purpose**: Tornar os post-its clicáveis, com balão de anotação para escrever/editar texto e persistência.

- [ ] T009 [US2] Em `lib/tela_ar.dart`: projetar, para cada `AnotacaoPostit` em `_anotacoes`, a posição de tela atual com base em `(u, v)` e na homografia/cantos do target, usando a mesma transformação de `_OverlayPainter`.
- [ ] T010 [US2] Em `lib/tela_ar.dart`: desenhar visualmente cada post-it projetado (por ex. quadrilátero amarelo com sombra) sobre o `CameraPreview` (via `CustomPainter` ou widgets em `Stack`).
- [ ] T011 [US2] Em `lib/tela_ar.dart`: atualizar `_aoTocarNaTela(TapDownDetails details)` para, em vez de apenas mostrar SnackBar, identificar se o toque está próximo de algum post-it projetado (distância em px abaixo de um limiar) e selecionar o post-it correspondente.
- [ ] T012 [US2] Em `lib/tela_ar.dart`: ao selecionar um post-it, abrir `showDialog` ou `showModalBottomSheet` com `TextField` multi-linha, limite de 1000 caracteres e botões “Cancelar” e “OK”.
- [ ] T013 [US2] Em `lib/tela_ar.dart`: ao confirmar em “OK”, atualizar o `texto` do `AnotacaoPostit` selecionado em memória e chamar `ScanDatabase.updateAnotacao`; ao reabrir o post-it, o texto previamente guardado deve aparecer preenchido para edição.

**Checkpoint**: Utilizador consegue colocar um post-it, abrir balão de anotação, escrever texto, guardar e reabrir para editar; texto persiste entre sessões.

---

## Phase 4: Restore & Edge Cases (User Story 3 - P3)

**Purpose**: Garantir que anotações reaparecem ao reabrir a página e tratar casos de borda.

- [ ] T014 [US3] Em `lib/tela_ar.dart`: após `_verificarTargets` e antes de iniciar a câmera, carregar de `ScanDatabase.getAnotacoesForImagem` todas as anotações para o `scanId` e `imagemId` correntes, populando `_anotacoes`.
- [ ] T015 [US3] Em `lib/tela_ar.dart`: garantir que post-its são apenas desenhados quando `_matchAtual != null` (target rastreado); quando o target é perdido, esconder post-its até novo rastreio.
- [ ] T016 [US3] Em `lib/tela_ar.dart`: suportar múltiplos post-its na mesma página, assegurando que todos são desenhados e clicáveis (seleção por proximidade ao toque).
- [ ] T017 [US3] Em `lib/tela_ar.dart`: aplicar rigorosamente o limite de 1000 caracteres na UI (bloquear input adicional ou avisar o utilizador).

**Checkpoint**: Após fechar a app e reabrir, bem como ao voltar à tela de RA, todas as anotações previamente criadas reaparecem nas posições corretas; múltiplos post-its funcionam sem conflitos.

---

## Phase 5: Polish & Documentation

**Purpose**: Atualizar documentação e garantir qualidade básica.

- [ ] T018 [P] Atualizar `docs/ARQUITETURA.md` com a nova entidade `AnotacaoPostit`, tabela `anotacoes_postit` e breve explicação de como as coordenadas normalizadas `(u, v)` são usadas para ancorar post-its ao target.
- [ ] T019 [P] Criar ou atualizar `specs/005-ar-postit-annotations/quickstart.md` com passos de validação manual dos principais cenários (US1–US3 + edge cases).
- [ ] T020 Executar `flutter analyze` em `projetotcc/` e corrigir avisos diretamente ligados às alterações desta feature.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Data Model & DB)**: Sem dependências; BLOQUEIA as demais fases.  
- **Phase 2 (RA Overlay & Placement)**: Depende de Phase 1 (persistência pronta).  
- **Phase 3 (Annotation Dialog & Editing)**: Depende de Phase 2 (post-its já posicionados).  
- **Phase 4 (Restore & Edge Cases)**: Depende de Phase 1 (BD) e Phase 2 (posição) para restaurar corretamente.  
- **Phase 5 (Polish & Documentation)**: Depende das anteriores.

### Within Each Phase

- **Phase 1**:  
  - T001 → T002 → T003 (T003 pode ser iniciado em paralelo com validação de T002).

- **Phase 2**:  
  - T004 → T005 → T006 → T007 → T008 (ordem lógica de UI → lógica → persistência).

- **Phase 3**:  
  - T009 → T010 → T011 → T012 → T013.

- **Phase 4**:  
  - T014 → T015 → T016 → T017 (podem ser ligeiramente intercaladas durante testes).

- **Phase 5**:  
  - T018, T019 e T020 podem ser feitas em paralelo após as fases anteriores.

### Parallel Opportunities

- T003 em paralelo com validação manual das migrations (após T002).  
- T018 e T019 em paralelo com T020 (após funcionalidade estabilizada).

---

## Summary

| Métrica            | Valor |
|--------------------|-------|
| **Total tasks**    | 20    |
| **US1 (P1)**       | 5     |
| **US2 (P2)**       | 5     |
| **US3 (P3)**       | 7     |
| **Setup/Polish**   | 3     |
| **Parallelizable** | T003, T018, T019 |
| **MVP scope**      | Fases 1–2 (T001–T008) |

