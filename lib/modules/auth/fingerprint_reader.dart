enum FingerprintResult { matched, notMatched, unavailable }

/// Implement this boundary with the reader vendor's SDK for real verification.
abstract interface class FingerprintReader {
  Future<FingerprintResult> verify(String registrationNumber);
}

/// UI demonstration only: no biometric sample is captured or stored.
class DemoFingerprintReader implements FingerprintReader {
  FingerprintResult outcome = FingerprintResult.matched;
  @override
  Future<FingerprintResult> verify(String registrationNumber) async {
    final result = outcome;
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return result;
  }
}
