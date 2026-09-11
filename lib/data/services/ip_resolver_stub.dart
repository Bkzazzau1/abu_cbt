Future<String?> resolveLocalIpv4Address() async {
  final host = Uri.base.host.trim();
  if (host.isEmpty) {
    return null;
  }
  return host;
}
