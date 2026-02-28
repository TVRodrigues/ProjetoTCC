import 'dart:async';
import 'dart:io';
import 'scan_database.dart';
import 'image_analysis_service.dart';
import '../models/imagem_page.dart';

/// Atualização de estado de uma imagem emitida pelo pipeline.
class ImagemPageUpdate {
  final String scanId;
  final int imagemId;
  final String estadoTarget;
  final int? numeroPagina;
  final bool? ehPagina;
  final int? qualidadeTarget;

  const ImagemPageUpdate({
    required this.scanId,
    required this.imagemId,
    required this.estadoTarget,
    this.numeroPagina,
    this.ehPagina,
    this.qualidadeTarget,
  });
}

/// Serviço de processamento de targets AR em background.
class TargetPipelineService {
  final ImageAnalysisService _analyzer = ImageAnalysisService();

  final _pageUpdatesController = StreamController<ImagemPageUpdate>.broadcast();

  Stream<ImagemPageUpdate> get pageUpdates => _pageUpdatesController.stream;

  void dispose() {
    _pageUpdatesController.close();
  }

  /// Inicia o processamento assíncrono de todas as imagens de um scan.
  Future<void> processScan(String scanId) async {
    // Executa em background sem bloquear a UI
    Future.microtask(() => _processScanImpl(scanId));
  }

  Future<void> _processScanImpl(String scanId) async {
    final imagens = await ScanDatabase.getImagensForScan(scanId);
    for (final img in imagens) {
      if (img.estadoTarget != 'processando') continue;
      await _processImage(scanId, img);
    }
  }

  Future<void> _processImage(String scanId, ImagemPage img) async {
    try {
      final result = await _analyzer.analyze(img.caminho);
      if (!result.ehPagina) {
        await ScanDatabase.updateImagemMetadata(
          imagemId: img.id,
          ehPagina: false,
          estadoTarget: 'nao_pagina',
        );
        _emit(scanId, img.id, 'nao_pagina', null, false, null);
        return;
      }
      await ScanDatabase.updateImagemMetadata(
        imagemId: img.id,
        numeroPagina: result.numeroPagina,
        ehPagina: true,
        qualidadeTarget: result.qualidadeTarget,
        estadoTarget: 'sucesso',
      );
      _emit(
        scanId,
        img.id,
        'sucesso',
        result.numeroPagina,
        true,
        result.qualidadeTarget,
      );
    } catch (_) {
      await ScanDatabase.updateImagemEstado(img.id, 'falha');
      _emit(scanId, img.id, 'falha', null, null, null);
    }
  }

  void _emit(
    String scanId,
    int imagemId,
    String estadoTarget, [
    int? numeroPagina,
    bool? ehPagina,
    int? qualidadeTarget,
  ]) {
    if (!_pageUpdatesController.isClosed) {
      _pageUpdatesController.add(ImagemPageUpdate(
        scanId: scanId,
        imagemId: imagemId,
        estadoTarget: estadoTarget,
        numeroPagina: numeroPagina,
        ehPagina: ehPagina,
        qualidadeTarget: qualidadeTarget,
      ));
    }
  }

  /// Reprocessa uma imagem que falhou.
  Future<void> retryImage(int imagemId) async {
    final db = await ScanDatabase.database;
    final rows = await db.query(
      'imagens',
      columns: ['id', 'scan_id', 'caminho', 'ordem', 'formato', 'numero_pagina', 'eh_pagina', 'estado_target', 'qualidade_target'],
      where: 'id = ?',
      whereArgs: [imagemId],
    );
    if (rows.isEmpty) return;
    final scanId = rows.first['scan_id'] as String;
    await ScanDatabase.updateImagemEstado(imagemId, 'processando');
    _emit(scanId, imagemId, 'processando');

    try {
      final caminho = rows.first['caminho'] as String;
      final result = await _analyzer.analyze(caminho);
      if (!result.ehPagina) {
        await ScanDatabase.updateImagemMetadata(
          imagemId: imagemId,
          ehPagina: false,
          estadoTarget: 'nao_pagina',
        );
        _emit(scanId, imagemId, 'nao_pagina', null, false, null);
        return;
      }
      await ScanDatabase.updateImagemMetadata(
        imagemId: imagemId,
        numeroPagina: result.numeroPagina,
        ehPagina: true,
        qualidadeTarget: result.qualidadeTarget,
        estadoTarget: 'sucesso',
      );
      _emit(scanId, imagemId, 'sucesso', result.numeroPagina, true, result.qualidadeTarget);
    } catch (_) {
      await ScanDatabase.updateImagemEstado(imagemId, 'rescan');
      _emit(scanId, imagemId, 'rescan');
    }
  }

  /// Substitui uma imagem (rescan) por nova captura.
  Future<void> replaceImageForRescan(int imagemId, String novoCaminho) async {
    final file = File(novoCaminho);
    if (!await file.exists()) return;

    final db = await ScanDatabase.database;
    final rows = await db.query(
      'imagens',
      columns: ['caminho', 'scan_id'],
      where: 'id = ?',
      whereArgs: [imagemId],
    );
    if (rows.isEmpty) return;
    final oldPath = rows.first['caminho'] as String;
    final scanId = rows.first['scan_id'] as String;

    // Substitui ficheiro: copia novo para o path antigo (mantém estrutura de pastas)
    await file.copy(oldPath);
    if (novoCaminho != oldPath) {
      try {
        await file.delete();
      } catch (_) {}
    }

    await ScanDatabase.updateImagemPath(imagemId, oldPath);
    _emit(scanId, imagemId, 'processando');

    // Reinicia processamento
    final imagens = await ScanDatabase.getImagensForScan(scanId);
    final img = imagens.where((i) => i.id == imagemId).firstOrNull;
    if (img != null) {
      await _processImage(scanId, img);
    }
  }
}
