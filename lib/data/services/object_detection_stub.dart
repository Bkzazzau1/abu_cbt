class ObjectDetectionService {
  Future<void> start(
    void Function(String) onFlag, {
    void Function(String)? onStatus,
    String? referencePhotoPath,
    int? durationSeconds,
  }) async {
    onStatus?.call('Unavailable');
    onFlag('Object detection unavailable on this platform.');
  }

  Future<void> stop() async {}
}
