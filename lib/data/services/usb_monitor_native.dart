import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

class UsbMonitorService {
  Timer? _timer;
  void Function()? _stop;
  Pointer<Uint8> Function()? _poll;
  void Function(Pointer<Uint8>)? _free;
  void Function(String)? _onFlag;

  Future<void> start(void Function(String) onFlag) async {
    if (_timer != null) return;
    _onFlag = onFlag;
    if (!Platform.isWindows) {
      onFlag('USB monitoring unavailable on this platform.');
      return;
    }
    try {
      final directory = File(Platform.resolvedExecutable).parent.path;
      final library = DynamicLibrary.open('$directory/usb_monitor.dll');
      final start = library.lookupFunction<Uint32 Function(), int Function()>(
        'usb_monitor_start',
      );
      _stop = library.lookupFunction<Void Function(), void Function()>(
        'usb_monitor_stop',
      );
      _poll = library
          .lookupFunction<Pointer<Uint8> Function(), Pointer<Uint8> Function()>(
            'usb_monitor_poll',
          );
      _free = library
          .lookupFunction<
            Void Function(Pointer<Uint8>),
            void Function(Pointer<Uint8>)
          >('usb_monitor_free');
      final result = start();
      if (result != 0) {
        throw StateError('Windows notification registration: $result');
      }
      _timer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => _drain(),
      );
    } catch (_) {
      onFlag('USB monitoring unavailable: native monitor could not start.');
    }
  }

  void _drain() {
    for (var i = 0; i < 256; i++) {
      final pointer = _poll?.call();
      if (pointer == null || pointer == nullptr) break;
      try {
        var length = 0;
        while (length < 65536 && pointer[length] != 0) {
          length++;
        }
        final event =
            jsonDecode(utf8.decode(pointer.asTypedList(length))) as Map;
        if (event['kind'] == 'overflow') {
          _onFlag?.call(
            'USB monitoring event buffer overflow; some events were lost.',
          );
        } else if (event['kind'] == 'attached') {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(
            event['timestampMs'] as int,
          ).toUtc();
          _onFlag?.call(
            'USB device connected at ${timestamp.toIso8601String()}: ${event['deviceId']}. Officer review required.',
          );
        }
      } catch (_) {
        _onFlag?.call('USB monitoring returned an unreadable event.');
      } finally {
        _free?.call(pointer);
      }
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _stop?.call();
    _stop = null;
    _drain();
    _onFlag = null;
  }
}
