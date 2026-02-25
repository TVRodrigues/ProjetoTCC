import 'package:flutter/material.dart';
import 'package:augen/augen.dart'; // Para controlarmos o tamanho (escala)

class TelaAR extends StatefulWidget {
  const TelaAR({super.key});

  @override
  State<TelaAR> createState() => _TelaARState();
}

class _TelaARState extends State<TelaAR> {
  AugenController? _controller;
  bool _isARSupported = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Função disparada assim que a câmara abre
  Future<void> _onARViewCreated(AugenController controller) async {
    _controller = controller;

    // Verifica suporte ao motor de RA do aparelho
    final isSupported = await controller.isARSupported();
    if (mounted) {
      setState(() {
        _isARSupported = isSupported;
      });
    }

    if (!isSupported) {
      debugPrint('Realidade Aumentada não é suportada neste dispositivo.');
      return;
    }

    // Inicializa a sessão com leitura de iluminação e deteção de superfícies ativas
    await _controller!.initialize(
      const ARSessionConfig(
        planeDetection: true,
        lightEstimation: true,
        depthData: false,
        autoFocus: true,
      ),
    );
  }

  // O "Hit Test": Disparado quando o utilizador toca no ecrã
  Future<void> _aoTocarNaTela(TapUpDetails details) async {
    if (_controller == null || !_isARSupported) return;

    // Pega as coordenadas X e Y do exato ponto em que o dedo tocou no vidro do telemóvel
    final screenX = details.localPosition.dx;
    final screenY = details.localPosition.dy;

    // Dispara um "raio" invisível do ecrã para o mundo físico para ver se bate numa mesa/livro
    final results = await _controller!.hitTest(screenX, screenY);

    // Se o raio bateu num plano real válido
    if (results.isNotEmpty) {
      // Instanciamos o objeto 3D nesse exato ponto
      await _controller!.addNode(
        ARNode(
          id: 'astronauta_${DateTime.now().millisecondsSinceEpoch}', // Nome único
          type: NodeType.model,
          // Usamos modelPath em vez de uri, e o Augen faz o download seguro!
          modelPath:
              'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
          position: results.first.position,
          rotation: results.first.rotation,
          scale: Vector3(
            0.05,
            0.05,
            0.05,
          ), // Um bom tamanho para anotações em livros
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anotação colada com sucesso no livro!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcador RA (Nova Geração)'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Envolvemos a câmara num GestureDetector (Ouvinte de Toque) do Flutter
          GestureDetector(
            onTapUp: _aoTocarNaTela,
            child: AugenView(
              onViewCreated: _onARViewCreated,
              config: const ARSessionConfig(
                planeDetection: true,
                lightEstimation: true,
                depthData: false,
                autoFocus: true,
              ),
            ),
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.only(bottom: 30),
              child: const Text(
                'Aponte para a página e toque no ecrã para adicionar a anotação 3D!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
