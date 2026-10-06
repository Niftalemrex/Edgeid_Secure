/// Contains all data classes shared across the SDK.
class EdgeIDResult {
  final bool isLive;
  final double matchScore;
  final bool verified;
  final String? error;
  final String? citizenId;   // from the QR

  EdgeIDResult({
    required this.isLive,
    required this.matchScore,
    required this.verified,
    this.error,
    this.citizenId,
  });

  factory EdgeIDResult.error(String message) => EdgeIDResult(
    isLive: false,
    matchScore: 0.0,
    verified: false,
    error: message,
  );
}

/// Low‑level result from the biometric engine isolate.
class BiometricResult {
  final bool isLive;
  final double matchScore;
  final bool verified;
  final String? citizenId;

  BiometricResult({
    required this.isLive,
    required this.matchScore,
    required this.verified,
    this.citizenId,
  });
}