import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../models/face_detector.dart'; // for DetectedFace

class Preprocessor {
  /// Converts YUV420 CameraImage to an RGB img.Image.
  static img.Image convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final planeY = cameraImage.planes[0];
    final planeU = cameraImage.planes[1];
    final planeV = cameraImage.planes[2];

    final int yRowStride = planeY.bytesPerRow;
    final int yPixelStride = planeY.bytesPerPixel ?? 1;

    final int uvRowStride = planeU.bytesPerRow;
    final int uvPixelStride = planeU.bytesPerPixel ?? 1;

    final img.Image image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Y value
        int yIndex = y * yRowStride + x * yPixelStride;
        int yVal = planeY.bytes[yIndex] & 0xFF;

        // U and V (each sample covers 2x2 pixel block)
        int uvX = x ~/ 2;
        int uvY = y ~/ 2;
        int uvIndex = uvY * uvRowStride + uvX * uvPixelStride;
        int uVal = planeU.bytes[uvIndex] & 0xFF;
        int vVal = planeV.bytes[uvIndex] & 0xFF;

        // YUV to RGB (BT.601 full swing)
        int r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255).toInt();
        int g = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128))
            .round()
            .clamp(0, 255)
            .toInt();
        int b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255).toInt();

        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return image;
  }

  /// Aligns a face using eye coordinates to a canonical 112×112 image.
  static img.Image alignFace(img.Image src, DetectedFace face) {
    const double targetEyeDistance = 45.0;
    const double targetEyeCenterX = 112.0 / 2.0;
    const double targetLeftEyeY = 38.0;

    // Use double for all point coordinates (img.Point uses int, cast to double)
    double leftEyeX = face.leftEye.x.toDouble();
    double leftEyeY = face.leftEye.y.toDouble();
    double rightEyeX = face.rightEye.x.toDouble();
    double rightEyeY = face.rightEye.y.toDouble();

    double dx = rightEyeX - leftEyeX;
    double dy = rightEyeY - leftEyeY;
    double angle = atan2(dy, dx);
    double dist = sqrt(dx * dx + dy * dy);
    double scale = targetEyeDistance / dist;

    double cosA = cos(angle);
    double sinA = sin(angle);
    double tx = targetEyeCenterX - (leftEyeX * scale * cosA - leftEyeY * scale * sinA);
    double ty = targetLeftEyeY - (leftEyeX * scale * sinA + leftEyeY * scale * cosA);

    final img.Image aligned = img.Image(width: 112, height: 112);

    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        double srcX = (x - tx) * cosA + (y - ty) * sinA;
        double srcY = -(x - tx) * sinA + (y - ty) * cosA;
        srcX /= scale;   // double division
        srcY /= scale;

        int sx = srcX.round();
        int sy = srcY.round();
        if (sx >= 0 && sx < src.width && sy >= 0 && sy < src.height) {
          var pixel = src.getPixel(sx, sy);
          aligned.setPixel(x, y, pixel);
        }
      }
    }
    return aligned;
  }

  /// Normalizes and resizes an RGB image into a Float32List tensor.
  static Float32List imageToNormalizedTensor(
      img.Image image,
      int targetWidth,
      int targetHeight,
      double mean,
      double std,
      ) {
    final resized = img.copyResize(image, width: targetWidth, height: targetHeight);
    final int flatSize = targetWidth * targetHeight * 3;
    final Float32List tensor = Float32List(flatSize);
    int idx = 0;
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final pixel = resized.getPixel(x, y);
        // Convert int components to double explicitly
        double r = pixel.r.toDouble() / 255.0;
        double g = pixel.g.toDouble() / 255.0;
        double b = pixel.b.toDouble() / 255.0;
        tensor[idx++] = (r - mean) / std;
        tensor[idx++] = (g - mean) / std;
        tensor[idx++] = (b - mean) / std;
      }
    }
    return tensor;
  }
}