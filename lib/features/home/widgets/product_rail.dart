import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../shared/models/product.dart';
import '../../products/widgets/product_card.dart';

/// Horizontally scrolling row of product cards used on the home screen.
class ProductRail extends StatelessWidget {
  const ProductRail({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _railHeight(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: RawnqSpace.lg),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: RawnqSpace.md),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: 168,
            child: ProductCard(
              key: ValueKey<String>('rail-${product.id}'),
              product: product,
              onTap: () => context.push(Routes.productPath(product.id)),
            ),
          );
        },
      ),
    );
  }
}

class ProductRailSkeleton extends StatelessWidget {
  const ProductRailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: _railHeight(context),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: RawnqSpace.lg),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: RawnqSpace.md),
          itemBuilder: (context, __) =>
              const SizedBox(width: 168, child: ProductCardSkeleton()),
        ),
      ),
    );
  }
}

/// Card width plus its text block, scaled with the user's text size so long
/// Arabic names never clip.
double _railHeight(BuildContext context) {
  const cardWidth = 168.0;
  final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
  return cardWidth + (86 * textScale);
}
