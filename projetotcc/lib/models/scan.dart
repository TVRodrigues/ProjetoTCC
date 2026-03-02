/// Modelo que representa uma sessão de escaneamento guardada.
class Scan {
  final String id;
  final String titulo;
  final String? autor;
  final String? resumo;
  final int dataCriacao;
  final List<String> imagePaths;

  const Scan({
    required this.id,
    required this.titulo,
    this.autor,
    this.resumo,
    required this.dataCriacao,
    required this.imagePaths,
  });

  factory Scan.fromMap(Map<String, dynamic> map, List<String> paths) {
    return Scan(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      autor: map['autor'] as String?,
      resumo: map['resumo'] as String?,
      dataCriacao: map['data_criacao'] as int,
      imagePaths: paths,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'autor': autor,
      'resumo': resumo,
      'data_criacao': dataCriacao,
    };
  }
}
