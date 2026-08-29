import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/product.dart';
import '../cart/cart_controller.dart';
import '../favorites/favorites_controller.dart';
import 'widgets/option_selectors.dart';
import 'widgets/product_card.dart';
import 'widgets/product_gallery.dart';

/// Product detail: gallery, options, description and add-to-cart.
///
/// The option rules match the storefront's: a product that has variants
/// cannot be added until one is chosen, and when the chosen colour offers
/// sizes, a size is required too.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _color;
  String? _size;

  /// Set when the shopper tries to add without choosing, so the selector can
  /// be highlighted rather than only showing a transient snack bar.
  bool _showSelectionError = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.productDetailsTitle)),
      body: catalog.when(
        loading: () => const _DetailSkeleton(),
        error: (error, _) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(catalogProvider),
        ),
        data: (data) {
          final product = data.productById(widget.productId);
          if (product == null) {
            return EmptyStateView(
              icon: Icons.search_off_rounded,
              title: l10n.stateEmptyProducts,
              body: l10n.stateEmptyProductsHint,
              action: OutlinedButton(
                onPressed: () => context.go(Routes.home),
                child: Text(l10n.cartStartShopping),
              ),
            );
          }
          final brandName = data.brandById(product.brandId)?.name;
          return _DetailBody(
            product: product,
            brandName: brandName,
            color: _color,
            size: _size,
            showSelectionError: _showSelectionError,
            onColorSelected: _selectColor,
            onSizeSelected: (value) => setState(() {
              _size = value;
              _showSelectionError = false;
            }),
            onAddToCart: () => _addToCart(product),
          );
        },
      ),
    );
  }

  void _selectColor(String color) {
    setState(() {
      _color = color;
      _showSelectionError = false;
      // Keep the size only if the new colour still offers it.
      final product = ref.read(productByIdProvider(widget.productId));
      final sizes = product?.sizesFor(color) ?? const <String>[];
      if (_size != null && !sizes.contains(_size)) _size = null;
      if (sizes.length == 1) _size = sizes.first;
    });
  }

  void _addToCart(Product product) {
    final l10n = AppLocalizations.of(context);
    final variant = _resolveVariant(product);

    if (product.requiresSelection && variant == null) {
      setState(() => _showSelectionError = true);
      _toast(
        _color == null && product.hasColors
            ? l10n.productSelectColorFirst
            : l10n.productSelectSizeFirst,
      );
      return;
    }

    final result = ref.read(cartProvider.notifier).add(product, variant: variant);
    if (result.isSuccess) {
      _toast(
        l10n.productAddedToCart,
        action: SnackBarAction(
          label: l10n.navCart,
          textColor: Colors.white,
          onPressed: () => context.go(Routes.cart),
        ),
      );
      return;
    }

    setState(() => _showSelectionError = true);
    _toast(
      switch (result.error!) {
        CartAddError.optionRequired => l10n.productSelectColorFirst,
        CartAddError.sizeRequired => l10n.productSelectSizeFirst,
        CartAddError.outOfStock => l10n.productOutOfStockOption,
        CartAddError.maxQuantity =>
          l10n.cartMaxQuantityReached(result.availableQuantity ?? 0),
      },
    );
  }

  /// Maps the current selection onto a concrete variant, if it is complete.
  ProductVariant? _resolveVariant(Product product) {
    if (!product.hasVariants) return null;
    final color = _color;
    if (color == null) return null;
    final sizes = product.sizesFor(color);
    if (sizes.isNotEmpty && _size == null) return null;
    return product.findVariant(color: color, size: _size);
  }

  void _toast(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.product,
    required this.brandName,
    required this.color,
    required this.size,
    required this.showSelectionError,
    required this.onColorSelected,
    required this.onSizeSelected,
    required this.onAddToCart,
  });

  final Product product;
  final String? brandName;
  final String? color;
  final String? size;
  final bool showSelectionError;
  final ValueChanged<String> onColorSelected;
  final ValueChanged<String> onSizeSelected;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isFavorite = ref.watch(isFavoriteProvider(product.id));

    final selectedVariant = color == null
        ? null
        : product.findVariant(color: color, size: size) ??
            product.findVariant(color: color);
    final gallery = product.galleryFor(selectedVariant);
    final price = selectedVariant?.price != null && selectedVariant!.price > 0
        ? selectedVariant.price
        : product.displayPrice;
    final available = selectedVariant?.inStock ?? product.inStock;
    final sizes = product.sizesFor(color);
    final material = selectedVariant?.material ??
        (product.variants.isEmpty ? null : product.variants.first.material);

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  ProductGallery(images: gallery, semanticLabel: product.name),
                  PositionedDirectional(
                    top: RawnqSpace.md,
                    start: RawnqSpace.md,
                    child: FavoriteButton(
                      productId: product.id,
                      isFavorite: isFavorite,
                      iconSize: 22,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(RawnqSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        if (product.isNew) ProductBadge(label: l10n.productBadgeNew),
                        if (product.isNew) const SizedBox(width: RawnqSpace.sm),
                        ProductBadge(
                          label: available ? l10n.productAvailable : l10n.productUnavailable,
                          color: available ? RawnqColors.success : RawnqColors.inkSoft,
                        ),
                      ],
                    ),
                    const SizedBox(height: RawnqSpace.md),
                    Text(product.name, style: theme.textTheme.titleLarge),
                    if (brandName != null) ...<Widget>[
                      const SizedBox(height: RawnqSpace.xs),
                      Text(
                        '${l10n.productBrand}: $brandName',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: RawnqSpace.md),
                    _PriceBlock(price: price, original: product.effectiveOriginalPrice),

                    if (product.hasColors) ...<Widget>[
                      const SizedBox(height: RawnqSpace.xl),
                      _OptionLabel(
                        text: l10n.productChooseColor,
                        highlight: showSelectionError && color == null,
                      ),
                      const SizedBox(height: RawnqSpace.md),
                      ColorSelector(
                        options: product.colorOptions,
                        selected: color,
                        onSelected: onColorSelected,
                        isAvailable: (value) => product.variants
                            .any((v) => v.color == value && v.inStock),
                      ),
                    ],

                    if (sizes.isNotEmpty) ...<Widget>[
                      const SizedBox(height: RawnqSpace.xl),
                      _OptionLabel(
                        text: l10n.productChooseSize,
                        highlight: showSelectionError && color != null && size == null,
                      ),
                      const SizedBox(height: RawnqSpace.md),
                      SizeSelector(
                        sizes: sizes,
                        selected: size,
                        onSelected: onSizeSelected,
                        isAvailable: (value) =>
                            product.findVariant(color: color, size: value)?.inStock ?? false,
                      ),
                    ],

                    if (selectedVariant != null && !selectedVariant.inStock) ...<Widget>[
                      const SizedBox(height: RawnqSpace.md),
                      Text(
                        l10n.productOutOfStockOption,
                        style: theme.textTheme.bodySmall?.copyWith(color: RawnqColors.sale),
                      ),
                    ],

                    if (material != null) ...<Widget>[
                      const SizedBox(height: RawnqSpace.xl),
                      _InfoRow(label: l10n.productMaterial, value: material),
                    ],

                    if (product.description != null) ...<Widget>[
                      const SizedBox(height: RawnqSpace.xl),
                      Text(l10n.productDescription, style: theme.textTheme.titleMedium),
                      const SizedBox(height: RawnqSpace.sm),
                      Text(product.description!, style: theme.textTheme.bodyMedium),
                    ],
                    const SizedBox(height: RawnqSpace.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
        _AddToCartBar(
          price: price,
          enabled: available,
          onPressed: onAddToCart,
        ),
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.price, required this.original});

  final double price;
  final double? original;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          Money.format(price),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: RawnqColors.brown,
          ),
        ),
        if (original != null) ...<Widget>[
          const SizedBox(width: RawnqSpace.md),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              Money.format(original!),
              style: const TextStyle(
                fontSize: 14,
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

class _OptionLabel extends StatelessWidget {
  const _OptionLabel({required this.text, required this.highlight});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: highlight ? RawnqColors.sale : RawnqColors.ink,
              ),
        ),
        if (highlight) ...<Widget>[
          const SizedBox(width: RawnqSpace.sm),
          const Icon(Icons.error_outline_rounded, size: 18, color: RawnqColors.sale),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({
    required this.price,
    required this.enabled,
    required this.onPressed,
  });

  final double price;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: RawnqColors.surface,
      elevation: 8,
      shadowColor: const Color(0x1A7C3918),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(RawnqSpace.lg),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(l10n.cartTotal, style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      Money.format(price),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: RawnqColors.brown,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: RawnqSpace.lg),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: enabled ? onPressed : null,
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                  label: Text(
                    enabled ? l10n.productAddToCart : l10n.productUnavailable,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(aspectRatio: 1, child: ShimmerBox(borderRadius: BorderRadius.zero)),
          Padding(
            padding: EdgeInsets.all(RawnqSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ShimmerBox(height: 20, width: 220),
                SizedBox(height: RawnqSpace.md),
                ShimmerBox(height: 26, width: 120),
                SizedBox(height: RawnqSpace.xl),
                ShimmerBox(height: 44, width: 200),
                SizedBox(height: RawnqSpace.xl),
                ShimmerBox(height: 14, width: double.infinity),
                SizedBox(height: RawnqSpace.sm),
                ShimmerBox(height: 14, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
