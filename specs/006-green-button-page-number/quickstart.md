# Quickstart: Número da página no indicador verde

**Feature**: 006-green-button-page-number  
**Branch**: `006-green-button-page-number`

## Pré-requisitos

- Flutter SDK (Dart ^3.11.0)
- App com pelo menos um livro/scan que tenha **pelo menos uma página em estado "sucesso"** (indicador verde)

## Objetivo

Validar que o indicador circular **verde** (estado "sucesso") na lista de páginas do livro exibe o **número da página** junto com o ícone (check), de forma visível e legível.

## Passos de validação manual

1. **Abrir o app** e navegar até a lista de livros (scans).
2. **Abrir um livro** que tenha pelo menos uma página já processada em estado "sucesso" (indicador verde).  
   - Se não houver nenhum: fazer um scan e aguardar o pipeline concluir pelo menos uma página em "sucesso".
3. **Na lista de páginas** (TelaListaPaginas):
   - Localizar as linhas cujo indicador à direita está **verde** (sucesso).
   - **Verificar**: o indicador verde mostra o **ícone de check** e, **por baixo**, o **número da página** (ex.: 1, 2, 3).
   - Confirmar que o número exibido corresponde à página da respetiva linha (ex.: linha "Página 2" deve mostrar "2" no indicador verde).
4. **Outros estados**: confirmar que os indicadores **amarelo** (processando), **vermelho** (falha), **roxo** (rescan) e **cinzento** (não-página) continuam apenas com ícone, sem número.
5. **Edge case (opcional)**: se houver uma página com número alto (ex.: 10 ou 100), verificar que o número cabe no círculo sem cortar (pode estar em fonte menor ou escalado).

## Critérios de sucesso (SC-001, SC-002)

- **SC-001**: O utilizador identifica, em menos de 3 segundos, qual o número da página pronta para RA ao olhar para o indicador verde.
- **SC-002**: Em todas as páginas em estado "sucesso", o número no indicador verde corresponde à página correta (sem trocas entre linhas).

## Resumo

| Verificação                         | Esperado                          |
|-------------------------------------|-----------------------------------|
| Indicador verde                     | Ícone check + número da página    |
| Número correto por linha            | Sim                               |
| Outros estados (amarelo/vermelho/…) | Apenas ícone, sem número          |
| Layout estável (sem overflow)       | Número visível dentro do círculo  |
