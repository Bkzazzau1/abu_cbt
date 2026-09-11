import 'dart:io';

Future<String?> resolveLocalIpv4Address() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );

    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final ip = address.address.trim();
        if (ip.isEmpty) continue;
        if (ip.startsWith('169.254.')) continue;
        return ip;
      }
    }
  } catch (_) {
    // Ignore and fallback to null.
  }
  return null;
}
