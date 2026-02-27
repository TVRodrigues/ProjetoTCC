# Arquitetura do Projeto - Marcador AR

## 1. Visão Geral

O **Marcador AR** (ProjetoTCC) é um aplicativo móvel multiplataforma desenvolvido em Flutter que permite escanear páginas de livros/documentos, processá-las e visualizar anotações em Realidade Aumentada (RA). O usuário aponta a câmera para uma página escaneada e pode adicionar modelos 3D interativos sobre o conteúdo.

---

## 2. Objetivo do Sistema

- **Escaneamento de documentos**: Captura de páginas de livros via câmera com recorte automático
- **Processamento de imagens**: Simulação de envio para backend para geração de targets de RA
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
| **TelaPrincipal** | tela_principal.dart | Hub central com status do sistema e navegação |
| **TelaGaleria** | main.dart | Scanner de documentos, galeria de páginas, geração de targets |
| **TelaAR** | tela_ar.dart | Visualizador de RA, hit-test, colocação de modelos 3D |

### 4.2 Camada de Serviços (Plugins)

- **Document Scanner**: Captura e recorte de páginas (JPEG, até 20 páginas)
- **Augen**: Sessão AR com detecção de planos, estimativa de luz, foco automático
- **Permission Handler**: Solicitação de permissão de câmera
- **Camera**: Acesso à câmera (usado indiretamente pelos plugins)

---

## 5. Estrutura de Pastas

```
ProjetoTCC/
├── projetotcc/                    # Projeto Flutter principal
│   ├── lib/                        # Código-fonte Dart
│   │   ├── main.dart               # Entry point, App, TelaGaleria
│   │   ├── tela_principal.dart     # Hub Central
│   │   └── tela_ar.dart            # Tela de Realidade Aumentada
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
                    │  (Hub Central)    │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              │              ▼
    ┌─────────────────┐      │      ┌─────────────┐
    │  TelaGaleria    │      │      │   TelaAR    │
    │  (Scanner)      │      │      │ (Visualizador│
    │                 │      │      │     RA)     │
    └────────┬────────┘      │      └─────────────┘
             │               │
             │  Navigator.pop │  (apenas quando
             └───────────────┘   _raPronta = true)
```

### Fluxo de Uso

1. **Início**: App abre em `TelaPrincipal`
2. **Escanear**: Usuário toca em "1. Escanear Nova Página" → navega para `TelaGaleria`
3. **Captura**: Em `TelaGaleria`, usa o Document Scanner para capturar até 20 páginas
4. **Salvar**: Ao tocar em "GERAR TARGETS DE RA", retorna ao Hub (`Navigator.pop`)
5. **Processamento**: `TelaPrincipal` simula processamento na nuvem (~4s)
6. **RA**: Quando `_raPronta = true`, o botão "2. Abrir Visualizador RA" é habilitado
7. **Visualização**: Usuário abre `TelaAR`, aponta para a página e toca para adicionar modelo 3D

---

## 7. Modelo de Dados e Estado

### Estado Local (por Tela)

| Tela | Variáveis de Estado | Descrição |
|------|---------------------|-----------|
| **TelaPrincipal** | `_estaAProcessar`, `_raPronta` | Controla fluxo e habilitação do botão RA |
| **TelaGaleria** | `_paginasEscaneadas`, `_processando` | Lista de imagens (paths) e estado do scanner |
| **TelaAR** | `_controller`, `_isARSupported`, `_temPermissaoCamera` | Controller Augen, suporte AR, permissões |

### Persistência

- **Atual**: Nenhuma persistência. As imagens escaneadas existem apenas em memória durante a sessão.
- **Futuro**: Possível integração com armazenamento local (path_provider, shared_preferences) ou backend.

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
| **Storage** (futuro) | Salvamento de imagens escaneadas |

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
│  │ TelaPrincipal│  │ TelaGaleria │  │   TelaAR    │              │
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
