import 'package:flutter/foundation.dart';

import '../../core/utils/arabic_text.dart';
import '../../shared/models/product.dart';

/// The orderings offered on listing screens. Mirrors the sort options the
/// live storefront exposes.
enum ProductSort { defaultOrder, priceAsc, priceDesc, nameAsc, newest }

/// Filter state for a listing screen.
@immutable
class ProductFilter {
  const ProductFilter({
    this.categoryId,
    this.brandId,
    this.query = '',
    this.onlyAvailable = false,
    this.onlyNew = false,
    this.sort = ProductSort.defaultOrder,
  });

  final String? categoryId;
  final String? brandId;
  final String query;
  final bool onlyAvailable;
  final bool onlyNew;
  final ProductSort sort;

  /// True when anything narrows the list beyond the screen's own scope.
  bool get hasActiveRefinements =>
      brandId != null || onlyAvailable || onlyNew || sort != ProductSort.defaultOrder;

  int get activeRefinementCount => <bool>[
        brandId != null,
        onlyAvailable,
        onlyNew,
        sort != ProductSort.defaultOrder,
      ].where((active) => active).length;

  ProductFilter copyWith({
    String? categoryId,
    bool clearCategory = false,
    String? brandId,
    bool clearBrand = false,
    String? query,
    bool? onlyAvailable,
    bool? onlyNew,
    ProductSort? sort,
  }) =>
      ProductFilter(
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        brandId: clearBrand ? null : (brandId ?? this.brandId),
        query: query ?? this.query,
        onlyAvailable: onlyAvailable ?? this.onlyAvailable,
        onlyNew: onlyNew ?? this.onlyNew,
        sort: sort ?? this.sort,
      );

  /// Drops every refinement but keeps the screen's own scope (its category)
  /// and the current search term.
  ProductFilter reset() => ProductFilter(categoryId: categoryId, query: query);

  /// Applies the filter and ordering to [products].
  ///
  /// Filtering runs client-side: the storefront exposes no search endpoint,
  /// and the whole catalogue is 47 products.
  List<Product> apply(List<Product> products) {
    final filtered = products.where((product) {
      if (categoryId != null && product.categoryId != categoryId) return false;
      if (brandId != null && product.brandId != brandId) return false;
      if (onlyAvailable && !product.inStock) return false;
      if (onlyNew && !product.isNew) return false;
      if (query.trim().isNotEmpty && !_matchesQuery(product)) return false;
      return true;
    }).toList();

    switch (sort) {
      case ProductSort.priceAsc:
        filtered.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
      case ProductSort.priceDesc:
        filtered.sort((a, b) => b.displayPrice.compareTo(a.displayPrice));
      case ProductSort.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case ProductSort.newest:
        filtered.sort((a, b) {
          final aDate = a.createdAt;
          final bDate = b.createdAt;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
      case ProductSort.defaultOrder:
        filtered.sort((a, b) {
          final order = a.sortOrder.compareTo(b.sortOrder);
          return order != 0 ? order : a.name.compareTo(b.name);
        });
    }
    return List<Product>.unmodifiable(filtered);
  }

  bool _matchesQuery(Product product) {
    if (ArabicText.matches(product.name, query)) return true;
    final description = product.description;
    if (description != null && ArabicText.matches(description, query)) return true;
    for (final variant in product.variants) {
      if (ArabicText.matches(variant.name, query)) return true;
      final color = variant.color;
      if (color != null && ArabicText.matches(color, query)) return true;
    }
    return false;
  }

  @override
  bool operator ==(Object other) =>
      other is ProductFilter &&
      other.categoryId == categoryId &&
      other.brandId == brandId &&
      other.query == query &&
      other.onlyAvailable == onlyAvailable &&
      other.onlyNew == onlyNew &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(categoryId, brandId, query, onlyAvailable, onlyNew, sort);
}
