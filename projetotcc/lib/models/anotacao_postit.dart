/// Modelo que representa uma anotação em forma de post-it ancorada a uma página.
class AnotacaoPostit {
  final int? id;
  final String scanId;
  final int imagemId;
  final double u;
  final double v;
  final String texto;
  final int createdAt;
  final int updatedAt;

  const AnotacaoPostit({
    this.id,
    required this.scanId,
    required this.imagemId,
    required this.u,
    required this.v,
    required this.texto,
    required this.createdAt,
    required this.updatedAt,
  });

  AnotacaoPostit copyWith({
    int? id,
    String? scanId,
    int? imagemId,
    double? u,
    double? v,
    String? texto,
    int? createdAt,
    int? updatedAt,
  }) {
    return AnotacaoPostit(
      id: id ?? this.id,
      scanId: scanId ?? this.scanId,
      imagemId: imagemId ?? this.imagemId,
      u: u ?? this.u,
      v: v ?? this.v,
      texto: texto ?? this.texto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AnotacaoPostit.fromMap(Map<String, dynamic> map) {
    return AnotacaoPostit(
      id: map['id'] as int?,
      scanId: map['scan_id'] as String,
      imagemId: map['imagem_id'] as int,
      u: (map['u'] as num).toDouble(),
      v: (map['v'] as num).toDouble(),
      texto: (map['texto'] as String?) ?? '',
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scan_id': scanId,
      'imagem_id': imagemId,
      'u': u,
      'v': v,
      'texto': texto,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

