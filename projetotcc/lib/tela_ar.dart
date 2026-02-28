import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:augen/augen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/scan.dart';
import 'services/scan_storage_service.dart';
import 'services/scan_database.dart';

class TelaAR extends StatefulWidget {
  final String? scanId;
  final int? imagemId;

  const TelaAR({super.key, this.scanId, this.imagemId});

  @override
  State<TelaAR> createState() => _TelaARState();
}

class _TelaARState extends State<TelaAR> {
  AugenController? _controller;
  bool _isARSupported = false;
  bool _temPermissaoCamera = false;
  final Set<String> _nodesAncorados = {};

  @override
  void initState() {
    super.initState();
    _pedirPermissaoCamera();
    if (widget.scanId != null) {
      _verificarImagensDoScan();
    }
  }

  Future<void> _verificarImagensDoScan() async {
    final scanId = widget.scanId;
    if (scanId == null) return;

    try {
      final storage = ScanStorageService();
      final scans = await storage.loadScans();
      Scan? scan;
      for (final s in scans) {
        if (s.id == scanId) {
          scan = s;
          break;
        }
      }
      if (scan == null) return;

      var todasExistem = true;
      for (final p in scan.imagePaths) {
        if (!await File(p).exists()) {
          todasExistem = false;
          break;
        }
      }

      if (!todasExistem && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagens não encontradas. Livro removido da lista.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await storage.deleteScan(scanId);
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar livro.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    }
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

    if (widget.scanId != null) {
      await _carregarImageTargets();
    }
  }

  Future<void> _carregarImageTargets() async {
    if (_controller == null || widget.scanId == null) return;
    // Image Tracking só está implementado em Android/iOS; em Windows/emulador causa MissingPluginException
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final imagens = await ScanDatabase.getImagensForScan(widget.scanId!);
    final paginas = imagens
        .where((i) =>
            i.estadoTarget == 'sucesso' &&
            i.ehPagina &&
            File(i.caminho).existsSync())
        .toList();
    if (paginas.isEmpty) return;

    try {
      for (final img in paginas) {
        try {
          final target = ARImageTarget(
            id: 'pagina_${img.id}',
            name: 'Pagina ${img.numeroPagina ?? img.ordem}',
            imagePath: img.caminho,
            physicalSize: const ImageTargetSize(0.21, 0.297),
          );
          await _controller!.addImageTarget(target);
        } catch (_) {}
      }
      await _controller!.setImageTrackingEnabled(true);
      _controller!.trackedImagesStream.listen(_onTrackedImages);
    } on MissingPluginException {
      // Emulador ou plataforma sem implementação de Image Tracking; fallback para plane + hit test
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Image Tracking não disponível. Use toque na tela para colocar anotações em superfícies.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onTrackedImages(List<ARTrackedImage> tracked) async {
    if (_controller == null) return;
    for (final t in tracked) {
      if (t.isTracked && t.isReliable && !_nodesAncorados.contains(t.id)) {
        _nodesAncorados.add(t.id);
        try {
          await _controller!.addNodeToTrackedImage(
            nodeId: 'modelo_${t.id}',
            trackedImageId: t.id,
            node: ARNode(
              id: 'modelo_${t.id}',
              type: NodeType.model,
              modelPath:
                  'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
              position: t.position,
              rotation: t.rotation,
              scale: const Vector3(0.05, 0.05, 0.05),
            ),
          );
        } catch (_) {
          _nodesAncorados.remove(t.id);
        }
      }
      if (!t.isTracked) {
        _nodesAncorados.remove(t.id);
      }
    }
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
        backgroundColor: const Color(0xFF1E1E1E),
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
