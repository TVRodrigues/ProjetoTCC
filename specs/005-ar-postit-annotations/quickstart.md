# Quickstart: Post-it e anotações ancoradas na tela de RA

**Feature**: 005-ar-postit-annotations  
**Branch**: `005-ar-postit-annotations`

## Pré-requisitos

- Feature 004 (RA com OpenCV) implementada: tela de RA com reconhecimento de página e overlay.
- Entrar na tela de RA **por uma página verde** (tap na página na lista) para ter `imagemId` e poder criar/ver anotações.
- Android ou iOS (RA não disponível em Windows).

## Visão Geral

1. **Mira e botão**: Na tela de RA aparecem uma mira vermelha translúcida no centro e um botão redondo com ícone de nota na parte inferior.
2. **Colocar post-it**: Com a mira **dentro** da área do target (página reconhecida), tocar no botão de nota → um post-it é criado nessa posição e persistido (texto vazio inicialmente).
3. **Editar anotação**: Tocar num post-it (quadrado âmbar) → abre balão com campo de texto e OK; limite 1000 caracteres. Ao guardar, o texto fica persistido localmente.
4. **Restauro**: Ao sair e reabrir a mesma página em RA, os post-its e textos reaparecem nas posições corretas (persistência em SQLite, tabela `anotacoes_postit`).

## Estrutura de Ficheiros

```
projetotcc/lib/
├── tela_ar.dart              # Mira, botão de nota, overlay de post-its, balão de anotação
├── models/
│   └── anotacao_postit.dart  # Modelo (id, scanId, imagemId, u, v, texto, createdAt, updatedAt)
├── services/
│   └── scan_database.dart    # Tabela anotacoes_postit, getAnotacoesForImagem, insertAnotacao, updateAnotacao
└── ...
```

## Comandos

```bash
cd projetotcc
flutter pub get
flutter run
# Para RA: dispositivo/emulador Android ou iOS; abrir um livro → página verde → TelaAR
```

## Verificações Manuais

### User Story 1 – Colocar post-it no target

- [ ] Abrir RA por uma página verde; ver **mira vermelha** no centro e **botão redondo com ícone de nota** em baixo.
- [ ] Apontar para a página física até o target ser reconhecido (contorno verde).
- [ ] Com a mira sobre a página, tocar no **botão de nota** → um post-it (quadrado âmbar) aparece e permanece ancorado ao mover o telemóvel.
- [ ] Tocar no botão com a mira **fora** da página → mensagem “Aponte a mira para dentro da página para anotar.” (ou similar); nenhum post-it criado.

### User Story 2 – Escrever e editar anotação

- [ ] Tocar num post-it → abre **balão** com campo de texto e botões Cancelar / OK.
- [ ] Escrever texto e tocar OK → balão fecha; post-it continua visível.
- [ ] Tocar de novo no mesmo post-it → balão abre com o **texto anterior**; editar e OK → alteração guardada.
- [ ] Verificar **limite 1000 caracteres** (contador e bloqueio no campo).

### User Story 3 – Persistência e restauro

- [ ] Colocar um ou mais post-its com texto; sair da tela de RA (voltar à lista) ou fechar o app.
- [ ] Reabrir o mesmo livro e a **mesma página** (tap na página verde) → os post-its aparecem nas **posições corretas** com o texto acessível ao toque.
- [ ] Editar um post-it restaurado → guardar → sair e reabrir → alteração mantida.

### Edge cases

- [ ] Tocar no botão de nota **sem** target reconhecido → mensagem “Aponte para a página para colocar uma anotação.” (ou similar).
- [ ] Múltiplos post-its na mesma página: todos visíveis e clicáveis (seleção por proximidade ao toque).
- [ ] Anotações só disponíveis quando se entra pela **página verde** (com `imagemId`); entrar por outro fluxo sem imagem específica → mensagem adequada ao tocar no botão de nota.

## Notas

- As anotações são **apenas locais** (mesmo dispositivo); não há sincronização em nuvem.
- A posição de cada post-it é guardada em **(u, v)** normalizados (0–1) no quadrilátero do target; a projeção para o ecrã usa os cantos do target em cada frame (ancoragem estável).
