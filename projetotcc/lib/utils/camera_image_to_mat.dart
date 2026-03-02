import 'package:camera/camera.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Converte [CameraImage] para [cv.Mat] BGR para uso com OpenCV.
/// Retorna null se o formato não for suportado ou a conversão falhar.
cv.Mat? cameraImageToMat(CameraImage image) {
  try {
    switch (image.format.group) {
      case ImageFormatGroup.jpeg:
        return _jpegToMat(image);
      case ImageFormatGroup.bgra8888:
        return _bgra8888ToMat(image);
      case ImageFormatGroup.yuv420:
        return _yuv420ToMat(image);
      default:
        return null;
    }
  } catch (_) {
    return null;
  }
}

cv.Mat? _jpegToMat(CameraImage image) {
  if (image.planes.isEmpty) return null;
  final bytes = image.planes[0].bytes;
  if (bytes.isEmpty) return null;
  final mat = cv.imdecode(bytes, cv.IMREAD_COLOR);
  if (mat.isEmpty) {
    mat.dispose();
    return null;
  }
  return mat;
}

cv.Mat? _bgra8888ToMat(CameraImage image) {
  if (image.planes.isEmpty) return null;
  final plane = image.planes[0];
  final w = image.width;
  final h = image.height;
  final stride = plane.bytesPerRow;
  if (stride < w * 4) return null;
  final bgr = <int>[];
  for (var y = 0; y < h; y++) {
    final rowStart = y * stride;
    for (var x = 0; x < w; x++) {
      final i = rowStart + x * 4;
      bgr.add(plane.bytes[i]);     // B
      bgr.add(plane.bytes[i + 1]); // G
      bgr.add(plane.bytes[i + 2]); // R (BGRA -> BGR)
    }
  }
  final mat = cv.Mat.fromList(h, w, cv.MatType.CV_8UC3, bgr);
  return mat;
}

cv.Mat? _yuv420ToMat(CameraImage image) {
  if (image.planes.length < 3) return null;
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];
  final w = image.width;
  final h = image.height;
  final yStride = yPlane.bytesPerRow;
  final uStride = uPlane.bytesPerRow;
  final vStride = vPlane.bytesPerRow;
  final bgr = <int>[];
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final yIdx = y * yStride + x;
      final uvY = y >> 1;
      final uvX = x >> 1;
      final uIdx = uvY * uStride + uvX;
      final vIdx = uvY * vStride + uvX;
      final yVal = yPlane.bytes[yIdx].toInt();
      final uVal = uPlane.bytes[uIdx].toInt() - 128;
      final vVal = vPlane.bytes[vIdx].toInt() - 128;
      final r = (yVal + (1.402 * vVal).round()).clamp(0, 255);
      final g = (yVal - (0.344 * uVal + 0.714 * vVal).round()).clamp(0, 255);
      final b = (yVal + (1.772 * uVal).round()).clamp(0, 255);
      bgr.add(b);
      bgr.add(g);
      bgr.add(r);
    }
  }
  final mat = cv.Mat.fromList(h, w, cv.MatType.CV_8UC3, bgr);
  return mat;
}
