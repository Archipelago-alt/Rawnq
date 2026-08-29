import 'package:flutter/material.dart';

@immutable
class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        id: json['id'] as String? ?? '',
        name: (json['name_ar'] ?? json['name'] ?? '') as String,
        description: _text(json['description']),
        imageUrl: _text(json['imageUrl'] ?? json['image']),
        sortOrder:
            (json['sortOrder'] ?? json['sort_order'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int sortOrder;

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

@immutable
class Brand {
  const Brand({
    required this.id,
    required this.name,
    this.logoUrl,
    this.sortOrder = 0,
  });

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
    id: json['id'] as String? ?? '',
    name: (json['name_ar'] ?? json['name'] ?? '') as String,
    logoUrl: ProductCategory._text(json['logoUrl'] ?? json['logo_url']),
    sortOrder: (json['sortOrder'] ?? json['sort_order'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String name;
  final String? logoUrl;
  final int sortOrder;
}
