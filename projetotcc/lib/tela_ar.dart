import 'package:flutter/material.dart';
import 'package:augen/augen.dart';
import 'package:permission_handler/permission_handler.dart'; // Pacote de permissões

class TelaAR extends StatefulWidget {
  const TelaAR({super.key});

  @override
  State<TelaAR> createState() => _TelaARState();
}

class _TelaARState extends State<TelaAR> {
  AugenController? _controller;
  bool _isARSupported = false;
  bool _temPermissaoCamera = false;

  @override
  void initState() {
    super.initState();
    // Assim que a tela abre, pede permissão antes de fazer qualquer coisa
    _pedirPermissaoCamera();
  }

  Future<void> _pedirPermissaoCamera() async {
    // Verifica e pede a permissão da câmera nativa
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (mounted) {
      setState(() {
        _temPermissaoCamera = status.isGranted;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Função disparada assim que a câmara (já permitida) abre
  Future<void> _onARViewCreated(AugenController controller) async {
    _controller = controller;

    final isSupported = await controller.isARSupported();
    if (mounted) {
      setState(() {
        _isARSupported = isSupported;
      });
    }

    if (!isSupported) {
      // Se não for suportado, avisamos o utilizador na tela em vez de tela preta!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Serviço ARCore da Google desatualizado neste aparelho!',
            ),
          ),
        );
      }
      return;
    }

    await _controller!.initialize(
      const ARSessionConfig(
        planeDetection: true,
        lightEstimation: true,
        depthData: false,
        autoFocus: true,
      ),
    );
  }

  Future<void> _aoTocarNaTela(TapUpDetails details) async {
    if (_controller == null || !_isARSupported) return;

    final screenX = details.localPosition.dx;
    final screenY = details.localPosition.dy;

    final results = await _controller!.hitTest(screenX, screenY);

    if (results.isNotEmpty) {
      await _controller!.addNode(
        ARNode(
          id: 'astronauta_${DateTime.now().millisecondsSinceEpoch}',
          type: NodeType.model,
          modelPath:
              'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
          position: results.first.position,
          rotation: results.first.rotation,
          scale: Vector3(0.05, 0.05, 0.05), // O formato correto!
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
        title: const Text('Marcador RA'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      // Aqui está o "Pulo do Gato":
      // Se não tiver permissão, mostra um loading e não a tela preta
      body: !_temPermissaoCamera
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Aguardando permissão da câmera..."),
                ],
              ),
            )
          : Stack(
              children: [
                GestureDetector(
                  onTapUp: _aoTocarNaTela,
                  child: SizedBox.expand(
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
                ),
                Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
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
