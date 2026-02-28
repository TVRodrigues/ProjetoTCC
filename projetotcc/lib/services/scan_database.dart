import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/imagem_page.dart';

/// Inicialização e acesso à base de dados SQLite para scans e imagens.
class ScanDatabase {
  static Database? _database;
  static const String _dbName = 'marcador_ar.db';
  static const int _version = 2;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = '${documentsDirectory.path}/$_dbName';

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scans (
        id TEXT PRIMARY KEY,
        titulo TEXT NOT NULL,
        autor TEXT,
        resumo TEXT,
        data_criacao INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE imagens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scan_id TEXT NOT NULL,
        caminho TEXT NOT NULL,
        ordem INTEGER NOT NULL,
        formato TEXT NOT NULL,
        numero_pagina INTEGER,
        eh_pagina INTEGER NOT NULL DEFAULT 1,
        estado_target TEXT NOT NULL DEFAULT 'processando',
        qualidade_target INTEGER,
        FOREIGN KEY (scan_id) REFERENCES scans(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_imagens_scan_id ON imagens(scan_id)',
    );
    await db.execute(
      'CREATE INDEX idx_imagens_scan_ordem ON imagens(scan_id, ordem)',
    );
    await db.execute(
      'CREATE INDEX idx_scans_data_criacao ON scans(data_criacao DESC)',
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE imagens ADD COLUMN numero_pagina INTEGER');
      await db.execute('ALTER TABLE imagens ADD COLUMN eh_pagina INTEGER NOT NULL DEFAULT 1');
      await db.execute(
        "ALTER TABLE imagens ADD COLUMN estado_target TEXT NOT NULL DEFAULT 'processando'",
      );
      await db.execute('ALTER TABLE imagens ADD COLUMN qualidade_target INTEGER');
      await db.execute(
        'CREATE INDEX idx_imagens_scan_ordem ON imagens(scan_id, ordem)',
      );
    }
  }

  /// Retorna o número total de scans na base de dados.
  /// Usado na fase 1 do carregamento da lista (FR-007: ordenação por data_criacao).
  static Future<int> getScansCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM scans');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Retorna todos os scans ordenados por data_criacao DESC (mais recente primeiro).
  static Future<List<Map<String, dynamic>>> getScans() async {
    final db = await database;
    return db.query(
      'scans',
      columns: ['id', 'titulo', 'autor', 'resumo', 'data_criacao'],
      orderBy: 'data_criacao DESC',
    );
  }

  /// Retorna as imagens de um scan como [ImagemPage], ordenadas por numero_pagina (ou ordem).
  static Future<List<ImagemPage>> getImagensForScan(String scanId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT id, scan_id, caminho, ordem, formato, numero_pagina, eh_pagina, estado_target, qualidade_target
      FROM imagens
      WHERE scan_id = ?
      ORDER BY COALESCE(numero_pagina, 9999), ordem ASC
      ''',
      [scanId],
    );
    return rows.map((r) => ImagemPage.fromMap(r)).toList();
  }

  /// Retorna os caminhos das imagens de um scan, ordenados por ordem.
  static Future<List<String>> getImagePathsForScan(String scanId) async {
    final db = await database;
    final rows = await db.query(
      'imagens',
      columns: ['caminho'],
      where: 'scan_id = ?',
      whereArgs: [scanId],
      orderBy: 'ordem ASC',
    );
    return rows.map((r) => r['caminho'] as String).toList();
  }

  /// Remove um scan e as suas imagens da base de dados (CASCADE).
  static Future<void> deleteScan(String id) async {
    final db = await database;
    await db.delete('scans', where: 'id = ?', whereArgs: [id]);
  }

  /// Atualiza o estado de target de uma imagem.
  static Future<void> updateImagemEstado(int imagemId, String estadoTarget) async {
    final db = await database;
    await db.update(
      'imagens',
      {'estado_target': estadoTarget},
      where: 'id = ?',
      whereArgs: [imagemId],
    );
  }

  /// Atualiza o caminho e estado de uma imagem (rescan).
  static Future<void> updateImagemPath(int imagemId, String novoCaminho) async {
    final db = await database;
    await db.update(
      'imagens',
      {'caminho': novoCaminho, 'estado_target': 'processando'},
      where: 'id = ?',
      whereArgs: [imagemId],
    );
  }

  /// Atualiza metadados de uma imagem (numero_pagina, eh_pagina, qualidade_target, estado_target).
  static Future<void> updateImagemMetadata({
    required int imagemId,
    int? numeroPagina,
    bool? ehPagina,
    int? qualidadeTarget,
    String? estadoTarget,
  }) async {
    final db = await database;
    final values = <String, dynamic>{};
    if (numeroPagina != null) values['numero_pagina'] = numeroPagina;
    if (ehPagina != null) values['eh_pagina'] = ehPagina ? 1 : 0;
    if (qualidadeTarget != null) values['qualidade_target'] = qualidadeTarget;
    if (estadoTarget != null) values['estado_target'] = estadoTarget;
    if (values.isEmpty) return;
    await db.update(
      'imagens',
      values,
      where: 'id = ?',
      whereArgs: [imagemId],
    );
  }

  /// Insere um scan e as suas imagens numa transação.
  /// Cada mapa em [imagens] pode incluir: scan_id, caminho, ordem, formato, estado_target, eh_pagina, numero_pagina, qualidade_target.
  static Future<void> insertScan({
    required String id,
    required String titulo,
    String? autor,
    String? resumo,
    required int dataCriacao,
    required List<Map<String, dynamic>> imagens,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('scans', {
        'id': id,
        'titulo': titulo,
        'autor': autor,
        'resumo': resumo,
        'data_criacao': dataCriacao,
      });
      for (final img in imagens) {
        await txn.insert('imagens', img);
      }
    });
  }
}
