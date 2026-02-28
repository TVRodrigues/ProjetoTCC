# Arquitetura do Projeto - Marcador AR

## 1. Visão Geral

O **Marcador AR** (ProjetoTCC) é um aplicativo móvel multiplataforma desenvolvido em Flutter que permite escanear páginas de livros/documentos, processá-las e visualizar anotações em Realidade Aumentada (RA). O usuário aponta a câmera para uma página escaneada e pode adicionar modelos 3D interativos sobre o conteúdo.

---

## 2. Objetivo do Sistema

- **Escaneamento de documentos**: Captura de páginas de livros via câmera com recorte automático
- **Processamento de imagens**: Análise local (ML Kit) e geração de targets de RA via Augen Image Tracking
- **Visualização em RA**: Sobreposição de modelos 3D (anotações) sobre páginas físicas em tempo real

---

## 3. Stack Tecnológica

| Categoria | Tecnologia | Versão | Propósito |
|-----------|------------|--------|-----------|
| **Framework** | Flutter | SDK | Desenvolvimento multiplataforma |
| **Linguagem** | Dart | ^3.11.0 | Lógica de negócio e UI |
| **Escaneamento** | google_mlkit_document_scanner | ^0.4.1 | Captura e recorte de documentos |
| **OCR** | google_mlkit_text_recognition | ^0.15.1 | Reconhecimento de texto (disponível) |
| **RA** | augen | ^1.0.2 | Motor de Realidade Aumentada |
| **Câmera** | camera | ^0.11.4 | Acesso à câmera nativa |
| **Permissões** | permission_handler | ^11.4.0 | Gerenciamento de permissões |
| **HTTP** | http | ^1.6.0 | Comunicação com APIs (futuro) |
| **Storage** | path_provider | ^2.1.x | Diretório privado da app (imagens) |
| **Base de dados** | sqflite | ^2.3.x | SQLite local (metadados de scans) |
| **UI** | shimmer | ^3.0.0 | Skeleton loader animado (feature 002) |

### Plataformas Suportadas

- **Android**: minSdk 24, targetSdk 36, compileSdk 36
- **iOS**: Suportado (estrutura padrão Flutter)
- **Windows**: Suportado (estrutura padrão Flutter)

---

## 4. Arquitetura de Camadas

O projeto segue uma estrutura **monolítica em camada única** (tela única), com a lógica distribuída entre os arquivos principais. A separação é feita por **telas/features** em vez de camadas clássicas (apresentação, domínio, dados).

```
┌─────────────────────────────────────────────────────────────┐
│                    CAMADA DE APRESENTAÇÃO                    │
│  (Widgets Flutter - Telas, Estados, Navegação)               │
├─────────────────────────────────────────────────────────────┤
│  main.dart          │  TelaPrincipal  │  TelaGaleria  │  TelaAR  │
│  (App + Galeria)    │  (Hub Central)  │  (Scanner)    │  (RA)    │
│                     │  TelaListaPaginas │  TelaRescan  │         │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    CAMADA DE SERVIÇOS                        │
│  (Plugins nativos - ML Kit, Augen, Camera, Permissões)        │
└─────────────────────────────────────────────────────────────┘
```

### 4.1 Camada de Apresentação

| Componente | Arquivo | Responsabilidade |
|------------|---------|------------------|
| **MeuMarcadorApp** | main.dart | Configuração do MaterialApp, tema escuro, rota inicial |
| **TelaPrincipal** | tela_principal.dart | Hub central com lista de livros e navegação |
| **TelaListaPaginas** | tela_lista_paginas.dart | Lista de páginas do livro com indicadores (verde/amarelo/vermelho/roxo/cinzento) |
| **TelaGaleria** | main.dart | Scanner de documentos, galeria de páginas |
| **TelaRescan** | tela_rescan.dart | Scanner único para substituir página que falhou |
| **TelaAR** | tela_ar.dart | Visualizador de RA com Image Tracking, ancoragem de modelos 3D |

### 4.2 Camada de Serviços (Plugins e Serviços Locais)

- **Document Scanner**: Captura e recorte de páginas (JPEG, até 20 páginas)
- **Augen**: Sessão AR com Image Tracking, detecção de planos, estimativa de luz
- **TargetPipelineService** (feature 003): Processamento em background de imagens, análise ML Kit, atualização de estado por página
- **ImageAnalysisService** (feature 003): Análise de imagem (eh_pagina, numero_pagina, capa)
- **Permission Handler**: Solicitação de permissão de câmera e storage
- **Camera**: Acesso à câmera (usado indiretamente pelos plugins)
- **ScanStorageService** (feature 001): Persistência de imagens (path_provider) e metadados (sqflite)

---

## 5. Estrutura de Pastas

```
ProjetoTCC/
├── projetotcc/                    # Projeto Flutter principal
│   ├── lib/                        # Código-fonte Dart
│   │   ├── main.dart               # Entry point, App, TelaGaleria
│   │   ├── tela_principal.dart     # Hub Central (botão redondo FAB)
│   │   ├── tela_ar.dart            # Tela de Realidade Aumentada
│   │   ├── models/
│   │   │   ├── scan.dart           # Modelo Scan (título, autor, resumo, imagens)
│   │   │   └── imagem_page.dart    # Modelo ImagemPage (estado_target, numero_pagina)
│   │   └── services/
│   │       ├── scan_storage_service.dart   # Persistência de scans
│   │       ├── scan_database.dart          # SQLite, CRUD, migration v2
│   │       ├── target_pipeline_service.dart # Pipeline de targets AR
│   │       └── image_analysis_service.dart # Análise de imagem (ML Kit)
│   │
│   ├── android/                    # Configuração Android
│   │   ├── app/
│   │   │   ├── build.gradle.kts    # Build do app (namespace, SDKs)
│   │   │   └── src/
│   │   ├── build.gradle.kts        # Configuração Gradle raiz
│   │   └── settings.gradle.kts     # Plugins e módulos
│   │
│   ├── ios/                        # Configuração iOS
│   ├── windows/                    # Configuração Windows
│   │
│   ├── pubspec.yaml                # Dependências e metadados
│   ├── analysis_options.yaml       # Regras do linter (flutter_lints)
│   └── README.md
│
├── docs/                           # Documentação
│   └── ARQUITETURA.md              # Este documento
│
└── .vscode/                        # Configurações do editor
```

---

## 6. Fluxo de Navegação

```
                    ┌──────────────────┐
                    │   TelaPrincipal   │
                    │  (Lista Livros)   │
                    └────────┬─────────┘
                             │ tap livro
              ┌──────────────┼──────────────┐
              │              ▼              │
              │     ┌─────────────────┐    │
              │     │ TelaListaPaginas│    │
              │     │ (Páginas+cores) │    │
              │     └────────┬─────────┘    │
              │              │ tap verde    │ tap roxo
              │              ▼              ▼
              │     ┌─────────────┐  ┌─────────────┐
              │     │   TelaAR    │  │  TelaRescan  │
              │     │ (Image Track)│  │  (Scanner)  │
              │     └─────────────┘  └─────────────┘
              │
              ▼
    ┌─────────────────┐
    │  TelaGaleria    │  FAB: escanear
    │  (Scanner)      │
    └─────────────────┘
```

### Fluxo de Uso

1. **Início**: App abre em `TelaPrincipal` (lista de livros)
2. **Escanear**: FAB → navega para `TelaGaleria`; Document Scanner captura até 20 páginas
3. **Salvar**: Ao tocar em "GERAR TARGETS DE RA", guarda scan e inicia `TargetPipelineService.processScan`
4. **Lista de páginas**: Tap num livro → `TelaListaPaginas` (indicadores amarelo/verde/vermelho/roxo/cinzento)
5. **RA**: Tap numa página verde → `TelaAR` com Image Tracking; aponta câmera para página física
6. **Rescan**: Página roxa → `TelaRescan` (scanner único); ao capturar, substitui imagem e regressa

---

## 7. Modelo de Dados e Estado

### Estado Local (por Tela)

| Tela | Variáveis de Estado | Descrição |
|------|---------------------|-----------|
| **TelaPrincipal** | `_estaAProcessar`, `_raPronta` | Controla fluxo e habilitação do botão RA |
| **TelaGaleria** | `_paginasEscaneadas`, `_processando` | Lista de imagens (paths) e estado do scanner |
| **TelaAR** | `_controller`, `_isARSupported`, `_temPermissaoCamera` | Controller Augen, suporte AR, permissões |

### Persistência

- **Feature 001**: Imagens em diretório privado (path_provider); metadados em SQLite (sqflite).
- **Feature 003**: Migration v2 — tabela `imagens` estendida com `numero_pagina`, `eh_pagina`, `estado_target`, `qualidade_target`.

---

## 8. Configurações de Build

### Android (build.gradle.kts)

- **Namespace**: `com.example.projetotcc`
- **minSdk**: 24 (Android 7.0)
- **targetSdk / compileSdk**: 36
- **Kotlin**: JVM target 1.8
- **Java**: 1.8

### Tema da Aplicação

- **Modo**: Escuro (ThemeData.dark)
- **Background**: `#121212`
- **AppBar**: `#1E1E1E`
- **Título**: "Marcador AR"

---

## 9. Dependências de Permissões

| Permissão | Uso |
|-----------|-----|
| **Camera** | Document Scanner, Tela AR (Augen) |
| **Storage** | Salvamento de imagens escaneadas (feature 001; diretório privado) |

---

## 10. Pontos de Extensão e Melhorias Futuras

1. **Backend real**: Substituir `_simularProcessamentoNaNuvem()` por chamada HTTP a API de geração de targets
2. **Persistência**: Salvar páginas escaneadas e targets entre sessões
3. **Separação de camadas**: Introduzir camada de domínio (models, use cases) e dados (repositories)
4. **Gerenciamento de estado**: Considerar Provider, Riverpod ou Bloc para estado global
5. **Targets customizados**: Associar modelos 3D específicos às páginas escaneadas (em vez do modelo fixo Astronaut.glb)
6. **Testes**: Adicionar testes unitários e de widget

---

## 11. Diagrama de Componentes (Resumido)

```
┌─────────────────────────────────────────────────────────────────┐
│                         Marcador AR App                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ TelaPrincipal│  │TelaListaPag.│  │   TelaAR    │              │
│  │ TelaGaleria  │  │ TelaRescan  │  │ (Image Track)│              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         │                 │                 │                     │
│         └─────────────────┼─────────────────┘                     │
│                           │                                       │
│  ┌────────────────────────┼────────────────────────┐             │
│  │  Plugins / Serviços    │                        │             │
│  │  • Document Scanner    │  • Augen (AR)          │             │
│  │  • Permission Handler │  • Camera               │             │
│  └─────────────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

---

*Documento gerado com base na análise do código-fonte do projeto. Última atualização: Fevereiro 2026.*
