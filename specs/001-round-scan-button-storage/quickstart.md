# Quickstart: Botão Escanear Redondo + Persistência

**Feature**: 001-round-scan-button-storage  
**Branch**: `001-round-scan-button-storage`

## Pré-requisitos

- Flutter SDK (Dart ^3.11.0)
- Android Studio / Xcode (para emulador ou dispositivo)
- Dispositivo físico recomendado (câmera, storage)

## Dependências a Adicionar

No `projetotcc/pubspec.yaml`:

```yaml
dependencies:
  path_provider: ^2.1.1
  sqflite: ^2.3.0
  # permission_handler já existe
```

Depois: `flutter pub get`

## Estrutura de Ficheiros a Criar

```
projetotcc/lib/
├── models/
│   └── scan.dart
├── services/
│   ├── scan_storage_service.dart
│   └── scan_database.dart
```

## Alterações nos Ficheiros Existentes

### tela_principal.dart

- Remover `ElevatedButton.icon` "1. Escanear Nova Página"
- Adicionar `FloatingActionButton` (ou `FloatingActionButton.extended` com ícone livro+)
- Posicionar no centro inferior: `Scaffold.floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat`
- Ícone: `Icons.menu_book` + `Icons.add` (Stack) ou `Icons.add_circle` sobre livro
- `onPressed`: `Navigator.push` para `TelaGaleria`

### main.dart (TelaGaleria)

- Botão "Gerar Targets de RA": desativado quando `_paginasEscaneadas.isEmpty`
- Ao tocar (quando há páginas): abrir `showDialog` com formulário (título, autor, resumo)
- Validação: título obrigatório; bloquear "Salvar" se vazio
- Ao confirmar: chamar `ScanStorageService().saveScan(...)`
- Após sucesso: `Navigator.pop(context)` (fecha TelaGaleria) + `ScaffoldMessenger.showSnackBar` "Scan guardado com sucesso"
- Tratar exceções: permissão negada, espaço insuficiente → mensagem ao utilizador

## Como Testar

1. **Botão redondo**: Executar app, verificar que FAB aparece no centro inferior com ícone livro+
2. **Navegação**: Tocar no FAB → TelaGaleria abre
3. **Botão desativado**: Na TelaGaleria sem páginas, "Gerar Targets de RA" deve estar cinzento
4. **Popup**: Escanear 1 página, tocar "Gerar Targets de RA" → popup com título, autor, resumo
5. **Validação**: Tentar salvar sem título → botão Salvar desativado ou mensagem de erro
6. **Persistência**: Preencher título, salvar → redireciona para tela principal, SnackBar "Scan guardado"
7. **Verificar persistência**: Fechar app, reabrir — (nota: UI para listar scans não está nesta feature; validar via logs ou inspeção de DB/storage)

## Comandos

```bash
cd projetotcc
flutter pub get
flutter run
```

## Permissões Android

Em `android/app/src/main/AndroidManifest.xml`, verificar:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<!-- Para Android <10, se necessário: -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
```

Em Android 10+, `getApplicationDocumentsDirectory()` não requer WRITE_EXTERNAL_STORAGE.
