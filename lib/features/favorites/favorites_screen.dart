import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/widgets/catalog_scaffold.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/app_localizations.dart';
import '../products/widgets/product_grid.dart';
import 'favorites_controller.dart';

/// Saved products, persisted between launches.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesTitle)),
      body: CatalogView(
        skeleton: (context) => const <Widget>[ProductSliverGridSkeleton(itemCount: 4)],
        builder: (context, catalog) {
          // Favourites survive catalogue changes, so ids that no longer exist
          // are simply skipped rather than rendered as broken tiles.
          final products = catalog.products
              .where((product) => favorites.contains(product.id))
              .toList(growable: false);

          if (products.isEmpty) {
            return <Widget>[
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.favorite_border_rounded,
                  title: l10n.favoritesEmpty,
                  body: l10n.favoritesEmptyHint,
                  action: OutlinedButton(
                    onPressed: () => context.go(Routes.home),
                    child: Text(l10n.cartStartShopping),
                  ),
                ),
              ),
            ];
          }

          return <Widget>[
            ProductSliverGrid(
              products: products,
              onProductTap: (product) => context.push(Routes.productPath(product.id)),
            ),
          ];
        },
      ),
    );
  }
}
