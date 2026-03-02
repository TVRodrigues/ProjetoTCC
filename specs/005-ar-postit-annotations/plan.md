# Implementation Plan: Post-it e anotações ancoradas na tela de RA

**Branch**: `005-ar-postit-annotations` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `specs/005-ar-postit-annotations/spec.md`

## Summary

Adicionar, sobre a tela de RA já baseada em OpenCV (feature 004), um fluxo completo de **anotações espaciais**:

- Botão redondo com ícone de nota na parte inferior da tela de RA.  
- Mira vermelha translúcida fixa no centro da tela.  
- Quando a mira está **dentro do target rastreado** e o utilizador toca no botão, é criado um **post-it ancorado ao target** na posição correspondente à mira.  
- O post-it é clicável; abre um balão de anotação (texto + OK) com persistência local (SQLite).  
- Ao reabrir a mesma página em RA no mesmo dispositivo, os post-its e textos reaparecem ancorados nas posições correctas.

Esta feature **não** altera o pipeline de targets (features 001/003) nem a detecção OpenCV (feature 004); apenas consome estes serviços.

## Technical Context

- **Linguagem/Framework**: Dart ^3.11.0, Flutter (projetotcc/).  
- **RA base**: `TelaAR` + `ArOpencvService` (feature 004) ― reconhecimento de página via ORB + homografia.  
- **Persistência**: `sqflite` via `ScanDatabase` (`scan_database.dart`) e modelos `Scan` / `ImagemPage`.  
- **Plataformas alvo**: Android e iOS (RA); Windows continua sem RA (já tratado em `TelaAR`).  
- **UI**: Tema escuro (`#121212` / `#1E1E1E`), alinhado ao app.

### Dependências Relevantes

- `projetotcc/lib/tela_ar.dart`: visualizador RA com camera preview, overlay do target (polígono verde), hit test básico no toque (placeholder atual: SnackBar).  
- `projetotcc/lib/services/ar_opencv_service.dart`: carrega targets, extrai ORB, faz matching e devolve `ArMatchResult` com `corners` (cantos do target no frame).  
- `projetotcc/lib/services/scan_database.dart`: acesso a SQLite (tabelas `scans`, `imagens`, etc.).

### Princípios de Design

- Reusar ao máximo o **polígono do target** (homografia) para:
  - Determinar se a mira (ponto central da tela) está “dentro do target”.  
  - Converter um ponto no espaço da câmera para **coordenadas normalizadas no target** para persistência.  
- Manter a lógica de anotações **local à `TelaAR`** (UI + projeção) e **persistência no `ScanDatabase`** (modelo/DAO).
- Representar a posição de cada post-it como **(u, v)** normalizados em relação ao target (0–1 em largura/altura da imagem base), permitindo recomputar a posição de tela em cada frame a partir da homografia.

## Constitution Check (Project Guidelines Alignment)

- **Documentação**: Qualquer alteração em modelos de dados (`ScanDatabase`) MUST ser refletida em `docs/ARQUITETURA.md` (secção de modelo de dados).  
- **Separação Apresentação/Serviços**: `TelaAR` continua como camada de apresentação; `ArOpencvService` continua responsável apenas por reconhecimento/homografia. Funções auxiliares de projeção podem morar em `TelaAR` ou num helper estático, mas sem dependências de UI nos serviços.  
- **Persistência Local**: Anotações são guardadas **apenas localmente** (sem sync); isto deve constar em Assumptions (já no spec) e em ARQUITETURA.  
- **Simplicidade**: Sem plane detection nem múltiplas âncoras 3D genéricas; apenas post-its 2D “pseudo-3D” ancorados à página rastreada.

## Project Structure

### Documentation (this feature)

```text
specs/005-ar-postit-annotations/
├── spec.md               # O quê / porquê (já feito)
├── plan.md               # Este ficheiro
├── quickstart.md         # (opcional) Guia rápido de validação manual
├── data-model.md         # (opcional) Detalhes do modelo de dados das anotações
└── tasks.md              # Lista de tasks implementáveis
```

### Source Code (relevante)

```text
projetotcc/
├── lib/
│   ├── tela_ar.dart                 # Tela de RA; será extendida com mira, botão e post-its
│   ├── models/
│   │   ├── scan.dart
│   │   ├── imagem_page.dart
│   │   └── anotacao_postit.dart     # (novo) Modelo de anotação/post-it (opção 1)
│   └── services/
│       ├── scan_database.dart       # Extensão do schema/tabelas para anotações (ou colunas novas)
│       ├── ar_opencv_service.dart   # Pode ganhar helper de projeção ponto<->target, se necessário
│       └── ...                      # Demais serviços existentes
```

*(Se o modelo de anotação for embutido em `ImagemPage`, o ficheiro `anotacao_postit.dart` pode não ser necessário; o plano considera o modelo próprio como opção preferida para clareza.)*

## Data Model & Persistence Design

### Entidade `AnotacaoPostit`

Nova entidade lógica para representar cada post-it ancorado:

- `id` (PK, inteiro)  
- `scanId` (FK → livro/scan)  
- `imagemId` (FK → imagem/página específica)  
- `u` (double) — coordenada normalizada horizontal no target (0–1)  
- `v` (double) — coordenada normalizada vertical no target (0–1)  
- `texto` (string) — conteúdo da anotação (até ~1000 caracteres)  
- `createdAt`, `updatedAt` (timestamps simples)

### Estrutura de Base de Dados (SQLite)

Opção preferida:

- **Nova tabela** `anotacoes_postit` em `ScanDatabase`, com os campos acima.  
- Índice por `(scanId, imagemId)` para carregamento rápido das anotações de uma página.

### Projeção de Coordenadas

- Para **criar** um post-it:
  - Usar o centro da tela (mira).  
  - Verificar se está dentro do polígono `corners` do `ArMatchResult` (método `_isPointInsidePolygon`).  
  - Calcular a transformação inversa da homografia (ou equivalente) para passar do espaço da câmera para o espaço do target (imagem base).  
  - Converter `(xTarget, yTarget)` em `(u, v)` normalizados com base em `width`/`height` do target (já disponíveis em `_TargetData`).  
  - Persistir `(u, v)` na base de dados.

- Para **renderizar** post-its:
  - Reaplicar a homografia corrente para cada `(u, v)` da página rastreada, obtendo `(xScene, yScene)` no frame.  
  - Converter para coordenadas de tela usando mesma lógica de escala/offset já usada em `_OverlayPainter`.  
  - Desenhar um pequeno quadrilátero/ícone tipo post-it na posição resultante.

## Phases & Milestones

### Phase 1: Data Model & Database (Blocking)

**Objetivo**: Introduzir o modelo de anotação e persistência local sem quebrar o app.

- Definir classe `AnotacaoPostit` no diretório `models/` (ou equivalente).  
- Estender `ScanDatabase` com:
  - Criação da tabela `anotacoes_postit` (migration nova versão).  
  - Métodos CRUD:
    - `Future<List<AnotacaoPostit>> getAnotacoesForImagem(String scanId, int imagemId)`  
    - `Future<int> insertAnotacao(AnotacaoPostit a)`  
    - `Future<void> updateAnotacao(AnotacaoPostit a)`  
- Garantir que a migration é idempotente e compatível com dados existentes.

**Checkpoint**: App abre sem erros; migrations aplicadas; possível inserir e ler anotações via código de teste simples.

### Phase 2: RA Overlay & Placement (User Story 1)

**Objetivo**: Interação visual básica ― mira central + botão de nota + criação de post-it ancorado em memória (sem texto ainda).

- Adicionar **mira vermelha translúcida** fixa ao centro da tela em `TelaAR`:
  - Usar `Stack` sobre o `CameraPreview` com um widget circular/semi-transparente.  
- Adicionar **botão redondo com ícone de nota** na parte inferior:
  - Idealmente `FloatingActionButton` customizado ou `ElevatedButton` circular posicionado em `Stack`.  
  - Disponível apenas quando há `scanId` válido e RA ativa.  
- Implementar **hit test da mira no target**:
  - Novo método em `TelaAR`: `_isPointInsideTargetPolygon(Offset p, List<Offset> corners)`.  
  - Avaliar o centro da tela (coordenadas do layout) contra o polígono transformado; reutilizar lógica/escala de `_OverlayPainter`.  
- Implementar **criação de post-it (posição apenas)**:
  - No `onPressed` do botão de nota, se `_matchAtual != null` e mira estiver dentro do polígono:
    - Calcular `(u, v)` a partir da homografia atual (helper em `ArOpencvService` ou função local).  
    - Adicionar um `AnotacaoPostit` em memória (sem texto) associado ao `scanId`/`imagemId`.  
    - Persistir na BD com texto vazio (`''`).
  - Se mira estiver fora do target ou sem match:
    - Mostrar SnackBar “Aponte para a página para colocar uma anotação”.

**Checkpoint**: Com RA funcional, ao apontar para página verde e tocar no botão com mira dentro, pelo menos um marcador (post-it vazio) aparece na posição e é persistido.

### Phase 3: Annotation Dialog & Editing (User Story 2)

**Objetivo**: Tornar o post-it clicável, com balão de anotação, escrita/edição de texto e persistência.

- Representar visualmente cada post-it:
  - Com base nas coordenadas projetadas (Phase 2), desenhar um pequeno quadrilátero amarelo ou widget com sombra.  
  - Podem ser desenhados via novo `CustomPainter` ou widgets posicionados em `Stack` com `Positioned`.  
- Implementar **seleção de post-it ao toque**:
  - No `onTapDown` da `GestureDetector`, em vez de apenas SnackBar:
    - Verificar a distância entre o ponto de toque e cada post-it projetado; escolher o mais próximo sob um limiar (por ex. 40 px).  
    - Se encontrar post-it: abrir balão/modal para edição.  
    - Se não encontrar: (opcional) manter comportamento atual ou nenhum.
+- Implementar **balão/modal de anotação**:
  - `showDialog` ou `showModalBottomSheet` com:
    - `TextField` multi-linha.  
    - Contador/limite de caracteres (1000).  
    - Botões “Cancelar” e “OK”.  
  - No “OK”:
    - Atualizar `texto` do `AnotacaoPostit` em memória.  
    - Persistir via `updateAnotacao`.  
- Reabrir balão com texto existente:
  - Ao tocar num post-it com texto, o campo já vem preenchido; alterações são guardadas no “OK”.

**Checkpoint**: Utilizador consegue colocar post-it, abrir balão, escrever, guardar e reabrir para editar (texto persiste).

### Phase 4: Restore & Edge Cases (User Story 3)

**Objetivo**: Anotações reaparecem ao reabrir a página; comportamentos de borda consistentes.

- Carregamento inicial:
  - Em `_inicializar`/`_verificarTargets`, após garantir que há targets, carregar `AnotacaoPostit` para o `scanId` e `imagemId` correntes.  
  - Manter lista em estado (`_anotacoes`), filtrada por página.  
- Renderização estável:
  - Garantir que o cálculo da posição de tela a partir de `(u, v)` funciona de forma consistente quando o target é rastreado (outra sessão, ângulos diferentes).  
  - Se não há match (`_matchAtual == null`), esconder post-its (ou não desenhar).  
- Edge cases:
  - Vários post-its na mesma página: todos devem ser desenhados e clicáveis.  
  - Limite de texto: bloquear entrada após 1000 caracteres.  
  - Se a imagem/página for “rescan” e o identificador mudar:
    - Manter comportamento definido em spec (continuar associados por imagem/página, ou ficar órfãs/internas ao slot); para esta versão, seguir a política decidida na migration/ScanDatabase.

**Checkpoint**: Após fechar e reabrir app e RA, todos os post-its e textos voltam e se comportam conforme user stories.

### Phase 5: Polish & Documentation

- Atualizar `docs/ARQUITETURA.md`:
  - Adicionar referência a `AnotacaoPostit` e à tabela `anotacoes_postit`.  
  - Descrever, de forma sucinta, como as anotações são ancoradas à página (coordenadas normalizadas).  
- Adicionar/atualizar `specs/005-ar-postit-annotations/quickstart.md` com:
  - Passos para validar a feature manualmente (cenários principais e edge cases).  
- Executar `flutter analyze` e correções triviais.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|----------|-----------|----------------------------------------|
| Uso de homografia inversa para coordenadas (math não trivial) | Necessário para que o post-it fique realmente ancorado na página física, independentemente do ângulo de câmera | Usar coordenadas de tela diretamente faria o post-it “derrapar” ao mover a câmera, quebrando a experiência de RA |

## Implementation Strategy

### Ordem Recomendada (High Level)

1. **Phase 1**: Data model e migrations em `ScanDatabase` + modelo `AnotacaoPostit`.  
2. **Phase 2**: Mira central + botão de nota + criação de post-it (posição, sem texto).  
3. **Phase 3**: Visualização dos post-its, seleção por toque e balão de anotação com persistência de texto.  
4. **Phase 4**: Restore completo das anotações ao reabrir a tela de RA; validação de edge cases.  
5. **Phase 5**: Documentação e lint.

### Iteração MVP

- **MVP mínimo** (para demo inicial):
  - Mira central + botão de nota.  
  - Criação de um único post-it por página, sem edição, apenas com texto simples.  
  - Persistência local e restauro básico.  
- Depois do MVP, expandir para:
  - Múltiplos post-its por página.  
  - Edição completa (balão reabrível).  
  - UX refinada (estilo do post-it, animações).

