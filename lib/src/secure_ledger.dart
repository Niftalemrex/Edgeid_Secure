import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SecureLedger {
  static const _boxName = 'verification_log';
  static late Box _box;
  static final _storage = FlutterSecureStorage();

  static Future<void> initialize() async {
    await Hive.initFlutter();

    String? key = await _storage.read(key: 'ledger_key');
    if (key == null) {
      final newKey = base64Encode(Hive.generateSecureKey());
      await _storage.write(key: 'ledger_key', value: newKey);
      key = newKey;
    }
    _box = await Hive.openBox(
      _boxName,
      encryptionCipher: HiveAesCipher(base64Decode(key)),
    );
  }

  static Future<void> log({
    required String citizenId,
    required bool livenessPass,
    required double matchScore,
    required bool verified,
  }) async {
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'citizenId': citizenId,
      'liveness': livenessPass,
      'matchScore': matchScore,
      'verified': verified,
      'synced': false,
    };
    final jsonStr = json.encode(entry);
    final hmac = await _computeHmac(jsonStr);
    _box.add({'data': jsonStr, 'hmac': hmac});
  }

  static Future<String> _computeHmac(String data) async {
    final deviceKey = await _storage.read(key: 'device_hmac_key') ??
        (await _generateAndStoreDeviceKey());
    final keyBytes = base64.decode(deviceKey);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(utf8.encode(data));
    return base64.encode(digest.bytes);
  }

  static Future<String> _generateAndStoreDeviceKey() async {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final key = base64.encode(bytes);
    await _storage.write(key: 'device_hmac_key', value: key);
    return key;
  }

  static List<Map<String, dynamic>> getUnsynced() {
    return _box.values
        .where((e) => (e as Map)['synced'] == false)
        .cast<Map<String, dynamic>>()
        .toList();
  }
}