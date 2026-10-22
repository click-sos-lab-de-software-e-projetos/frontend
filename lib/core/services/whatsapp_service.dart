import 'package:url_launcher/url_launcher.dart';

import 'geo_point.dart';

typedef UrlLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchExternal(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

class WhatsAppService {
  const WhatsAppService({UrlLauncher launcher = _launchExternal}) : _launch = launcher;

  final UrlLauncher _launch;

  /// Digits-only international number for wa.me. Brazilian numbers without a
  /// country code get `55`; numbers typed with `+` or already including `55`
  /// (12–13 digits) are kept.
  static String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (phone.trim().startsWith('+')) return digits;
    if (digits.length >= 12 && digits.startsWith('55')) return digits;
    return '55${digits.replaceFirst(RegExp(r'^0+'), '')}';
  }

  static Uri chatUri(String phone, String text) =>
      Uri.parse('https://wa.me/${normalizePhone(phone)}?text=${Uri.encodeComponent(text)}');

  static String mapsLink(GeoPoint p) => 'https://maps.google.com/?q=${p.lat},${p.lng}';

  Future<bool> open(String phone, String text) => _launch(chatUri(phone, text));
}
