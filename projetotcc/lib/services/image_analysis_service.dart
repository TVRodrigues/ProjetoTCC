import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Resultado da análise de uma imagem para target AR.
class ImageAnalysisResult {
  final bool ehPagina;
  final int? numeroPagina;
  final int? qualidadeTarget;

  const ImageAnalysisResult({
    required this.ehPagina,
    this.numeroPagina,
    this.qualidadeTarget,
  });
}

/// Serviço de análise de imagem para detecção de página e extração de número.
class ImageAnalysisService {
  /// Analisa uma imagem e retorna metadados para persistência.
  /// MVP: numeroPagina retorna null; ehPagina baseada em heurística de texto.
  Future<ImageAnalysisResult> analyze(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      return const ImageAnalysisResult(ehPagina: false);
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        final recognizedText = await textRecognizer.processImage(inputImage);
        textRecognizer.close();

        final text = recognizedText.text.trim();
        // Heurística eh_pagina: se pouquíssimo ou nenhum texto → não é página
        final ehPagina = text.length >= 10;

        // Detecção de capa: primeiro bloco grande no terço superior (heurística simplificada)
        final isCapa = _detectarCapa(recognizedText);
        // Extração de numero_pagina: regex sobre texto (padrões "42", "Pág. 42", "— 42 —")
        final numeroPagina = isCapa ? 0 : _extrairNumeroPagina(text);

        // Qualidade: densidade de texto (0–100)
        final qualidadeTarget = text.isEmpty
            ? 0
            : (text.length.clamp(0, 500) / 5).round().clamp(0, 100);

        return ImageAnalysisResult(
          ehPagina: ehPagina,
          numeroPagina: numeroPagina,
          qualidadeTarget: qualidadeTarget,
        );
      } finally {
        textRecognizer.close();
      }
    } catch (_) {
      return const ImageAnalysisResult(ehPagina: false);
    }
  }

  bool _detectarCapa(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return false;
    final firstBlock = recognizedText.blocks.first;
    final firstText = firstBlock.text.trim();
    if (firstText.length < 15) return false;
    // Heurística: bloco grande (muitos caracteres) no início sugere capa
    final totalChars = recognizedText.blocks.fold<int>(
      0, (sum, b) => sum + b.text.length);
    return firstText.length >= totalChars * 0.3;
  }

  int? _extrairNumeroPagina(String text) {
    final patterns = [
      RegExp(r'[Pp]ág\.?\s*(\d{1,4})\b'),
      RegExp(r'[-—]\s*(\d{1,4})\s*[-—]'),
      RegExp(r'\b(\d{1,4})\b'),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(text);
      if (m != null) {
        final n = int.tryParse(m.group(1) ?? '');
        if (n != null && n < 2000) return n; // Filtrar anos
      }
    }
    return null;
  }
}
