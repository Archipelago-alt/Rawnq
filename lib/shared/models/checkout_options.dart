import 'package:flutter/material.dart';

/// A delivery destination the shop actually serves. Read from the
/// storefront's `delivery_locations`; RAWNQ configures exactly one (غزة, 0 ₪).
@immutable
class DeliveryLocation {
  const DeliveryLocation({
    required this.id,
    required this.name,
    required this.price,
    this.type = 'local',
  });

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) => DeliveryLocation(
        id: json['id'] as String? ?? '',
        name: _pick(json['name_ar'], json['name']) ?? '',
        price: _toDouble(json['price'] ?? json['delivery_price']),
        type: (json['type'] ?? json['delivery_type'] ?? 'local') as String,
      );

  final String id;
  final String name;
  final double price;
  final String type;

  bool get isFree => price <= 0;
}

/// How the shopper intends to pay. These are the shop's own configured
/// methods; none of them is an integrated gateway, so the app never attempts
/// to process a payment — it passes the choice to the shop.
@immutable
class StorePaymentMethod {
  const StorePaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    this.iconUrl,
  });

  factory StorePaymentMethod.fromJson(Map<String, dynamic> json) => StorePaymentMethod(
        id: json['id'] as String? ?? '',
        name: _pick(json['method_name_ar'], json['name'] ?? json['method_name']) ?? '',
        type: (json['type'] ?? json['method_type'] ?? 'other') as String,
        iconUrl: _pick(json['iconUrl'], json['icon_url']),
      );

  final String id;
  final String name;
  final String type;
  final String? iconUrl;

  bool get isCashOnDelivery => type == 'cod';
  bool get isPickup => type == 'pickup';
}

String? _pick(Object? a, Object? b) {
  for (final value in <Object?>[a, b]) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
