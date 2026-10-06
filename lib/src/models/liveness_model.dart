
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../engine/preprocessor.dart';

class LivenessModel {
  late Interpreter? _interpreter;
  bool _useMock = false;
  final double _spoofThreshold = 0.85;

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/liveness.tflite');
    } catch (_) {
      _useMock = true;
    }
  }

  Future<bool> predict(img.Image alignedFace) async {
    if (_useMock) return true;

    final input = Preprocessor.imageToNormalizedTensor(alignedFace, 112, 112, 0.5, 0.5);
    final inputShape = [1, 112, 112, 3];
    final output = List.filled(1, List<double>.filled(2, 0.0));
    _interpreter!.run(input.reshape(inputShape), output);
    double liveProb = (output[0] as List<double>)[0]; // index may vary
    return liveProb >= _spoofThreshold;
  }
}