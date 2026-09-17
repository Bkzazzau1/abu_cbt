enum FingerprintResult { matched, notMatched, unavailable }

/// Implement this boundary with the reader vendor's SDK for real verification.
abstract interface class FingerprintReader {
  Future<FingerprintResult> verify(String registrationNumber);
}

/// UI demonstration only: no biometric sample is captured or stored.
///
/// Two sample accounts deliberately exercise the exception paths so the ABU
/// presentation can demonstrate controlled invigilator review without changing
/// production authentication logic:
/// - ABU/PHY/003 -> fingerprint not matched
/// - ABU/CHM/007 -> reader unavailable
/// All other demo candidates match by default.
class DemoFingerprintReader implements FingerprintReader {
  DemoFingerprintReader({this.useScenarioOutcomes = true});

  final bool useScenarioOutcomes;

  /// Existing override used by tests or a custom demo harness. Any non-matched
  /// value takes priority over the built-in scenario table below.
  FingerprintResult outcome = FingerprintResult.matched;

  @override
  Future<FingerprintResult> verify(String registrationNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    if (outcome != FingerprintResult.matched) return outcome;
    if (!useScenarioOutcomes) return FingerprintResult.matched;

    switch (registrationNumber.trim().toUpperCase()) {
      case 'ABU/PHY/003':
        return FingerprintResult.notMatched;
      case 'ABU/CHM/007':
        return FingerprintResult.unavailable;
      default:
        return FingerprintResult.matched;
    }
  }
}
