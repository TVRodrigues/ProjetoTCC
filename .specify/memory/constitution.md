<!--
  Sync Impact Report
  Version change: (template) → 1.0.0
  Modified principles: N/A (initial fill from template)
  Added sections: All sections filled from docs/ARQUITETURA.md
  Removed sections: None
  Templates requiring updates:
    - .specify/templates/plan-template.md ✅ (Constitution Check references principles)
    - .specify/templates/spec-template.md ✅ (scope aligns with principles)
    - .specify/templates/tasks-template.md ✅ (task types compatible)
  Follow-up TODOs: None
-->

# Marcador AR (ProjetoTCC) Constitution

## Core Principles

### I. Documentation-First

A documentação em `docs/ARQUITETURA.md` é a fonte de verdade para arquitetura, stack tecnológica, estrutura de pastas e fluxos. Alterações que impactem camadas, tecnologias ou estrutura de pastas MUST ser refletidas nesse documento. Novas features que introduzam componentes significativos devem documentar integração no fluxo existente.

**Rationale**: Mantém consistência entre código e documentação, essencial para TCC e manutenção futura.

### II. Presentation + Services

O projeto segue arquitetura em duas camadas: (1) Apresentação — widgets Flutter (telas, estado, navegação) em `lib/`; (2) Serviços — plugins nativos (ML Kit, Augen, Camera, Permission Handler). Lógica de negócio complexa que crescer além de um widget MUST ser extraída para camada de domínio ou serviços antes de implementação.

**Rationale**: Evita acoplamento excessivo; prepara evolução para separação de camadas (domínio, dados) quando justificado.

### III. Flutter Stack

O stack MUST permanecer Flutter/Dart: Dart ^3.11.0, Flutter SDK. Plataformas alvo: Android (minSdk 24, targetSdk 36), iOS, Windows. Dependências principais: google_mlkit_document_scanner, augen, permission_handler, camera, http. Novas dependências MUST ser justificadas e documentadas em `docs/ARQUITETURA.md`.

**Rationale**: Garante compatibilidade e evita fragmentação de stack em projeto multiplataforma.

### IV. Simplicity (YAGNI)

Evitar complexidade prematura. Não introduzir gerenciamento de estado global (Provider, Riverpod, Bloc), camadas de domínio/dados ou persistência sem requisito explícito. Cada adição MUST resolver um problema concreto; alternativas mais simples devem ser consideradas primeiro.

**Rationale**: Projeto TCC beneficia de foco em funcionalidade; refatoração pode vir após validação.

### V. Permissions & Privacy

Permissões sensíveis (câmera, armazenamento) MUST ser solicitadas no momento de uso, com feedback claro ao usuário. A tela de RA MUST verificar permissão de câmera antes de inicializar o visualizador. Falhas de permissão devem ser tratadas graciosamente (mensagem, não crash).

**Rationale**: Conformidade com boas práticas de UX e políticas de loja (Play Store, App Store).

## Technical Constraints

- **Namespace Android**: `com.example.projetotcc`
- **Tema**: Modo escuro (ThemeData.dark), background #121212, AppBar #1E1E1E
- **Linter**: Regras de `analysis_options.yaml` (flutter_lints) devem ser respeitadas
- **Estrutura de pastas**: `lib/` para código Dart; `docs/` para documentação; `projetotcc/` como raiz do projeto Flutter

## Development Workflow

- Alterações em fluxo de navegação ou telas devem ser validadas contra `docs/ARQUITETURA.md`
- Novas features que alterem arquitetura ou stack devem atualizar a documentação antes do merge
- Testes (unitários, widget) são recomendados para novas funcionalidades críticas; não obrigatórios para protótipos iniciais

## Governance

- Esta constituição tem precedência sobre práticas ad-hoc; exceções devem ser documentadas e justificadas
- Emendas requerem: (1) proposta documentada, (2) atualização de `docs/ARQUITETURA.md` se aplicável, (3) versionamento semântico (MAJOR/MINOR/PATCH)
- PRs e revisões devem verificar conformidade com os princípios; violações devem ser explicitamente justificadas na seção "Complexity Tracking" do plano (quando aplicável)
- Use `docs/ARQUITETURA.md` como guia de referência para desenvolvimento e onboarding

**Version**: 1.0.0 | **Ratified**: 2026-02-26 | **Last Amended**: 2026-02-26
