/// Build-time configuration for the RAWNQ app.
///
/// Every value is supplied through `--dart-define` (or
/// `--dart-define-from-file`). Nothing here is committed to source control —
/// see `.env.example` for the expected keys.
///
/// When [hasRemoteApi] is false the app reads the bundled catalogue snapshot
/// instead of the live storefront, and says so in the UI.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.tenantSlug,
  });

  /// Reads configuration from the compile-time environment.
  factory AppConfig.fromEnvironment() => const AppConfig(
        supabaseUrl: String.fromEnvironment('RAWNQ_SUPABASE_URL'),
        supabaseAnonKey: String.fromEnvironment('RAWNQ_SUPABASE_ANON_KEY'),
        tenantSlug: String.fromEnvironment(
          'RAWNQ_TENANT_SLUG',
          defaultValue: 'rawnqgaza',
        ),
      );

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String tenantSlug;

  /// True only when a complete, usable live-API configuration was provided.
  bool get hasRemoteApi {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) return false;
    final uri = Uri.tryParse(supabaseUrl);
    return uri != null && uri.isScheme('https') && uri.host.isNotEmpty;
  }

  /// Base URL of the storefront's PostgREST API.
  String get restBaseUrl => '${supabaseUrl.replaceAll(RegExp(r'/+$'), '')}/rest/v1';
}

/// Public, non-secret facts about the storefront the app is built for.
///
/// These are published on every page of the live site; they are not
/// credentials. Sourced from `docs/website-analysis.md`.
class StorefrontLinks {
  const StorefrontLinks._();

  static const String websiteBase = 'https://bring-us.app';
  static const String storeSlug = 'rawnqgaza';

  static Uri get storefront => Uri.parse('$websiteBase/$storeSlug/mobile');
  static Uri get storefrontCart => Uri.parse('$websiteBase/$storeSlug/mobile/cart');
  static Uri get privacyPolicy => Uri.parse('$websiteBase/$storeSlug/mobile/privacy');
  static Uri get termsConditions => Uri.parse('$websiteBase/$storeSlug/mobile/terms');
}
