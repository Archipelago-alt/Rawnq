import 'package:flutter/material.dart';

/// A single purchasable option of a product — a colour, optionally in a
/// specific size. Mirrors the storefront's `product_variants` row, whose
/// options live in a JSON `attributes` object.
@immutable
class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.stock,
    this.color,
    this.colorHex,
    this.size,
    this.material,
    this.imageUrl,
    this.sortOrder = 0,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'];
    String? attr(String key) {
      if (json[key] is String) return _text(json[key]);
      if (attributes is Map) return _text(attributes[key]);
      return null;
    }

    return ProductVariant(
      id: json['id'] as String? ?? '',
      productId: (json['productId'] ?? json['product_id'] ?? '') as String,
      name:
          (json['name'] ??
                  json['variant_name_ar'] ??
                  json['variant_name'] ??
                  '')
              as String,
      price: _toDouble(json['price'] ?? json['price_1']),
      stock: _toDouble(json['stock'] ?? json['stock_quantity']),
      color: attr('color'),
      colorHex: attr('colorHex') ?? attr('color_hex'),
      size: attr('size'),
      material: attr('material'),
      imageUrl: _text(json['imageUrl'] ?? json['image_url']),
      sortOrder:
          (json['sortOrder'] ?? json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String productId;
  final String name;
  final double price;
  final double stock;
  final String? color;
  final String? colorHex;
  final String? size;
  final String? material;
  final String? imageUrl;
  final int sortOrder;

  bool get inStock => stock > 0;

  /// Parses `color_hex` into a swatch colour. Returns null for anything that
  /// is not a well-formed hex value, so the UI can fall back to a label.
  Color? get swatch {
    final hex = colorHex?.replaceAll('#', '').trim();
    if (hex == null || (hex.length != 6 && hex.length != 8)) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return Color(hex.length == 6 ? 0xFF000000 | value : value);
  }
}

/// A product as the storefront exposes it.
///
/// Note the price: the live platform keeps `price` at 0 for every RAWNQ row
/// and stores the real retail price in the tier-1 price column. The snapshot
/// and the remote mapper both normalise that into [price].
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.categoryId,
    this.brandId,
    this.description,
    this.compareAtPrice,
    this.discountPercentage = 0,
    this.showDiscount = false,
    this.stock = 0,
    this.images = const <String>[],
    this.labels = const <String>[],
    this.isFeatured = false,
    this.sortOrder = 0,
    this.createdAt,
    this.variants = const <ProductVariant>[],
  });

  factory Product.fromJson(
    Map<String, dynamic> json, {
    List<ProductVariant> variants = const <ProductVariant>[],
  }) {
    final embedded = json['variants'];
    final resolvedVariants = embedded is List
        ? embedded
              .whereType<Map<String, dynamic>>()
              .map(ProductVariant.fromJson)
              .toList(growable: false)
        : variants;

    return Product(
      id: json['id'] as String? ?? '',
      name: (json['name_ar'] ?? json['name'] ?? '') as String,
      price: _toDouble(json['price'] ?? json['price_1']),
      categoryId: _text(json['categoryId'] ?? json['category_id']),
      brandId: _text(json['brandId'] ?? json['brand_id']),
      description: _text(json['description'] ?? json['description_ar']),
      compareAtPrice:
          json['compareAtPrice'] == null && json['compare_at_price'] == null
          ? null
          : _toDouble(json['compareAtPrice'] ?? json['compare_at_price']),
      discountPercentage: _toDouble(
        json['discountPercentage'] ?? json['discount_percentage_tier1'],
      ),
      showDiscount:
          json['showDiscount'] as bool? ??
          json['show_discount'] as bool? ??
          false,
      stock: _toDouble(json['stock'] ?? json['stock_quantity']),
      images: _images(json),
      labels:
          (json['labels'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const <String>[],
      isFeatured:
          json['isFeatured'] as bool? ?? json['is_featured'] as bool? ?? false,
      sortOrder:
          (json['sortOrder'] ?? json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'] ?? '') as String? ?? '',
      ),
      variants: resolvedVariants,
    );
  }

  final String id;
  final String name;
  final double price;
  final String? categoryId;
  final String? brandId;
  final String? description;
  final double? compareAtPrice;
  final double discountPercentage;
  final bool showDiscount;
  final double stock;
  final List<String> images;
  final List<String> labels;
  final bool isFeatured;
  final int sortOrder;
  final DateTime? createdAt;
  final List<ProductVariant> variants;

  /// The storefront tags newly-added products with a `new` label.
  bool get isNew => labels.contains('new');

  bool get hasVariants => variants.isNotEmpty;

  /// The shopper must pick an option before this can go in the cart.
  bool get requiresSelection => hasVariants;

  /// Sizes are optional on the live data: 64 of 94 variants carry one.
  bool get hasSizes => variants.any((v) => (v.size ?? '').isNotEmpty);

  bool get hasColors => variants.any((v) => (v.color ?? '').isNotEmpty);

  bool get inStock => hasVariants ? variants.any((v) => v.inStock) : stock > 0;

  /// Distinct colours in variant order, de-duplicated by colour name.
  List<ProductVariant> get colorOptions {
    final seen = <String>{};
    final options = <ProductVariant>[];
    for (final variant in variants) {
      final key = variant.color ?? variant.name;
      if (key.isEmpty || !seen.add(key)) continue;
      options.add(variant);
    }
    return options;
  }

  /// Sizes offered for [color], or every size when [color] is null.
  List<String> sizesFor(String? color) {
    final sizes = <String>[];
    for (final variant in variants) {
      final size = variant.size;
      if (size == null || size.isEmpty) continue;
      if (color != null && variant.color != color) continue;
      if (!sizes.contains(size)) sizes.add(size);
    }
    return sizes;
  }

  /// Resolves a colour/size pair to a concrete variant, or null when the
  /// combination does not exist.
  ProductVariant? findVariant({String? color, String? size}) {
    for (final variant in variants) {
      final colorMatches = color == null || variant.color == color;
      final sizeMatches = size == null || variant.size == size;
      if (colorMatches && sizeMatches) return variant;
    }
    return null;
  }

  /// Price shown on cards: the cheapest option when the product has variants.
  double get displayPrice {
    if (!hasVariants) return price;
    final prices = variants.where((v) => v.price > 0).map((v) => v.price);
    if (prices.isEmpty) return price;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  /// True when the storefront is actively advertising a reduction. On the live
  /// RAWNQ data this is false for every product today; the UI supports it so
  /// the app is correct the moment the shop runs a sale.
  bool get isOnSale => effectiveOriginalPrice != null;

  /// The struck-through "was" price, or null when nothing is discounted.
  double? get effectiveOriginalPrice {
    final compare = compareAtPrice;
    if (compare != null && compare > displayPrice) return compare;
    if (showDiscount && discountPercentage > 0) {
      return displayPrice / (1 - discountPercentage / 100);
    }
    return null;
  }

  /// Whole-percent reduction, for the sale badge.
  int? get discountBadge {
    final original = effectiveOriginalPrice;
    if (original == null || original <= 0) return null;
    final percent = ((original - displayPrice) / original * 100).round();
    return percent > 0 ? percent : null;
  }

  String? get primaryImage => images.isEmpty ? null : images.first;

  /// Gallery for the detail screen, with the selected variant's own photo
  /// promoted to the front when it has one.
  List<String> galleryFor(ProductVariant? variant) {
    final variantImage = variant?.imageUrl;
    if (variantImage == null || variantImage.isEmpty) return images;
    return <String>[variantImage, ...images.where((i) => i != variantImage)];
  }

  static List<String> _images(Map<String, dynamic> json) {
    final direct = json['images'];
    if (direct is List) {
      final list = direct
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (list.isNotEmpty) return List<String>.unmodifiable(list);
    }
    // The live table stores images in flat `image_url_1` … `image_url_10`
    // columns; the `images` array column is null for every RAWNQ row.
    final flat = <String>[];
    for (var i = 1; i <= 10; i++) {
      final value = _text(json['image_url_$i']);
      if (value != null) flat.add(value);
    }
    return List<String>.unmodifiable(flat);
  }
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
