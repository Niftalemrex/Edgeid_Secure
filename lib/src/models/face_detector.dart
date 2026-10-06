import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class DetectedFace {
  final int boxLeft, boxTop, boxWidth, boxHeight;
  final img.Point leftEye, rightEye, nose, mouthLeft, mouthRight;

  DetectedFace({
    required this.boxLeft, required this.boxTop,
    required this.boxWidth, required this.boxHeight,
    required this.leftEye, required this.rightEye,
    required this.nose, required this.mouthLeft, required this.mouthRight,
  });
}

class FaceDetector {
  late Interpreter? _interpreter;
  bool _useMock = false;

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/face_det_short.tflite');
    } catch (_) {
      _useMock = true;
    }
  }

  Future<List<DetectedFace>> detect(img.Image image) async {
    if (_useMock) {
      // Mock fallback (covers the whole image)
      return [DetectedFace(
        boxLeft: 0, boxTop: 0, boxWidth: image.width, boxHeight: image.height,
        leftEye: img.Point(image.width ~/ 3, image.height ~/ 3),
        rightEye: img.Point(2 * image.width ~/ 3, image.height ~/ 3),
        nose: img.Point(image.width ~/ 2, image.height ~/ 2),
        mouthLeft: img.Point(image.width ~/ 3, 2 * image.height ~/ 3),
        mouthRight: img.Point(2 * image.width ~/ 3, 2 * image.height ~/ 3),
      )];
    }

    // Real inference (pseudo‑code – adjust to your model’s output)
    final input = _preprocess(image);
    final output = List.filled(1, Float32List(896)); // example: [boxes, keypoints]
    _interpreter!.run(input, output);
    // Parse output into List<DetectedFace> – this depends on your model format.
    return _parseOutput(output);
  }

  Float32List _preprocess(img.Image image) {
    // Resize to model input size (e.g., 128x128) and normalise
    final resized = img.copyResize(image, width: 128, height: 128);
    final input = Float32List(1 * 128 * 128 * 3);
    int idx = 0;
    for (int y = 0; y < 128; y++) {
      for (int x = 0; x < 128; x++) {
        final pixel = resized.getPixel(x, y);
        input[idx++] = (pixel.r / 255.0 - 0.5) / 0.5;
        input[idx++] = (pixel.g / 255.0 - 0.5) / 0.5;
        input[idx++] = (pixel.b / 255.0 - 0.5) / 0.5;
      }
    }
    return input;
  }

  List<DetectedFace> _parseOutput(List output) {
    // Implement based on your model’s output format
    return [];
  }
}