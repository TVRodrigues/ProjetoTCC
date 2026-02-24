import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'tela_ar.dart';

void main() {
  runApp(const MeuMarcadorApp());
}

class MeuMarcadorApp extends StatelessWidget {
  const MeuMarcadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Marcador AR',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E)),
      ),
      home: const TelaGaleria(),
    );
  }
}

class TelaGaleria extends StatefulWidget {
  const TelaGaleria({super.key});

  @override
  State<TelaGaleria> createState() => _TelaGaleriaState();
}

class _TelaGaleriaState extends State<TelaGaleria> {
  // Agora guardamos uma LISTA de imagens, não apenas uma
  final List<String> _paginasEscaneadas = [];
  bool _processando = false;

  Future<void> _abrirScanner() async {
    setState(() {
      _processando = true;
    });

    try {
      final DocumentScannerOptions options = DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        // Aumentamos o limite para permitir escanear um capítulo inteiro de uma vez!
        pageLimit: 20,
        isGalleryImport: false,
      );

      final DocumentScanner documentScanner = DocumentScanner(options: options);
      final DocumentScanningResult result = await documentScanner
          .scanDocument();

      // Se o usuário escaneou páginas e clicou em "Salvar" lá no Google
      if (result.images != null && result.images!.isNotEmpty) {
        setState(() {
          // Adicionamos as novas fotos à nossa galeria
          _paginasEscaneadas.addAll(result.images!);
        });
        debugPrint("✅ ${_paginasEscaneadas.length} páginas na galeria agora.");
      }

      documentScanner.close();
    } catch (e) {
      debugPrint("Erro ao escanear: $e");
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  // Função que simula o envio dessas imagens para o algoritmo de RA (Target)
  void _salvarTargets() {
    // Agora o botão verde navega diretamente para o nosso ambiente de Realidade Aumentada
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TelaAR()),
    );
  }

  // Função para remover uma foto da galeria se o usuário não gostar
  void _removerImagem(int index) {
    setState(() {
      _paginasEscaneadas.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Páginas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Botão de escanear lá no topo também
          IconButton(
            icon: const Icon(Icons.document_scanner),
            onPressed: _processando ? null : _abrirScanner,
          ),
        ],
      ),
      body: _paginasEscaneadas.isEmpty
          ? _construirTelaVazia()
          : _construirGradeDeFotos(),

      // Botão flutuante para iniciar o scanner
      floatingActionButton: _paginasEscaneadas.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _processando ? null : _abrirScanner,
              icon: const Icon(Icons.add_a_photo),
              label: const Text("Adicionar Páginas"),
              backgroundColor: Colors.blueAccent,
            ),

      // Barra inferior que aparece quando temos fotos, com o botão "Salvar Tudo"
      // Barra inferior substituída por um Container mais flexível e seguro
      bottomNavigationBar: _paginasEscaneadas.isEmpty
          ? null
          : SafeArea(
              child: Container(
                color: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _salvarTargets,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                    ), // Espaço interno do botão
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "GERAR TARGETS DE RA",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // Tela mostrada quando não há nenhuma foto
  Widget _construirTelaVazia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            "Nenhuma página escaneada ainda.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _processando ? null : _abrirScanner,
            icon: const Icon(Icons.camera_alt),
            label: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text('Iniciar Scanner', style: TextStyle(fontSize: 18)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Grade que mostra as fotos capturadas
  Widget _construirGradeDeFotos() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Mostra 2 fotos por linha
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7, // Proporção parecida com uma folha A4/Livro
      ),
      itemCount: _paginasEscaneadas.length,
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // A imagem recortada
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_paginasEscaneadas[index]),
                fit: BoxFit.cover,
              ),
            ),
            // Uma borda para ficar bonito
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Botão de deletar no canto superior direito
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removerImagem(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
            // Número da página no canto inferior esquerdo
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Pág. ${index + 1}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
