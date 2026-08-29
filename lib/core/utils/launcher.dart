import 'package:url_launcher/url_launcher.dart';

/// Opens external links, refusing anything that is not an expected scheme.
///
/// Product data comes from a remote API, so a URL from that data is never
/// handed to the platform without checking its scheme first.
class ExternalLauncher {
  const ExternalLauncher._();

  static const Set<String> _allowedSchemes = <String>{'https', 'tel', 'mailto'};

  /// Returns false when the link is unsafe or no app can handle it.
  static Future<bool> open(Uri uri, {bool external = true}) async {
    if (!_allowedSchemes.contains(uri.scheme)) return false;
    try {
      return await launchUrl(
        uri,
        mode: external ? LaunchMode.externalApplication : LaunchMode.platformDefault,
      );
    } on Exception {
      return false;
    }
  }

  /// Validates a URL string coming from remote data before opening it.
  static Future<bool> openUrlString(String? value) async {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) return false;
    return open(uri);
  }
}
