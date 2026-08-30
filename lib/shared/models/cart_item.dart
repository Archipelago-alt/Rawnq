import 'package:flutter/material.dart';

import 'product.dart';

/// One line in the shopping cart.
///
/// Identity is the product *and* the chosen variant, so the same dress in two
/// sizes is two lines, while re-adding the same size increments one line.
@immutable
class CartItem {
  const CartItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.variantId,
    this.variantLabel,
    this.color,
    this.size,
    this.imageUrl,
    this.maxQuantity,
  });

  factory CartItem.fromProduct(
    Product product, {
    ProductVariant? variant,
    int quantity = 1,
  }) {
    return CartItem(
      productId: product.id,
      name: product.name,
      unitPrice: variant?.price != null && variant!.price > 0
          ? variant.price
          : product.price,
      quantity: quantity,
      variantId: variant?.id,
      variantLabel: variant?.name,
      color: variant?.color,
      size: variant?.size,
      imageUrl: variant?.imageUrl ?? product.primaryImage,
      maxQuantity: variant != null
          ? variant.stock.floor()
          : product.stock.floor(),
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['productId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    variantId: json['variantId'] as String?,
    variantLabel: json['variantLabel'] as String?,
    color: json['color'] as String?,
    size: json['size'] as String?,
    imageUrl: json['imageUrl'] as String?,
    maxQuantity: (json['maxQuantity'] as num?)?.toInt(),
  );

  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? variantId;
  final String? variantLabel;
  final String? color;
  final String? size;
  final String? imageUrl;

  /// Stock ceiling captured when the line was created, so the quantity
  /// stepper cannot exceed what the shop has.
  final int? maxQuantity;

  /// Stable identity for a cart line.
  String get key => '$productId::${variantId ?? 'base'}';

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
    productId: productId,
    name: name,
    unitPrice: unitPrice,
    quantity: quantity ?? this.quantity,
    variantId: variantId,
    variantLabel: variantLabel,
    color: color,
    size: size,
    imageUrl: imageUrl,
    maxQuantity: maxQuantity,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'productId': productId,
    'name': name,
    'unitPrice': unitPrice,
    'quantity': quantity,
    if (variantId != null) 'variantId': variantId,
    if (variantLabel != null) 'variantLabel': variantLabel,
    if (color != null) 'color': color,
    if (size != null) 'size': size,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (maxQuantity != null) 'maxQuantity': maxQuantity,
  };

  @override
  bool operator ==(Object other) =>
      other is CartItem &&
      other.productId == productId &&
      other.variantId == variantId &&
      other.quantity == quantity &&
      other.unitPrice == unitPrice;

  @override
  int get hashCode => Object.hash(productId, variantId, quantity, unitPrice);
}
