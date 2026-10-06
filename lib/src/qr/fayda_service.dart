import 'dart:typed_data';
import 'fayda_qr_parser.dart';

abstract class FaydaService {
  Future<List<double>?> extractTemplate(String qrRawData);
}

class MockFaydaService implements FaydaService {
  @override
  Future<List<double>?> extractTemplate(String qrRawData) async {
    return List<double>.filled(512, 0.5);
  }
}

class RealFaydaService implements FaydaService {
  final String publicKeyPem;

  RealFaydaService(this.publicKeyPem);

  @override
  Future<List<double>?> extractTemplate(String qrRawData) async {
    return FaydaQrParser.extractTemplateWithKey(qrRawData, publicKeyPem);
  }
}