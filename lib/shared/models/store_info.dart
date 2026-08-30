import 'package:flutter/material.dart';

/// Store-level settings, read from the storefront's `tenants` record.
@immutable
class StoreInfo {
  const StoreInfo({
    required this.id,
    required this.slug,
    required this.label,
    required this.brandColor,
    required this.currency,
    this.slogan,
    this.logoUrl,
    this.country,
    this.whatsapp,
    this.email,
    this.instagram,
    this.facebook,
    this.tiktok,
    this.showStock = false,
    this.hideOutOfStock = false,
    this.taxRate = 0,
    this.pricesIncludeTax = true,
    this.privacyPolicy,
    this.termsConditions,
    this.aboutUs,
    this.showBringusBranding = true,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) => StoreInfo(
    id: json['id'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    label: _text(json['label'] ?? json['store_label']) ?? 'رونق | RAWNQ',
    brandColor: _text(json['brandColor'] ?? json['brand_color']) ?? '#7c3918',
    currency: _text(json['currency']) ?? 'ILS',
    slogan: _text(
      json['slogan'] ?? json['store_slogan_ar'] ?? json['store_slogan'],
    ),
    logoUrl: _text(json['logoUrl'] ?? json['store_logo']),
    country: _text(json['country']),
    whatsapp: _text(json['whatsapp'] ?? json['store_whatsapp']),
    email: _text(json['email'] ?? json['store_email']),
    instagram: _text(json['instagram'] ?? _social(json, 'instagram')),
    facebook: _text(json['facebook'] ?? _social(json, 'facebook')),
    tiktok: _text(json['tiktok'] ?? _social(json, 'tiktok')),
    showStock:
        json['showStock'] as bool? ??
        json['show_stock_to_mobile'] as bool? ??
        false,
    hideOutOfStock:
        json['hideOutOfStock'] as bool? ??
        json['hide_out_of_stock_when_stock_hidden'] as bool? ??
        false,
    taxRate: (json['taxRate'] ?? json['tax_rate'] as num?)?.toDouble() ?? 0,
    pricesIncludeTax:
        json['pricesIncludeTax'] as bool? ??
        json['prices_include_tax'] as bool? ??
        true,
    privacyPolicy: _text(json['privacyPolicy'] ?? json['privacy_policy_ar']),
    termsConditions: _text(
      json['termsConditions'] ?? json['terms_conditions_ar'],
    ),
    aboutUs: _text(json['aboutUs'] ?? json['about_us_ar']),
    showBringusBranding:
        json['showBringusBranding'] as bool? ??
        json['show_bringus_branding'] as bool? ??
        true,
  );

  final String id;
  final String slug;
  final String label;
  final String brandColor;
  final String currency;
  final String? slogan;
  final String? logoUrl;
  final String? country;
  final String? whatsapp;
  final String? email;
  final String? instagram;
  final String? facebook;
  final String? tiktok;

  /// The live store sets this false, so the app shows availability as a
  /// binary state rather than printing stock counts.
  final bool showStock;
  final bool hideOutOfStock;
  final double taxRate;
  final bool pricesIncludeTax;
  final String? privacyPolicy;
  final String? termsConditions;
  final String? aboutUs;
  final bool showBringusBranding;

  /// Digits-only WhatsApp number suitable for a `wa.me` link.
  String? get whatsappDigits {
    final raw = whatsapp;
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : digits;
  }

  bool get hasPrivacyPolicy => (privacyPolicy ?? '').trim().isNotEmpty;
  bool get hasTermsConditions => (termsConditions ?? '').trim().isNotEmpty;
  bool get hasAboutUs => (aboutUs ?? '').trim().isNotEmpty;

  static String? _social(Map<String, dynamic> json, String key) {
    final links = json['social_links'];
    if (links is Map) return links[key] as String?;
    return null;
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
