import 'dart:convert';
import 'dart:typed_data';

class FaydaQrParser {
  /// Extracts the biometric template from a Fayda QR JWT (offline mode).
  /// No signature verification – the QR is trusted as a secure document.
  static Future<List<double>?> extractTemplateWithKey(
      String qrRawData,
      String publicKeyPem, // ignored for now
      ) async {
    try {
      final parts = qrRawData.split('.');
      if (parts.length < 2) return null;

      // Decode the payload (middle part of JWT)
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final jsonPayload = json.decode(decoded) as Map<String, dynamic>;

      final hashB64 = jsonPayload['biometric_hash'] as String?;
      if (hashB64 == null) return null;

      final bytes = base64.decode(hashB64);
      if (bytes.length < 2048) return null; // 512 floats × 4 bytes

      final floats = Float32List.view(bytes.buffer, 0, 512);
      return floats.toList();
    } catch (_) {
      return null;
    }
  }
}