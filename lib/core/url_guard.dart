/// SSRF-style guard: only public http(s) hosts. No dart:io (web-safe).
bool isSafePublicUrl(Uri u) {
  if (u.scheme != 'http' && u.scheme != 'https') return false;
  final h = u.host.toLowerCase();
  if (h.isEmpty) return false;
  if (h == 'localhost' ||
      h.endsWith('.localhost') ||
      h.endsWith('.local') ||
      h.endsWith('.internal')) {
    return false;
  }
  if (h.contains(':')) {
    // IPv6 literal: block loopback, unspecified, unique-local, link-local.
    return !(h == '::' ||
        h == '::1' ||
        h.startsWith('fc') ||
        h.startsWith('fd') ||
        h.startsWith('fe80'));
  }
  final m = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$')
      .firstMatch(h);
  if (m != null) {
    final o = [for (var i = 1; i <= 4; i++) int.parse(m.group(i)!)];
    if (o.any((x) => x > 255)) return false;
    if (o[0] == 0 || o[0] == 10 || o[0] == 127) return false;
    if (o[0] == 169 && o[1] == 254) return false;
    if (o[0] == 172 && o[1] >= 16 && o[1] <= 31) return false;
    if (o[0] == 192 && o[1] == 168) return false;
  }
  return true;
}
