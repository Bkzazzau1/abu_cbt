class UsbMonitorService {
  Future<void> start(void Function(String) onFlag) async {
    onFlag('USB monitoring unavailable on this platform.');
  }

  void stop() {}
}
