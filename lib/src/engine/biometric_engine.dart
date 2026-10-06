import 'dart:isolate';
import 'package:camera/camera.dart';
import 'inference_runner.dart';
import '../types.dart';

class BiometricEngine {
  late Isolate _isolate;
  late SendPort _commandPort;
  final ReceivePort _responsePort = ReceivePort();

  Future<void> start() async {
    _isolate = await Isolate.spawn(isolateMain, _responsePort.sendPort);
    _commandPort = await _responsePort.first;
  }

  Future<BiometricResult> verify(CameraImage cameraImage, List<double> template) async {
    final responsePort = ReceivePort();
    _commandPort.send({
      'image': cameraImage,
      'template': template,
      'replyPort': responsePort.sendPort,
    });
    final result = await responsePort.first;
    return result as BiometricResult;
  }

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
  }
}

void isolateMain(SendPort initPort) async {
  final commandPort = ReceivePort();
  initPort.send(commandPort.sendPort);
  final runner = InferenceRunner();
  await runner.initialize();   // load models inside isolate

  commandPort.listen((msg) async {
    final cameraImage = msg['image'] as CameraImage;
    final template = msg['template'] as List<double>;
    final replyPort = msg['replyPort'] as SendPort;
    final result = await runner.process(cameraImage, template);
    replyPort.send(result);
  });
}