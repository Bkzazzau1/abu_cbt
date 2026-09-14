class ObjectDetectionService {
  Future<void> start(
    void Function(String) onFlag, {
    void Function(String)? onStatus,
  }) async {
    onStatus?.call('Unavailable');
    onFlag('Object detection unavailable on this platform.');
  }

  Future<void> stop() async {}
}
