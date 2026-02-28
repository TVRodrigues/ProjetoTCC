# Quickstart: Feature 002 - Lista Meus Livros

**Branch**: `002-list-meus-livros`

## Pré-requisitos

- Flutter SDK (Dart ^3.11.0)
- Projeto na raiz `projetotcc/`
- Feature 001 implementada (ScanStorageService, ScanDatabase, modelo Scan)

## Dependência Nova

Adicionar ao `pubspec.yaml`:

```yaml
dependencies:
  shimmer: ^3.0.0
```

Justificação: Skeleton loader animado (shimmer) para as 3 fases de carregamento. Documentar em `docs/ARQUITETURA.md`.

## Ordem de Implementação Sugerida

1. **ScanDatabase**: Adicionar `getScansCount()`, `getScans()`, `deleteScan(id)`
2. **ScanStorageService**: Adicionar `getScansCount()`, `loadScans()`, `deleteScan(id)`
3. **TelaAR**: Adicionar parâmetro opcional `String? scanId`; se presente, carregar imagens desse scan (ou manter comportamento atual se null)
4. **TelaPrincipal**: Refatorar para lista "Meus Livros":
   - Header "Meus Livros"
   - Body: lista scrollável ou mensagem vazia
   - Carregamento em 3 fases (count → skeleton → detalhes)
   - Pull-to-refresh (RefreshIndicator)
   - FAB mantido; ao voltar da TelaGaleria com sucesso, refresh
   - Clique em item → Navigator.push(TelaAR(scanId: scan.id))
5. **TelaGaleria**: Alterar `Navigator.pop()` para `Navigator.pop(context, true)` quando salvar com sucesso
6. **Tratamento FR-009**: Ao abrir TelaAR com scanId, verificar se imagePaths existem; se não, toast + deleteScan + Navigator.pop

## Comandos Úteis

```bash
cd projetotcc
flutter pub get
flutter run
```

## Validação Rápida

1. Abrir app → ver header "Meus Livros" e skeleton/lista vazia
2. Escanear e guardar um livro → voltar → lista atualizada com o livro
3. Tocar no livro → TelaAR abre
4. Pull-to-refresh → lista recarrega
5. (Opcional) Apagar manualmente pasta de um scan → tocar no livro → toast + livro removido da lista
