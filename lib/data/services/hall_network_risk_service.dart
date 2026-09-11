import 'ip_resolver_stub.dart' if (dart.library.io) 'ip_resolver_io.dart';

class HallIpRiskAssessment {
  HallIpRiskAssessment({
    required this.ipAddress,
    required this.expectedRanges,
    required this.matchesExpectedRange,
  });

  final String ipAddress;
  final List<String> expectedRanges;
  final bool matchesExpectedRange;

  bool get hasIp => ipAddress.trim().isNotEmpty;
  bool get hasExpectedRange => expectedRanges.isNotEmpty;
  String get expectedRangeLabel =>
      expectedRanges.isEmpty ? 'Unconfigured' : expectedRanges.join(' or ');
}

class HallNetworkRiskService {
  HallNetworkRiskService._();

  // Example hall API ranges (mock policy baseline).
  static const Map<String, List<String>> _hallIpPrefixes = {
    'Hall A': ['10.10.1.0/24', '192.168.10.0/24'],
    'Hall B': ['10.10.2.0/24', '192.168.20.0/24'],
    'Hall C': ['10.10.3.0/24', '192.168.30.0/24'],
  };

  static Future<HallIpRiskAssessment> assess({
    required String hallName,
  }) async {
    final ip = (await resolveLocalIpv4Address())?.trim() ?? '';
    final expected = _hallIpPrefixes[hallName.trim()] ?? const <String>[];
    final matches = ip.isNotEmpty && expected.any((range) => _matchesRange(ip, range));

    return HallIpRiskAssessment(
      ipAddress: ip,
      expectedRanges: List<String>.from(expected),
      matchesExpectedRange: matches,
    );
  }

  static bool _matchesRange(String ip, String range) {
    final trimmed = range.trim();
    if (trimmed.isEmpty) return false;

    if (trimmed.contains('/')) {
      return _isIpInCidr(ip, trimmed);
    }
    return ip.startsWith(trimmed);
  }

  static bool _isIpInCidr(String ip, String cidr) {
    final parts = cidr.split('/');
    if (parts.length != 2) return false;
    final network = _ipToInt(parts[0].trim());
    final target = _ipToInt(ip.trim());
    final prefix = int.tryParse(parts[1].trim());
    if (network == null || target == null || prefix == null) return false;
    if (prefix < 0 || prefix > 32) return false;

    final mask = prefix == 0 ? 0 : ((0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF);
    return (network & mask) == (target & mask);
  }

  static int? _ipToInt(String ip) {
    final items = ip.split('.');
    if (items.length != 4) return null;

    var value = 0;
    for (final item in items) {
      final octet = int.tryParse(item);
      if (octet == null || octet < 0 || octet > 255) return null;
      value = (value << 8) | octet;
    }
    return value;
  }
}
