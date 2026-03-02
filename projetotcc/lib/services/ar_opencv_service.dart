import 'dart:io';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../models/imagem_page.dart';
import 'scan_database.dart';

class ArMatchResult {
  final String targetId;
  final List<Offset> corners;

  const ArMatchResult({required this.targetId, required this.corners});
}

class ArOpencvService {
  ArOpencvService(this._targetPaths) {
    if (_targetPaths.isEmpty) return;
    _orb = cv.ORB.create(nFeatures: 1500);
    _matcher = cv.BFMatcher.create(type: cv.NORM_HAMMING, crossCheck: false);
  }

  final List<String> _targetPaths;
  cv.ORB? _orb;
  cv.BFMatcher? _matcher;

  final List<_TargetData> _targets = [];

  static const int _minMatchesHomography = 10;
  static const double _ratioThreshold = 0.75;

  static Future<List<String>> getTargetPathsForSession(
    String scanId, {
    int? imagemId,
  }) async {
    final imagens = await ScanDatabase.getImagensForScan(scanId);
    final candidatas = imagens
        .where((e) =>
            e.estadoTarget == 'sucesso' &&
            e.ehPagina &&
            File(e.caminho).existsSync())
        .toList();
    if (candidatas.isEmpty) return [];

    List<ImagemPage> subconjunto;
    if (imagemId != null) {
      final idx = candidatas.indexWhere((e) => e.id == imagemId);
      if (idx < 0) return candidatas.take(5).map((e) => e.caminho).toList();
      final start = (idx - 3).clamp(0, candidatas.length);
      final end = (idx + 4).clamp(0, candidatas.length);
      subconjunto = candidatas.sublist(start, end);
    } else {
      subconjunto = candidatas.take(5).toList();
    }
    return subconjunto.take(10).map((e) => e.caminho).toList();
  }

  Future<void> init() async {
    if (_orb == null || _matcher == null) return;
    for (final path in _targetPaths) {
      try {
        final file = File(path);
        if (!await file.exists()) continue;

        // Usa imread nativo (agora que o pubspec foi corrigido)
        final imgColor = cv.imread(path, flags: cv.IMREAD_COLOR);
        if (imgColor.isEmpty) continue;

        // Redimensiona para evitar lentidão e OutOfMemory (OOM)
        final novaLargura = 800;
        final novaAltura = (novaLargura * imgColor.rows / imgColor.cols).toInt();
        final imgResized = cv.resize(imgColor, (novaLargura, novaAltura));
        
        final img = cv.cvtColor(imgResized, cv.COLOR_BGR2GRAY);
        
        final mask = cv.Mat.empty();
        final (kp, desc) = _orb!.detectAndCompute(img, mask);

        if (kp.length < _minMatchesHomography || desc.isEmpty) {
          continue;
        }

        _targets.add(_TargetData(
          path: path,
          keypoints: kp,
          descriptors: desc,
          width: img.cols, // Usa dimensões da imagem cinza já redimensionada
          height: img.rows,
        ));
      } catch (e) {
        debugPrint('Erro ao processar target $path: $e');
      }
    }
  }

  ArMatchResult? matchFrame(cv.Mat frameBgr) {
    if (_orb == null || _matcher == null || _targets.isEmpty) return null;
    if (frameBgr.isEmpty) return null;

    try {
      cv.Mat gray;
      if (frameBgr.channels == 3) {
        gray = cv.cvtColor(frameBgr, cv.COLOR_BGR2GRAY);
      } else {
        gray = frameBgr.clone();
      }
      
      final mask = cv.Mat.empty();
      final (frameKp, frameDesc) = _orb!.detectAndCompute(gray, mask);
      
      if (frameKp.length < _minMatchesHomography || frameDesc.isEmpty) {
        return null;
      }

      for (final t in _targets) {
        final result = _matchOne(
          frameKp: frameKp,
          frameDesc: frameDesc,
          target: t,
        );
        if (result != null) {
          return result;
        }
      }
    } catch (_) {}
    
    return null;
  }

  ArMatchResult? _matchOne({
    required cv.VecKeyPoint frameKp,
    required cv.Mat frameDesc,
    required _TargetData target,
  }) {
    try {
      final knn = _matcher!.knnMatch(frameDesc, target.descriptors, 2);
      final good = <cv.DMatch>[];
      for (var i = 0; i < knn.length; i++) {
        final row = knn[i];
        if (row.length < 2) continue;
        final m = row[0];
        final n = row[1];
        if (m.distance < _ratioThreshold * n.distance) good.add(m);
      }
      
      if (good.length < _minMatchesHomography) return null;

      final trainPts = cv.VecPoint2f();
      final queryPts = cv.VecPoint2f();
      for (final m in good) {
        trainPts.add(cv.Point2f(
          target.keypoints[m.trainIdx].x,
          target.keypoints[m.trainIdx].y,
        ));
        queryPts.add(cv.Point2f(
          frameKp[m.queryIdx].x,
          frameKp[m.queryIdx].y,
        ));
      }
      
      final srcMat = cv.Mat.fromVec(trainPts);
      final dstMat = cv.Mat.fromVec(queryPts);
      
      final H = cv.findHomography(
        srcMat,
        dstMat,
        method: 0,
        ransacReprojThreshold: 5,
      );
      
      if (H.isEmpty) return null;

      final cornersTarget = cv.VecPoint2f.fromList([
        cv.Point2f(0, 0),
        cv.Point2f(target.width.toDouble(), 0),
        cv.Point2f(target.width.toDouble(), target.height.toDouble()),
        cv.Point2f(0, target.height.toDouble()),
      ]);
      
      final cornersMat = cv.Mat.fromVec(cornersTarget);
      final sceneCorners = cv.perspectiveTransform(cornersMat, H);
      final cornersVec = cv.VecPoint2f.fromMat(sceneCorners);
      
      final corners = List.generate(
        cornersVec.length,
        (i) => Offset(cornersVec[i].x, cornersVec[i].y),
      );

      return ArMatchResult(targetId: target.path, corners: corners);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    // Deixa o Garbage Collector limpar a memória nativa
    _targets.clear();
    _orb = null;
    _matcher = null;
  }

  int get targetCount => _targets.length;
}

class _TargetData {
  final String path;
  final cv.VecKeyPoint keypoints;
  final cv.Mat descriptors;
  final int width;
  final int height;

  _TargetData({
    required this.path,
    required this.keypoints,
    required this.descriptors,
    required this.width,
    required this.height,
  });
}