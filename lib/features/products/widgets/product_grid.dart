import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/models/product.dart';
import 'product_card.dart';

/// Responsive product grid.
///
/// Two columns on a phone, three once the window is wide enough that two
/// columns would leave the cards oversized.
class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<Product> products;
  final void Function(Product product) onProductTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        RawnqSpace.lg,
        RawnqSpace.sm,
        RawnqSpace.lg,
        RawnqSpace.xxl,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: productGridDelegate(context),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            key: ValueKey<String>(product.id),
            product: product,
            onTap: () => onProductTap(product),
          );
        },
      ),
    );
  }
}

/// Skeleton grid shown while the catalogue loads.
class ProductSliverGridSkeleton extends StatelessWidget {
  const ProductSliverGridSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        RawnqSpace.lg,
        RawnqSpace.sm,
        RawnqSpace.lg,
        RawnqSpace.xxl,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: productGridDelegate(context),
        itemCount: itemCount,
        itemBuilder: (context, _) => const ProductCardSkeleton(),
      ),
    );
  }
}

/// Shared grid geometry so cards and skeletons always agree.
SliverGridDelegate productGridDelegate(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final columns = width >= 720 ? 3 : 2;
  // Square image + a fixed text block; the ratio keeps the text from
  // overflowing on the narrowest supported phones.
  final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
  final aspectRatio = 1 / (1 + (0.42 * textScale).clamp(0.42, 0.62));

  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: RawnqSpace.lg,
    crossAxisSpacing: RawnqSpace.lg,
    childAspectRatio: aspectRatio,
  );
}
