import 'dart:io';

import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../models/imagem_page.dart';
import 'scan_database.dart';

/// Resultado de um match AR: identificador do target e cantos no frame para overlay.
class ArMatchResult {
  /// Identificador do target (caminho do ficheiro da imagem).
  final String targetId;

  /// Cantos do retângulo no frame da câmera (ordem: topLeft, topRight, bottomRight, bottomLeft).
  final List<Offset> corners;

  const ArMatchResult({required this.targetId, required this.corners});
}

/// Serviço de RA baseado em OpenCV: carrega imagens-alvo, extrai descritores ORB
/// e faz matching em frames da câmera, devolvendo homografia para overlay.
class ArOpencvService {
  ArOpencvService(this._targetPaths) {
    if (_targetPaths.isEmpty) return;
    _orb = cv.ORB.create(nFeatures: 1500);
    _matcher = cv.BFMatcher.create(type: cv.NORM_HAMMING, crossCheck: false);
  }

  final List<String> _targetPaths;
  cv.ORB? _orb;
  cv.BFMatcher? _matcher;

  /// Por target: (caminho, keypoints, descriptors, width, height).
  final List<_TargetData> _targets = [];

  static const int _minMatchesHomography = 10;
  static const double _ratioThreshold = 0.75;

  /// Devolve os caminhos das imagens a usar como targets na sessão AR.
  /// Filtra por estado_target == 'sucesso', eh_pagina == true e ficheiro existe.
  /// Se [imagemId] for passado: essa imagem + 3 antes e 3 depois (máx. 10).
  /// Caso contrário: primeiras 5 (máx. 10).
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

  /// Inicializa os targets: carrega imagens e extrai keypoints/descritores ORB.
  /// Deve ser chamado antes de [matchFrame].
  Future<void> init() async {
    if (_orb == null || _matcher == null) return;
    for (final path in _targetPaths) {
      try {
        final img = cv.imread(path, flags: cv.IMREAD_GRAYSCALE);
        if (img.isEmpty) {
          img.dispose();
          continue;
        }
        final mask = cv.Mat.empty();
        final (kp, desc) = _orb!.detectAndCompute(img, mask);
        mask.dispose();
        if (kp.length < _minMatchesHomography || desc.isEmpty) {
          img.dispose();
          kp.dispose();
          desc.dispose();
          continue;
        }
        _targets.add(_TargetData(
          path: path,
          keypoints: kp,
          descriptors: desc,
          width: img.cols,
          height: img.rows,
        ));
        img.dispose();
      } catch (_) {
        // ignorar target que não carregou
      }
    }
  }

  /// Procura um target no frame. Retorna o primeiro match válido com homografia.
  /// [frameBgr] deve ser Mat BGR (3 canais) da câmera.
  ArMatchResult? matchFrame(cv.Mat frameBgr) {
    if (_orb == null || _matcher == null || _targets.isEmpty) return null;
    if (frameBgr.isEmpty) return null;

    cv.Mat? gray;
    try {
      if (frameBgr.channels == 3) {
        gray = cv.cvtColor(frameBgr, cv.COLOR_BGR2GRAY);
      } else {
        gray = frameBgr.clone();
      }
      final mask = cv.Mat.empty();
      final (frameKp, frameDesc) = _orb!.detectAndCompute(gray, mask);
      mask.dispose();
      gray.dispose();
      if (frameKp.length < _minMatchesHomography || frameDesc.isEmpty) {
        frameKp.dispose();
        frameDesc.dispose();
        return null;
      }

      for (final t in _targets) {
        final result = _matchOne(
          frameKp: frameKp,
          frameDesc: frameDesc,
          target: t,
        );
        if (result != null) {
          frameKp.dispose();
          frameDesc.dispose();
          return result;
        }
      }
      frameKp.dispose();
      frameDesc.dispose();
    } catch (_) {
      gray?.dispose();
    }
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
      knn.dispose();
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
      trainPts.dispose();
      queryPts.dispose();

      final H = cv.findHomography(
        srcMat,
        dstMat,
        method: 0,
        ransacReprojThreshold: 5,
      );
      srcMat.dispose();
      dstMat.dispose();
      if (H.isEmpty) {
        H.dispose();
        return null;
      }

      final cornersTarget = cv.VecPoint2f.fromList([
        cv.Point2f(0, 0),
        cv.Point2f(target.width.toDouble(), 0),
        cv.Point2f(target.width.toDouble(), target.height.toDouble()),
        cv.Point2f(0, target.height.toDouble()),
      ]);
      final cornersMat = cv.Mat.fromVec(cornersTarget);
      final sceneCorners = cv.perspectiveTransform(cornersMat, H);
      cornersTarget.dispose();
      cornersMat.dispose();
      H.dispose();

      final cornersVec = cv.VecPoint2f.fromMat(sceneCorners);
      final corners = List.generate(
        cornersVec.length,
        (i) => Offset(cornersVec[i].x, cornersVec[i].y),
      );
      cornersVec.dispose();
      sceneCorners.dispose();

      return ArMatchResult(targetId: target.path, corners: corners);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    for (final t in _targets) {
      t.keypoints.dispose();
      t.descriptors.dispose();
    }
    _targets.clear();
    _orb?.dispose();
    _orb = null;
    _matcher?.dispose();
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
