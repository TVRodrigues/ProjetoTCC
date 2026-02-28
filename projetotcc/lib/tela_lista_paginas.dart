import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'models/scan.dart';
import 'models/imagem_page.dart';
import 'services/scan_database.dart';
import 'services/target_pipeline_service.dart';
import 'tela_ar.dart';
import 'tela_rescan.dart';

class TelaListaPaginas extends StatefulWidget {
  final Scan scan;

  const TelaListaPaginas({super.key, required this.scan});

  @override
  State<TelaListaPaginas> createState() => _TelaListaPaginasState();
}

class _TelaListaPaginasState extends State<TelaListaPaginas> {
  List<ImagemPage> _imagens = [];
  final TargetPipelineService _pipeline = TargetPipelineService();
  StreamSubscription<ImagemPageUpdate>? _subscription;

  @override
  void initState() {
    super.initState();
    _carregarImagens();
    _subscription = _pipeline.pageUpdates.listen((update) {
      if (update.scanId == widget.scan.id && mounted) {
        _carregarImagens();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pipeline.dispose();
    super.dispose();
  }

  Future<void> _carregarImagens() async {
    final list = await ScanDatabase.getImagensForScan(widget.scan.id);
    if (mounted) {
      setState(() => _imagens = list);
    }
  }

  Color _corParaEstado(String estado) {
    switch (estado) {
      case 'processando':
        return Colors.amber;
      case 'sucesso':
        return Colors.green;
      case 'falha':
        return Colors.red;
      case 'rescan':
        return Colors.purple;
      case 'nao_pagina':
        return Colors.grey;
      default:
        return Colors.amber;
    }
  }

  void _aoTocarPagina(ImagemPage img) {
    if (img.estadoTarget == 'processando') return;
    if (img.estadoTarget == 'nao_pagina') return; // Apenas visualização
    if (img.estadoTarget == 'sucesso') {
      Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (ctx) => TelaAR(scanId: widget.scan.id, imagemId: img.id),
        ),
      ).then((refreshed) {
        if (refreshed == true && mounted) _carregarImagens();
      });
      return;
    }
    if (img.estadoTarget == 'falha') {
      _pipeline.retryImage(img.id);
      return;
    }
    if (img.estadoTarget == 'rescan') {
      Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (ctx) => TelaRescan(scanId: widget.scan.id, imagemId: img.id),
        ),
      ).then((refreshed) {
        if (refreshed == true && mounted) _carregarImagens();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scan.titulo),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: _imagens.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _imagens.length,
              itemBuilder: (ctx, i) {
                final img = _imagens[i];
                final cor = _corParaEstado(img.estadoTarget);
                final clicavel = img.estadoTarget != 'processando' &&
                    img.estadoTarget != 'nao_pagina';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: clicavel ? () => _aoTocarPagina(img) : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: File(img.caminho).existsSync()
                                  ? Image.file(
                                      File(img.caminho),
                                      width: 56,
                                      height: 72,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 56,
                                      height: 72,
                                      color: Colors.grey.shade800,
                                      child: const Icon(Icons.image_not_supported),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Página ${img.ordem}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    img.estadoTarget,
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cor.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                img.estadoTarget == 'processando'
                                    ? Icons.hourglass_empty
                                    : img.estadoTarget == 'sucesso'
                                        ? Icons.check_circle
                                        : img.estadoTarget == 'nao_pagina'
                                            ? Icons.visibility
                                            : img.estadoTarget == 'rescan'
                                                ? Icons.camera_alt
                                                : Icons.error,
                                color: cor,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
