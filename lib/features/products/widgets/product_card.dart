import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/product.dart';
import '../../favorites/favorites_controller.dart';

/// The product tile used on every listing screen.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final available = product.inStock;

    return Semantics(
      button: true,
      label:
          '${product.name}، ${Money.format(product.displayPrice)}، '
          '${available ? l10n.productAvailable : l10n.productUnavailable}',
      excludeSemantics: true,
      child: Material(
        color: RawnqColors.surface,
        borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
              boxShadow: kCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _Thumbnail(product: product, available: available),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    RawnqSpace.md,
                    RawnqSpace.sm,
                    RawnqSpace.md,
                    RawnqSpace.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Long Arabic product names are the norm here, so a
                      // fixed two-line box keeps grid rows aligned.
                      SizedBox(
                        height: 40,
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: RawnqSpace.xs),
                      _PriceRow(product: product),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends ConsumerWidget {
  const _Thumbnail({required this.product, required this.available});

  final Product product;
  final bool available;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isFavorite = ref.watch(isFavoriteProvider(product.id));
    final discount = product.discountBadge;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Opacity(
            opacity: available ? 1 : 0.55,
            child: ProductImage(
              url: product.primaryImage,
              decodeWidth: 400,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(RawnqSpace.radiusMd),
              ),
            ),
          ),
          PositionedDirectional(
            top: RawnqSpace.sm,
            start: RawnqSpace.sm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (product.isNew) ProductBadge(label: l10n.productBadgeNew),
                if (discount != null) ...<Widget>[
                  const SizedBox(height: RawnqSpace.xs),
                  ProductBadge(
                    label: l10n.productBadgeSale(discount),
                    color: RawnqColors.sale,
                  ),
                ],
                if (!available) ...<Widget>[
                  const SizedBox(height: RawnqSpace.xs),
                  ProductBadge(
                    label: l10n.productUnavailable,
                    color: RawnqColors.inkSoft,
                  ),
                ],
              ],
            ),
          ),
          PositionedDirectional(
            top: RawnqSpace.xs,
            end: RawnqSpace.xs,
            child: FavoriteButton(
              productId: product.id,
              isFavorite: isFavorite,
            ),
          ),
        ],
      ),
    );
  }
}

/// Heart toggle shared by the card and the detail screen.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.productId,
    required this.isFavorite,
    this.iconSize = 20,
  });

  final String productId;
  final bool isFavorite;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: IconButton(
        iconSize: iconSize,
        visualDensity: VisualDensity.compact,
        tooltip: isFavorite
            ? l10n.favoritesRemoveLabel
            : l10n.favoritesAddLabel,
        onPressed: () {
          final added = ref.read(favoritesProvider.notifier).toggle(productId);
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  added ? l10n.favoritesAdded : l10n.favoritesRemoved,
                ),
                duration: const Duration(milliseconds: 1400),
              ),
            );
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey<bool>(isFavorite),
            color: isFavorite ? RawnqColors.sale : RawnqColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Small pill used for `جديد`, sale and availability markers.
class ProductBadge extends StatelessWidget {
  const ProductBadge({
    super.key,
    required this.label,
    this.color = RawnqColors.brown,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RawnqSpace.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(RawnqSpace.radiusSm),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final original = product.effectiveOriginalPrice;
    return Row(
      children: <Widget>[
        Text(
          Money.format(product.displayPrice),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: RawnqColors.brown,
          ),
        ),
        if (original != null) ...<Widget>[
          const SizedBox(width: RawnqSpace.sm),
          Flexible(
            child: Text(
              Money.format(original),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: RawnqColors.inkSoft,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Loading placeholder matching [ProductCard]'s dimensions, so the grid does
/// not jump when real content arrives.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: ShimmerBox(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(RawnqSpace.radiusMd),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(RawnqSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ShimmerBox(height: 12, width: double.infinity),
                SizedBox(height: RawnqSpace.sm),
                ShimmerBox(height: 12, width: 110),
                SizedBox(height: RawnqSpace.md),
                ShimmerBox(height: 14, width: 70),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
