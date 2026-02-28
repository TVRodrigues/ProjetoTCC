/// Estado do processamento de target por imagem.
enum EstadoTarget {
  processando,
  sucesso,
  falha,
  rescan,
  naoPagina,
}

/// Converte string da BD para enum.
EstadoTarget estadoTargetFromString(String value) {
  switch (value) {
    case 'processando':
      return EstadoTarget.processando;
    case 'sucesso':
      return EstadoTarget.sucesso;
    case 'falha':
      return EstadoTarget.falha;
    case 'rescan':
      return EstadoTarget.rescan;
    case 'nao_pagina':
      return EstadoTarget.naoPagina;
    default:
      return EstadoTarget.processando;
  }
}

/// Converte enum para string da BD.
String estadoTargetToString(EstadoTarget estado) {
  switch (estado) {
    case EstadoTarget.processando:
      return 'processando';
    case EstadoTarget.sucesso:
      return 'sucesso';
    case EstadoTarget.falha:
      return 'falha';
    case EstadoTarget.rescan:
      return 'rescan';
    case EstadoTarget.naoPagina:
      return 'nao_pagina';
  }
}

/// Modelo que representa uma imagem/página de um scan com metadados de target.
class ImagemPage {
  final int id;
  final String scanId;
  final String caminho;
  final int ordem;
  final String formato;
  final int? numeroPagina;
  final bool ehPagina;
  final String estadoTarget;
  final int? qualidadeTarget;

  const ImagemPage({
    required this.id,
    required this.scanId,
    required this.caminho,
    required this.ordem,
    required this.formato,
    this.numeroPagina,
    required this.ehPagina,
    required this.estadoTarget,
    this.qualidadeTarget,
  });

  factory ImagemPage.fromMap(Map<String, dynamic> map) {
    return ImagemPage(
      id: map['id'] as int,
      scanId: map['scan_id'] as String,
      caminho: map['caminho'] as String,
      ordem: map['ordem'] as int,
      formato: map['formato'] as String,
      numeroPagina: map['numero_pagina'] as int?,
      ehPagina: (map['eh_pagina'] as int?) == 1,
      estadoTarget: (map['estado_target'] as String?) ?? 'processando',
      qualidadeTarget: map['qualidade_target'] as int?,
    );
  }

  EstadoTarget get estadoEnum => estadoTargetFromString(estadoTarget);
}
