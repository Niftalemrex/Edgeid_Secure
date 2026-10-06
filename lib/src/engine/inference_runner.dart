import 'package:camera/camera.dart';
import 'preprocessor.dart';
import '../models/face_detector.dart';
import '../models/liveness_model.dart';
import '../models/embedder_model.dart';
import '../matcher.dart';
import '../types.dart';

class InferenceRunner {
  late FaceDetector _detector;
  late LivenessModel _liveness;
  late EmbedderModel _embedder;

  Future<void> initialize() async {
    _detector = FaceDetector();
    _liveness = LivenessModel();
    _embedder = EmbedderModel();
    await _detector.initialize();
    await _liveness.initialize();
    await _embedder.initialize();
  }

  Future<BiometricResult> process(CameraImage cameraImage, List<double> template) async {
    // 1. Convert YUV → RGB
    final image = Preprocessor.convertYUV420ToImage(cameraImage);

    // 2. Detect face(s)
    final faces = await _detector.detect(image);
    if (faces.isEmpty) {
      return BiometricResult(isLive: false, matchScore: 0.0, verified: false);
    }
    final face = faces.first;

    // 3. Align face
    final aligned = Preprocessor.alignFace(image, face);

    // 4. Liveness
    final isLive = await _liveness.predict(aligned);
    if (!isLive) {
      return BiometricResult(isLive: false, matchScore: 0.0, verified: false);
    }

    // 5. Extract embedding
    final liveEmbedding = await _embedder.extract(aligned);

    // 6. Match
    final score = cosineSimilarity(liveEmbedding, template);
    final verified = score >= 0.65; // threshold

    return BiometricResult(
      isLive: true,
      matchScore: score,
      verified: verified,
      citizenId: null, // not extracted here; can be passed from QR if needed
    );
  }
}