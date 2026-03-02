import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/ar_opencv_service.dart';
import 'utils/camera_image_to_mat.dart';

class TelaAR extends StatefulWidget {
  final String? scanId;
  final int? imagemId;

  const TelaAR({super.key, this.scanId, this.imagemId});

  @override
  State<TelaAR> createState() => _TelaARState();
}

class _TelaARState extends State<TelaAR> {
  static const Color _bgDark = Color(0xFF121212);
  static const Color _appBarDark = Color(0xFF1E1E1E);
  static const Duration _hintDelay = Duration(seconds: 5);

  bool _temPermissaoCamera = false;
  bool _permissaoNegada = false;
  bool _mostrarDica = false;
  String? _erroCamera;
  CameraController? _cameraController;
  ArOpencvService? _arService;
  ArMatchResult? _matchAtual;
  StreamSubscription<CameraImage>? _imageSubscription;
  Timer? _timerDica;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    if (!Platform.isAndroid && !Platform.isIOS) {
      // RA apenas Android/iOS (spec 004)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Realidade aumentada disponível apenas em Android e iOS.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.maybePop(context);
        }
      });
      return;
    }
    if (widget.scanId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.maybePop(context);
      });
      return;
    }
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _verificarTargets();
    if (!mounted) return;
    await _pedirPermissaoCamera();
    if (!mounted) return;
    if (_temPermissaoCamera) {
      await _iniciarCamera();
      if (mounted) _iniciarDicaTimer();
    }
  }

  Future<void> _verificarTargets() async {
    final scanId = widget.scanId;
    if (scanId == null) return;
    final paths = await ArOpencvService.getTargetPathsForSession(
      scanId,
      imagemId: widget.imagemId,
    );
    if (!mounted) return;
    if (paths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma página disponível para RA. Volte à lista de páginas.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      return;
    }
    _arService = ArOpencvService(paths);
    await _arService!.init();
    if (!mounted) return;
    if (_arService!.targetCount == 0) {
      _arService!.dispose();
      _arService = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar as imagens para reconhecimento.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pedirPermissaoCamera() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;
    setState(() {
      _temPermissaoCamera = status.isGranted;
      _permissaoNegada = status.isDenied || status.isPermanentlyDenied;
    });
  }

  Future<void> _iniciarCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _erroCamera = 'Nenhuma câmera disponível.');
        return;
      }
      final controller = CameraController(
        _cameras!.first,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _erroCamera = null;
      });
      _iniciarStream();
    } on CameraException catch (e) {
      setState(() => _erroCamera = e.description ?? 'Erro ao iniciar câmera.');
    } catch (e) {
      setState(() => _erroCamera = 'Falha ao inicializar câmera.');
    }
  }

  void _iniciarStream() {
    _cameraController?.startImageStream((CameraImage image) {
      if (_arService == null || !mounted) return;
      final mat = cameraImageToMat(image);
      if (mat == null) return;
      try {
        final result = _arService!.matchFrame(mat);
        mat.dispose();
        if (!mounted) return;
        setState(() {
          _matchAtual = result;
          if (result != null) {
            _mostrarDica = false;
            _timerDica?.cancel();
            _timerDica = Timer(_hintDelay, () {
              if (mounted) setState(() => _mostrarDica = true);
            });
          }
        });
      } catch (_) {
        mat.dispose();
      }
    });
  }

  void _iniciarDicaTimer() {
    _timerDica?.cancel();
    _timerDica = Timer(_hintDelay, () {
      if (mounted && _matchAtual == null) {
        setState(() => _mostrarDica = true);
      }
    });
  }

  void _aoTocarNaTela(TapDownDetails details) {
    if (_matchAtual == null) return;
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

  @override
  void dispose() {
    _timerDica?.cancel();
    _imageSubscription?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _arService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return Scaffold(
        backgroundColor: _bgDark,
        appBar: AppBar(
          title: const Text('Marcador RA'),
          backgroundColor: _appBarDark,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('RA não disponível nesta plataforma.')),
      );
    }

    if (widget.scanId == null) {
      return Scaffold(
        backgroundColor: _bgDark,
        appBar: AppBar(
          title: const Text('Marcador RA'),
          backgroundColor: _appBarDark,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Livro não selecionado.')),
      );
    }

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        title: const Text('Marcador RA'),
        backgroundColor: _appBarDark,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_permissaoNegada) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'É necessária permissão de câmera para usar a realidade aumentada.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => openAppSettings(),
                child: const Text('Abrir definições'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_temPermissaoCamera) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Aguardando permissão da câmera...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_erroCamera != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                _erroCamera!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTapDown: _aoTocarNaTela,
          child: CameraPreview(_cameraController!),
        ),
        if (_matchAtual != null && _cameraController != null)
          _buildOverlay(
            _matchAtual!,
            previewSize: _cameraController!.value.previewSize,
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 30,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _matchAtual != null
                    ? 'Toque no ecrã para adicionar a anotação 3D!'
                    : (_mostrarDica
                        ? 'Aponte para uma página escaneada'
                        : 'Aponte para a página e toque para anotar.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlay(ArMatchResult result, {Size? previewSize}) {
    if (result.corners.length < 4) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _OverlayPainter(
            corners: result.corners,
            previewSize: previewSize ?? Size.zero,
            layoutSize: Size(constraints.maxWidth, constraints.maxHeight),
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final List<Offset> corners;
  final Size previewSize;
  final Size layoutSize;

  _OverlayPainter({
    required this.corners,
    required this.previewSize,
    required this.layoutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (previewSize.width <= 0 || previewSize.height <= 0) return;
    final scaleW = layoutSize.width / previewSize.width;
    final scaleH = layoutSize.height / previewSize.height;
    final scale = scaleW < scaleH ? scaleW : scaleH;
    final offsetX = (layoutSize.width - previewSize.width * scale) / 2;
    final offsetY = (layoutSize.height - previewSize.height * scale) / 2;
    final paint = Paint()
      ..color = Colors.green.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final path = Path();
    for (var i = 0; i < corners.length; i++) {
      final p = Offset(offsetX + corners[i].dx * scale, offsetY + corners[i].dy * scale);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) =>
      old.corners != corners ||
      old.previewSize != previewSize ||
      old.layoutSize != layoutSize;
}
