import 'dart:typed_data';
import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../engine/preprocessor.dart';

class EmbedderModel {
  late Interpreter? _interpreter;
  bool _useMock = false;
  final int _embeddingSize = 512;

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/embedder.tflite');
    } catch (_) {
      _useMock = true;
    }
  }

  Future<List<double>> extract(img.Image alignedFace) async {
    if (_useMock) {
      final rng = Random(42);
      return List.generate(_embeddingSize, (_) => rng.nextDouble());
    }

    final input = Preprocessor.imageToNormalizedTensor(alignedFace, 112, 112, 0.5, 0.5);
    final inputShape = [1, 112, 112, 3];
    final output = List.filled(1, Float32List(_embeddingSize));
    _interpreter!.run(input.reshape(inputShape), output);
    return List<double>.from(output[0] as List<double>);
  }
}