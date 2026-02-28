import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/scan.dart';
import 'scan_database.dart';

/// Exceções para falhas de persistência.
class StoragePermissionDeniedException implements Exception {
  final String message;
  StoragePermissionDeniedException([
    this.message = 'Permissão de armazenamento negada',
  ]);
}

class StorageFullException implements Exception {
  final String message;
  StorageFullException([this.message = 'Espaço insuficiente no dispositivo']);
}

class ValidationException implements Exception {
  final String message;
  ValidationException([this.message = 'Título do livro é obrigatório']);
}

/// Serviço de persistência de scans (imagens + metadados).
class ScanStorageService {
  /// Retorna o número total de scans.
  Future<int> getScansCount() => ScanDatabase.getScansCount();

  /// Carrega todos os scans com imagePaths, ordenados por data_criacao DESC.
  Future<List<Scan>> loadScans() async {
    final rows = await ScanDatabase.getScans();
    final scans = <Scan>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final paths = await ScanDatabase.getImagePathsForScan(id);
      scans.add(Scan.fromMap(row, paths));
    }
    return scans;
  }

  /// Remove um scan: ficheiros da pasta + registos na BD.
  Future<void> deleteScan(String id) async {
    final dir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${dir.path}/scans');
    if (await scansDir.exists()) {
      final entries = await scansDir.list().toList();
      for (final e in entries) {
        if (e is Directory) {
          final name = e.path.split(RegExp(r'[/\\]')).last;
          if (name.endsWith('_$id')) {
            try {
              await e.delete(recursive: true);
            } catch (_) {}
            break;
          }
        }
      }
    }
    await ScanDatabase.deleteScan(id);
  }

  /// Sanitiza o título para uso em nomes de pasta.
  static String _sanitizeForPath(String titulo) {
    const invalid = r'\/:*?"<>|';
    var sanitized = titulo;
    for (var i = 0; i < invalid.length; i++) {
      sanitized = sanitized.replaceAll(invalid[i], '_');
    }
    sanitized = sanitized.replaceAll(' ', '_');
    if (sanitized.length > 100) {
      sanitized = sanitized.substring(0, 100);
    }
    return sanitized.isEmpty ? 'scan' : sanitized;
  }

  /// Persiste um scan com imagens e metadados.
  /// Lança [ValidationException] se titulo for vazio.
  /// Lança [StoragePermissionDeniedException] se permissão negada.
  /// Lança [StorageFullException] se não houver espaço.
  Future<Scan> saveScan({
    required String titulo,
    String? autor,
    String? resumo,
    required List<String> imagePaths,
  }) async {
    titulo = titulo.trim();
    if (titulo.isEmpty) {
      throw ValidationException('O título do livro é obrigatório.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${dir.path}/scans');
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final folderName = '${_sanitizeForPath(titulo)}_$id';
    final scanDir = Directory('${scansDir.path}/$folderName');
    await scanDir.create(recursive: true);

    final persistedPaths = <String>[];
    try {
      for (var i = 0; i < imagePaths.length; i++) {
        final src = File(imagePaths[i]);
        if (!await src.exists()) continue;
        final ext = imagePaths[i].toLowerCase().endsWith('.png')
            ? 'png'
            : 'jpg';
        final destPath =
            '${scanDir.path}/page_${(i + 1).toString().padLeft(3, '0')}.$ext';
        await src.copy(destPath);
        persistedPaths.add(destPath);
      }

      final dataCriacao = DateTime.now().millisecondsSinceEpoch;
      final imagens = <Map<String, dynamic>>[];
      for (var i = 0; i < persistedPaths.length; i++) {
        final p = persistedPaths[i];
        imagens.add({
          'scan_id': id,
          'caminho': p,
          'ordem': i + 1,
          'formato': p.toLowerCase().endsWith('.png') ? 'png' : 'jpg',
          'estado_target': 'processando',
          'eh_pagina': 1,
        });
      }

      await ScanDatabase.insertScan(
        id: id,
        titulo: titulo,
        autor: autor?.trim().isEmpty == true ? null : autor?.trim(),
        resumo: resumo?.trim().isEmpty == true ? null : resumo?.trim(),
        dataCriacao: dataCriacao,
        imagens: imagens,
      );

      return Scan(
        id: id,
        titulo: titulo,
        autor: autor,
        resumo: resumo,
        dataCriacao: dataCriacao,
        imagePaths: persistedPaths,
      );
    } catch (e) {
      // Rollback: remover ficheiros copiados
      for (final p in persistedPaths) {
        try {
          await File(p).delete();
        } catch (_) {}
      }
      if (scanDir.existsSync()) {
        try {
          await scanDir.delete(recursive: true);
        } catch (_) {}
      }
      if (e is StoragePermissionDeniedException ||
          e is StorageFullException ||
          e is ValidationException) {
        rethrow;
      }
      if (e.toString().toLowerCase().contains('space') ||
          e.toString().toLowerCase().contains('disk') ||
          e.toString().toLowerCase().contains('full')) {
        throw StorageFullException(
          'Espaço insuficiente no dispositivo. Libere espaço e tente novamente.',
        );
      }
      rethrow;
    }
  }
}
