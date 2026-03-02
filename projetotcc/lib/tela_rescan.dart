import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'services/target_pipeline_service.dart';

class TelaRescan extends StatefulWidget {
  final String scanId;
  final int imagemId;

  const TelaRescan({super.key, required this.scanId, required this.imagemId});

  @override
  State<TelaRescan> createState() => _TelaRescanState();
}

class _TelaRescanState extends State<TelaRescan> {
  bool _processando = false;

  Future<void> _abrirScanner() async {
    setState(() => _processando = true);
    try {
      final options = DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        pageLimit: 1,
        isGalleryImport: false,
      );
      final scanner = DocumentScanner(options: options);
      final result = await scanner.scanDocument();
      scanner.close();

      if (result.images != null && result.images!.isNotEmpty) {
        final novoCaminho = result.images!.first;
        final file = File(novoCaminho);
        if (await file.exists()) {
          await TargetPipelineService().replaceImageForRescan(
            widget.imagemId,
            novoCaminho,
          );
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao escanear: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao capturar imagem: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear página novamente'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt,
                size: 64,
                color: Colors.purple,
              ),
              const SizedBox(height: 24),
              const Text(
                'A página anterior falhou no processamento.\nEscaneie a página novamente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _processando ? null : _abrirScanner,
                icon: _processando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.document_scanner),
                label: Text(_processando ? 'A escanear...' : 'Abrir scanner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
