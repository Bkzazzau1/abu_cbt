enum FingerprintResult { matched, notMatched, unavailable }

/// Implement this boundary with the reader vendor's SDK for real verification.
abstract interface class FingerprintReader {
  Future<FingerprintResult> verify(String registrationNumber);
}

/// UI demonstration only: no biometric sample is captured or stored.
///
/// ABU/CSC/008 deliberately exercises the exception path so the ABU
/// presentation can demonstrate fingerprint failure -> invigilator manual
/// identity review -> audited approval/rejection while remaining inside the
/// same CSC 305 attendance and General Exam Report dataset.
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
      case 'ABU/CSC/008':
        return FingerprintResult.notMatched;
      default:
        return FingerprintResult.matched;
    }
  }
}
