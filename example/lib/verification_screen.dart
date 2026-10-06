import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:edgeid_secure/edgeid_secure.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'camera_setup.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late final EdgeIDSecure _edge;
  CameraController? _controller;
  bool _ready = false;
  bool _processing = false;
  String _status = '';
  Color _statusColor = Colors.white;
  CameraImage? _latestImage;

  String? _scannedQrPayload;
  bool _showScanner = false;

  @override
  void initState() {
    super.initState();
    _edge = EdgeIDSecure();
    _init();
  }

  Future<void> _init() async {
    try {
      await _edge.initialize();
      if (cameras.isNotEmpty) {
        final front = cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        _controller = CameraController(
          front,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
        await _controller!.startImageStream(_onImage);
      }
      setState(() => _ready = true);
    } catch (e) {
      setState(() {
        _status = 'Init error: $e';
        _statusColor = Colors.red;
        _ready = true;
      });
    }
  }

  void _onImage(CameraImage image) {
    _latestImage = image;
  }

  Future<void> _scanQr() async {
    setState(() => _showScanner = true);
  }

  void _onQrDetected(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode != null && barcode.rawValue != null) {
      setState(() {
        _scannedQrPayload = barcode.rawValue;
        _showScanner = false;
      });
    }
  }

  Future<void> _verify() async {
    if (!_ready || _processing || _latestImage == null) return;
    if (_scannedQrPayload == null) {
      setState(() {
        _status = 'Please scan a Fayda QR first';
        _statusColor = Colors.orange;
      });
      return;
    }

    setState(() {
      _processing = true;
      _status = 'Verifying...';
      _statusColor = Colors.orange;
    });

    try {
      final result = await _edge.verifyOffline(
        qrPayload: _scannedQrPayload!,
        cameraImage: _latestImage!,
      );

      setState(() {
        if (result.verified) {
          _status = 'Identity verified ✅ (score: ${result.matchScore.toStringAsFixed(2)})';
          _statusColor = Colors.green;
        } else {
          _status = result.error ?? 'Verification failed ❌';
          _statusColor = Colors.red;
        }
        _processing = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _statusColor = Colors.red;
        _processing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _edge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showScanner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan Fayda QR')),
        body: MobileScanner(
          onDetect: _onQrDetected,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('EdgeID-Secure Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_controller != null && _controller!.value.isInitialized)
              SizedBox(
                width: 300,
                height: 300,
                child: CameraPreview(_controller!),
              ),
            const SizedBox(height: 20),
            Text(_status, style: TextStyle(color: _statusColor, fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _scanQr,
                  child: const Text('Scan QR'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _ready && !_processing ? _verify : null,
                  child: const Text('Verify Now'),
                ),
              ],
            ),
            if (_scannedQrPayload != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('QR ready', style: TextStyle(color: Colors.green)),
              ),
          ],
        ),
      ),
    );
  }
}