# Research: Feature 002 - Lista Meus Livros

**Branch**: `002-list-meus-livros` | **Date**: 2026-02-26

## 1. Skeleton Loader (Shimmer)

**Decision**: Usar o pacote `shimmer` (^3.0.0) para o efeito de skeleton loader animado.

**Rationale**: O pacote é amplamente utilizado (5.4k+ likes), mantido, e depende apenas do Flutter. Permite criar placeholders com shimmer (baseColor/highlightColor) compatíveis com o tema escuro (#121212). Alternativa: implementação custom com AnimationController — mais código e manutenção sem benefício claro.

**Alternatives considered**:
- `flutter_animated_skeleton`: Mais funcionalidades; adiciona mais complexidade; shimmer é suficiente para N placeholders de lista.
- Implementação custom: Evita dependência; aumenta código e risco de bugs.
- `shimmer_skeleton`, `skeleton_shimmer_loading`: Menos populares; shimmer é o padrão de facto.

**Uso**: `Shimmer.fromColors` com `baseColor` e `highlightColor` para tema escuro; wrappar containers retangulares que simulam o texto do título em cada item da lista.

---

## 2. Estratégia de Carregamento em 3 Fases

**Decision**: Implementar as 3 fases sequenciais: (1) count, (2) skeleton com N slots, (3) fetch detalhes.

**Rationale**: A spec exige explicitamente esta ordem. A query COUNT é rápida; permite mostrar imediatamente o número correto de placeholders; o fetch de detalhes pode ser uma única query `SELECT * FROM scans ORDER BY data_criacao DESC` — não precisa de N queries individuais.

**Alternatives considered**:
- Uma única query com todos os dados: Mais simples, mas não cumpre a spec (skeleton com N placeholders antes dos dados).
- Lazy loading por item: Complexidade desnecessária; para lista local com poucos itens, uma query é suficiente.

---

## 3. Navegação TelaPrincipal → TelaAR com scan_id

**Decision**: Passar `scan_id` como argumento da rota ao navegar para TelaAR: `Navigator.push(context, MaterialPageRoute(builder: (ctx) => TelaAR(scanId: scanId)))`.

**Rationale**: A spec exige que o clique redirecione para o Visualizador RA; a assunção diz que TelaAR recebe o identificador. Implementação mínima: adicionar parâmetro opcional `String? scanId` em TelaAR; se presente, carregar imagens desse scan (futuro); se ausente, comportamento atual (modelo fixo).

**Alternatives considered**:
- Estado global: Viola Constitution IV (Simplicity).
- Passar Scan completo: Funciona, mas scan_id é suficiente; TelaAR pode carregar dados se necessário.

---

## 4. Remoção de Scan (Imagens Faltando)

**Decision**: Ao detectar erro ao abrir TelaAR (imagens inexistentes), exibir toast e chamar `ScanDatabase.deleteScan(id)` e `ScanStorageService.deleteScan(id)` (ou equivalente) para remover da BD e da pasta de ficheiros; retornar à lista e atualizar a UI.

**Rationale**: FR-009 exige toast + remoção automática. O ScanStorageService precisa de um método `deleteScan(id)` que: (1) remove registos da tabela imagens e scans (CASCADE); (2) remove ficheiros da pasta do scan. O ScanDatabase precisa de `deleteScan(id)`.

**Alternatives considered**:
- Apenas remover da BD: Ficheiros órfãos permanecem; má prática.
- Remover apenas ficheiros: Dados inconsistentes na BD.

---

## 5. Refresh ao Voltar da TelaGaleria

**Decision**: Usar `Navigator.push(...).then((_) => _refrescarLista())` em TelaPrincipal; quando TelaGaleria faz `Navigator.pop()` após salvar, a Promise resolve e a lista é recarregada.

**Rationale**: FR-011 exige refresh automático. O fluxo atual é: TelaGaleria salva → Navigator.pop() → TelaPrincipal fica visível. O `.then()` garante que após qualquer pop (incluindo após salvar), a lista é recarregada. Alternativa: passar `resultado` no pop e só refrescar se `resultado == true`; evita refresh desnecessário quando o utilizador cancela. **Refinamento**: Usar `Navigator.pop(context, true)` quando salvar com sucesso; `_refrescarLista()` só quando `result == true`.

**Alternatives considered**:
- Stream/Event bus: Viola YAGNI.
- Callback passado: Navigator.pop retorna valor; suficiente.

---

## 6. Pull-to-Refresh

**Decision**: Usar `RefreshIndicator` do Flutter (Material) envolvendo a lista. Sem dependências adicionais.

**Rationale**: FR-012 exige pull-to-refresh. O `RefreshIndicator` é nativo do Flutter e suporta o gesto de puxar para baixo. O `onRefresh` deve chamar a mesma lógica de carregamento das 3 fases.

**Alternatives considered**:
- Pacote custom: Desnecessário; RefreshIndicator é suficiente.
