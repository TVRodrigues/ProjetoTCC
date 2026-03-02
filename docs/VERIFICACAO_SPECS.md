# Verificação dos specs na versão atual do código

**Data**: Após unificação de branches  
**Specs**: 001, 002, 003, 004

---

## Spec 001 – Botão Escanear Redondo + Persistência de Scans

| Requisito | Estado | Notas |
|-----------|--------|-------|
| Botão redondo centro inferior, ícone livro + | OK | `tela_principal.dart`: FAB com `menu_book` + `add_circle`, `FloatingActionButtonLocation.centerFloat` |
| Toque abre TelaGaleria | OK | `Navigator.push` → `TelaGaleria()` |
| Persistência em diretório privado | OK | `ScanStorageService` usa `getApplicationDocumentsDirectory()` + `/scans/` |
| Metadados em BD (título, autor, resumo, caminhos) | OK | `ScanDatabase`: tabelas `scans` e `imagens` com migration v2 |
| Popup "Guardar Scan" com título obrigatório | OK | `main.dart`: `_mostrarFormularioSalvar()`, `TextFormField` com validator |
| Botão "Gerar Targets de RA" desativado sem páginas | OK | `bottomNavigationBar` só quando `!_paginasEscaneadas.isEmpty`; botão com `onPressed: _paginasEscaneadas.isEmpty ? null : _salvarTargets` |
| Redirecionamento após salvar + SnackBar | OK | `Navigator.pop(ctx); navigator.pop(true); messenger.showSnackBar('Scan guardado com sucesso')` |
| Tratamento falhas (permissão, espaço) | OK | `StoragePermissionDeniedException`, `StorageFullException`, `ValidationException` com mensagens |

**Conclusão 001**: Implementado.

---

## Spec 002 – Lista Meus Livros

| Requisito | Estado | Notas |
|-----------|--------|-------|
| Header "Meus Livros" | OK | `tela_principal.dart`: `AppBar(title: Text('Meus Livros'))` |
| Lista de livros (títulos) scrollável | OK | `ListView.builder` com `_scans`, `_BookListItem` com `scan.titulo` |
| Lista vazia: mensagem explícita | OK | `'Nenhum livro guardado. Toque no botão + para escanear.'` |
| Skeleton loader (3 fases: count → skeleton → detalhes) | OK | `_LoadingPhase.count/skeleton/details/loaded`, `_SkeletonItem` com Shimmer |
| Pull-to-refresh | OK | `RefreshIndicator(onRefresh: _carregarLista, child: _buildBody())` |
| Toque no livro abre lista de páginas | OK | `_abrirLivro(scan)` → `TelaListaPaginas(scan: scan)` (fluxo 003) |
| FAB centro inferior (livro+) | OK | Mesmo FAB que 001 |
| Atualizar lista ao voltar da Galeria | OK | `if (result == true && mounted) _carregarLista()` |
| Livro com imagens removidas: toast + remover da lista | OK | Em `_abrirLivro`: verifica `File(p).exists()` para cada path; se faltar alguma, `deleteScan`, SnackBar e `_carregarLista()`. |

**Conclusão 002**: Implementado (incluída correção em `_abrirLivro`).

---

## Spec 003 – Pipeline de Targets AR

| Requisito | Estado | Notas |
|-----------|--------|-------|
| Após salvar: processar targets em background | OK | `TargetPipelineService().processScan(scan.id)` após save |
| Lista de páginas com indicadores verde/amarelo/vermelho/roxo/cinzento | OK | `tela_lista_paginas.dart`: `_corParaEstado`, ícones por estado |
| Toque no livro → lista de páginas | OK | `TelaListaPaginas(scan)` |
| Toque página verde → TelaAR | OK | `TelaAR(scanId, imagemId)` |
| Vermelho: retry (amarelo → falha → roxo) | OK | `_aoTocarPagina` falha → `_pipeline.retryImage`; pipeline em falha → `estado_target: 'rescan'` |
| Roxo: rescan (TelaRescan, substituir imagem) | OK | `TelaRescan` + `replaceImageForRescan` |
| Análise de imagem (numero_pagina, eh_pagina, capa) | OK | `ImageAnalysisService`, `ScanDatabase.updateImagemMetadata` |
| BD com estado_target, eh_pagina, numero_pagina | OK | `ScanDatabase` v2, `ImagemPage` |

**Conclusão 003**: Implementado.

---

## Spec 004 – OpenCV AR (substituição Augen)

| Requisito | Estado | Notas |
|-----------|--------|-------|
| Augen removido | OK | Nenhuma referência a `augen` no projeto |
| RA com OpenCV (câmera + matching + overlay) | OK | `ArOpencvService`, `tela_ar.dart` com camera + `matchFrame` + overlay |
| Subconjunto de targets (página + adjacentes / N) | OK | `getTargetPathsForSession(scanId, imagemId)` |
| Zero targets → mensagem e voltar | OK | `paths.isEmpty` ou `targetCount == 0` → SnackBar + `Navigator.pop` |
| Dica 5 s sem reconhecimento | OK | Timer 5 s, "Aponte para uma página escaneada" |
| Hit test com página rastreada | OK | Toque só com `_matchAtual != null`; SnackBar "Anotação colada" |
| Permissão câmera / mensagem clara | OK | `_permissaoNegada` → texto + botão definições |
| Windows: RA não suportada | OK | `!Platform.isAndroid && !Platform.isIOS` → SnackBar + pop |
| Tema escuro (#1E1E1E, #121212) | OK | `tela_ar.dart` e tema global |

**Conclusão 004**: Implementado.

---

## Resumo

| Spec | Estado | Ação |
|------|--------|------|
| 001 | OK | — |
| 002 | OK | Correção aplicada: `_abrirLivro` verifica imagens e remove livro se faltarem. |
| 003 | OK | — |
| 004 | OK | — |

**Todos os specs estão implementados na versão atual do código.**
