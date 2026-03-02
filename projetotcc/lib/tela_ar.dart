import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import 'models/anotacao_postit.dart';
import 'services/ar_opencv_service.dart';
import 'services/scan_database.dart';
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
  static const double _miraSize = 28;

  bool _temPermissaoCamera = false;
  bool _permissaoNegada = false;
  bool _mostrarDica = false;
  bool _isProcessingFrame = false;
  String? _erroCamera;
  CameraController? _cameraController;
  ArOpencvService? _arService;
  ArMatchResult? _matchAtual;
  Timer? _timerDica;
  List<CameraDescription>? _cameras;
  final List<AnotacaoPostit> _anotacoes = [];

  @override
  void initState() {
    super.initState();
    if (!Platform.isAndroid && !Platform.isIOS) {
      // RA apenas Android/iOS (spec 004)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Realidade aumentada disponível apenas em Android e iOS.',
              ),
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
          content: Text(
            'Nenhuma página disponível para RA. Volte à lista de páginas.',
          ),
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
          content: Text(
            'Não foi possível carregar as imagens para reconhecimento.',
          ),
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
      // 1. Previne encavalamento de processamento (Drop Frame)
      if (_arService == null || !mounted || _isProcessingFrame) return;
      _isProcessingFrame = true;

      final matRaw = cameraImageToMat(image);
      if (matRaw == null) {
        _isProcessingFrame = false;
        return;
      }

      try {
        final mat = cv.rotate(matRaw, cv.ROTATE_90_CLOCKWISE);
        final result = _arService!.matchFrame(mat);

        if (!mounted) return;

        setState(() {
          // 2. Só aceita o resultado se for um polígono válido (sem linhas loucas)
          if (result != null && _isPolygonValid(result.corners)) {
            // 3. Suavização (Interpolação) para parar de "sambar"
            if (_matchAtual != null &&
                _matchAtual!.targetId == result.targetId) {
              final smoothedCorners = <Offset>[];
              for (int i = 0; i < 4; i++) {
                final oldP = _matchAtual!.corners[i];
                final newP = result.corners[i];
                // Dá 70% de peso para a posição antiga (estabilidade) e 30% para a nova (movimento)
                smoothedCorners.add(
                  Offset(
                    oldP.dx * 0.7 + newP.dx * 0.3,
                    oldP.dy * 0.7 + newP.dy * 0.3,
                  ),
                );
              }
              _matchAtual = ArMatchResult(
                targetId: result.targetId,
                corners: smoothedCorners,
              );
            } else {
              _matchAtual = result; // Primeiro rastreio
            }

            _mostrarDica = false;
            _timerDica?.cancel();
            _timerDica = Timer(_hintDelay, () {
              if (mounted) setState(() => _mostrarDica = true);
            });
          } else {
            // Se perder o alvo ou o polígono for inválido, limpa a tela
            _matchAtual = null;
          }
        });
      } catch (e) {
        debugPrint('Erro no loop da câmera: $e');
      } finally {
        // Libera para processar o próximo frame
        _isProcessingFrame = false;
      }
    });
  }

  /// Checa se o polígono formado é Convexo (evita distorções de linhas cruzadas)
  bool _isPolygonValid(List<Offset> corners) {
    if (corners.length != 4) return false;
    bool? isPositive;
    for (int i = 0; i < 4; i++) {
      int j = (i + 1) % 4;
      int k = (i + 2) % 4;
      double crossProduct =
          (corners[j].dx - corners[i].dx) * (corners[k].dy - corners[j].dy) -
          (corners[j].dy - corners[i].dy) * (corners[k].dx - corners[j].dx);
      if (crossProduct == 0) continue;
      bool sign = crossProduct > 0;
      isPositive ??= sign;
      // Se a direção do desenho mudar, as linhas se cruzaram (formato ampulheta) = Inválido
      if (isPositive != sign) return false;
    }
    return true;
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
              const Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.grey,
              ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutSize = Size(constraints.maxWidth, constraints.maxHeight);
        final previewSize = _cameraController!.value.previewSize;
        final centroTela =
            Offset(layoutSize.width / 2, layoutSize.height / 2);

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
                previewSize: previewSize,
                layoutSize: layoutSize,
              ),
            // Mira vermelha translúcida fixa no centro
            IgnorePointer(
              child: Center(
                child: Container(
                  width: _miraSize,
                  height: _miraSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.3),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.9),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _matchAtual != null
                          ? 'Aponte a mira vermelha para a página e toque no botão de nota.'
                          : (_mostrarDica
                              ? 'Aponte para uma página escaneada'
                              : 'Aponte para a página do livro para começar.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: 'fab-nota',
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    onPressed: () => _onPressNovaAnotacao(
                      layoutSize: layoutSize,
                      previewSize: previewSize,
                      centroTela: centroTela,
                    ),
                    shape: const CircleBorder(),
                    child: const Icon(Icons.sticky_note_2_outlined),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverlay(
    ArMatchResult result, {
    required Size previewSize,
    required Size layoutSize,
  }) {
    if (result.corners.length < 4) return const SizedBox.shrink();
    return CustomPaint(
      painter: _OverlayPainter(
        corners: result.corners,
        previewSize: previewSize,
        layoutSize: layoutSize,
      ),
      size: layoutSize,
    );
  }

  Future<void> _onPressNovaAnotacao({
    required Size layoutSize,
    required Size previewSize,
    required Offset centroTela,
  }) async {
    if (widget.scanId == null) return;
    if (widget.imagemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Anotações só estão disponíveis quando entra pela página verde.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_matchAtual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aponte para a página para colocar uma anotação.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final screenCorners = _projectCornersToScreen(
      _matchAtual!.corners,
      previewSize,
      layoutSize,
    );

    if (!_isPointInsidePolygon(centroTela, screenCorners)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aponte a mira para dentro da página para anotar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final xs = screenCorners.map((p) => p.dx).toList();
    final ys = screenCorners.map((p) => p.dy).toList();
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);

    final width = (maxX - minX).abs();
    final height = (maxY - minY).abs();
    if (width <= 0 || height <= 0) {
      return;
    }

    var u = (centroTela.dx - minX) / width;
    var v = (centroTela.dy - minY) / height;
    u = u.clamp(0.0, 1.0);
    v = v.clamp(0.0, 1.0);

    final now = DateTime.now().millisecondsSinceEpoch;
    final anotacao = AnotacaoPostit(
      id: null,
      scanId: widget.scanId!,
      imagemId: widget.imagemId!,
      u: u,
      v: v,
      texto: '',
      createdAt: now,
      updatedAt: now,
    );

    try {
      final id = await ScanDatabase.insertAnotacao(anotacao);
      final anotacaoComId = anotacao.copyWith(id: id);
      if (!mounted) return;
      setState(() {
        _anotacoes.add(anotacaoComId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anotação colada com sucesso no livro!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível guardar a anotação.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    final previewPortraitSize = Size(previewSize.height, previewSize.width);
    final scaleW = layoutSize.width / previewPortraitSize.width;
    final scaleH = layoutSize.height / previewPortraitSize.height;
    final scale = scaleW < scaleH ? scaleW : scaleH;
    final offsetX = (layoutSize.width - previewPortraitSize.width * scale) / 2;
    final offsetY =
        (layoutSize.height - previewPortraitSize.height * scale) / 2;
    final paint = Paint()
      ..color = Colors.green.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final path = Path();
    for (var i = 0; i < corners.length; i++) {
      final p = Offset(
        offsetX + corners[i].dx * scale,
        offsetY + corners[i].dy * scale,
      );
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

List<Offset> _projectCornersToScreen(
  List<Offset> corners,
  Size previewSize,
  Size layoutSize,
) {
  final previewPortraitSize = Size(previewSize.height, previewSize.width);
  final scaleW = layoutSize.width / previewPortraitSize.width;
  final scaleH = layoutSize.height / previewPortraitSize.height;
  final scale = scaleW < scaleH ? scaleW : scaleH;
  final offsetX = (layoutSize.width - previewPortraitSize.width * scale) / 2;
  final offsetY = (layoutSize.height - previewPortraitSize.height * scale) / 2;

  return corners
      .map(
        (c) => Offset(
          offsetX + c.dx * scale,
          offsetY + c.dy * scale,
        ),
      )
      .toList();
}

bool _isPointInsidePolygon(Offset p, List<Offset> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].dx;
    final yi = polygon[i].dy;
    final xj = polygon[j].dx;
    final yj = polygon[j].dy;

    final intersect = ((yi > p.dy) != (yj > p.dy)) &&
        (p.dx <
            (xj - xi) * (p.dy - yi) / ((yj - yi) != 0 ? (yj - yi) : 1e-6) +
                xi);
    if (intersect) inside = !inside;
  }
  return inside;
}
