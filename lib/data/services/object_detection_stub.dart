typedef EvidenceCallback =
    void Function({
      required String evidenceType,
      double? confidence,
      required String details,
      required DateTime capturedAt,
    });

class ObjectDetectionService {
  Future<void> start(
    void Function(String) onFlag, {
    void Function(String)? onStatus,
    EvidenceCallback? onEvidence,
    String? referencePhotoPath,
    int? durationSeconds,
  }) async {
    onStatus?.call('Unavailable');
    onFlag('Object detection unavailable on this platform.');
  }

  void detach() {}

  Future<void> stop() async {}
}
