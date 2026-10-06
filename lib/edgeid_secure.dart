import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'src/engine/biometric_engine.dart';
import 'src/qr/fayda_service.dart';   // <-- new
import 'src/secure_ledger.dart';
import 'src/types.dart';

class EdgeIDSecure {
  final BiometricEngine _engine = BiometricEngine();
  bool _initialized = false;
  late FaydaService _faydaService;

  /// Initializes the SDK.
  /// If [useRealApi] is true, it will attempt to load the Fayda public key
  /// from assets/fayda_public_key.pem and use real JWT verification.
  /// Otherwise, it falls back to a mock service that always returns a valid template.
  Future<void> initialize({bool useRealApi = false}) async {
    await SecureLedger.initialize();
    await _engine.start();

    if (useRealApi) {
      try {
        final pem = await rootBundle.loadString('assets/fayda_public_key.pem');
        if (pem.trim().isNotEmpty) {
          _faydaService = RealFaydaService(pem.trim());
          _initialized = true;
          return;
        }
      } catch (_) {
        // Fall through to mock
      }
    }

    // Default: mock service
    _faydaService = MockFaydaService();
    _initialized = true;
  }

  Future<EdgeIDResult> verifyOffline({
    required String qrPayload,
    required CameraImage cameraImage,
  }) async {
    if (!_initialized) throw StateError('SDK not initialized');

    final template = await _faydaService.extractTemplate(qrPayload);
    if (template == null) {
      return EdgeIDResult.error('Invalid QR or signature');
    }

    final bioResult = await _engine.verify(cameraImage, template);

    await SecureLedger.log(
      citizenId: bioResult.citizenId ?? 'unknown',
      livenessPass: bioResult.isLive,
      matchScore: bioResult.matchScore,
      verified: bioResult.verified,
    );

    return EdgeIDResult(
      isLive: bioResult.isLive,
      matchScore: bioResult.matchScore,
      verified: bioResult.verified,
      citizenId: bioResult.citizenId,
    );
  }

  void dispose() => _engine.dispose();
}