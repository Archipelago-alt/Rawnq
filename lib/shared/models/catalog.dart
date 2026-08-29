import 'package:flutter/material.dart';

import 'category.dart';
import 'checkout_options.dart';
import 'product.dart';
import 'store_info.dart';

/// Everything the app needs to render the storefront, fetched as one unit.
///
/// The live catalogue is 47 products, so loading it whole is both correct and
/// cheaper than paginating; [CatalogRepository] still pages the underlying
/// requests so this stays true if the shop grows.
@immutable
class Catalog {
  const Catalog({
    required this.store,
    required this.categories,
    required this.brands,
    required this.products,
    required this.deliveryLocations,
    required this.paymentMethods,
    required this.isLiveData,
    this.capturedAt,
  });

  factory Catalog.fromSnapshot(Map<String, dynamic> json) => Catalog(
        store: StoreInfo.fromJson(json['store'] as Map<String, dynamic>),
        categories: _list(json['categories'], ProductCategory.fromJson),
        brands: _list(json['brands'], Brand.fromJson),
        products: _list(json['products'], (j) => Product.fromJson(j)),
        deliveryLocations: _list(json['deliveryLocations'], DeliveryLocation.fromJson),
        paymentMethods: _list(json['paymentMethods'], StorePaymentMethod.fromJson),
        isLiveData: false,
        capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? ''),
      );

  final StoreInfo store;
  final List<ProductCategory> categories;
  final List<Brand> brands;
  final List<Product> products;
  final List<DeliveryLocation> deliveryLocations;
  final List<StorePaymentMethod> paymentMethods;

  /// False when this came from the bundled snapshot rather than the live API.
  /// The UI surfaces this honestly instead of passing sample data off as live.
  final bool isLiveData;

  /// When the bundled snapshot was taken. Null for live data.
  final DateTime? capturedAt;

  List<Product> get newArrivals {
    final items = products.where((p) => p.isNew).toList(growable: false);
    return items;
  }

  List<Product> productsInCategory(String categoryId) =>
      products.where((p) => p.categoryId == categoryId).toList(growable: false);

  List<Product> productsOfBrand(String brandId) =>
      products.where((p) => p.brandId == brandId).toList(growable: false);

  Product? productById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  ProductCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Brand? brandById(String? id) {
    if (id == null) return null;
    for (final brand in brands) {
      if (brand.id == id) return brand;
    }
    return null;
  }

  static List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) build) {
    if (raw is! List) return const [];
    return List<T>.unmodifiable(raw.whereType<Map<String, dynamic>>().map(build));
  }
}
