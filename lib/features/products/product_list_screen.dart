import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/widgets/catalog_scaffold.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/catalog.dart';
import 'product_filters.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/product_grid.dart';

/// A filterable product listing.
///
/// The same screen serves a category, a brand and the "وصل حديثاً" scope,
/// matching the three listing routes on the live storefront.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({
    super.key,
    this.categoryId,
    this.brandId,
    this.scope,
  });

  final String? categoryId;
  final String? brandId;

  /// `new` restricts the list to products the shop labelled as new arrivals.
  final String? scope;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late ProductFilter _filter = ProductFilter(
    categoryId: widget.categoryId,
    brandId: widget.brandId,
    onlyNew: widget.scope == 'new',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(loadedCatalogProvider);
    final refinements = _filter.activeRefinementCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(context, catalog), overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.filtersTitle,
            onPressed: catalog == null ? null : () => _openFilters(catalog),
            icon: Badge(
              isLabelVisible: refinements > 0,
              label: Text('$refinements'),
              backgroundColor: RawnqColors.terracotta,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: CatalogView(
        skeleton: (context) => const <Widget>[ProductSliverGridSkeleton()],
        builder: (context, data) {
          final products = _filter.apply(data.products);
          if (products.isEmpty) {
            return <Widget>[
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.checkroom_outlined,
                  title: l10n.stateEmptyProducts,
                  body: l10n.stateEmptyProductsHint,
                  action: _filter.hasActiveRefinements
                      ? OutlinedButton(
                          onPressed: () => setState(() => _filter = _filter.reset()),
                          child: Text(l10n.filterReset),
                        )
                      : null,
                ),
              ),
            ];
          }

          return <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  RawnqSpace.lg,
                  RawnqSpace.md,
                  RawnqSpace.lg,
                  0,
                ),
                child: Text(
                  l10n.homeProductCount(products.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            ProductSliverGrid(
              products: products,
              onProductTap: (product) => context.push(Routes.productPath(product.id)),
            ),
          ];
        },
      ),
    );
  }

  Future<void> _openFilters(Catalog catalog) async {
    final next = await showProductFilterSheet(
      context,
      filter: _filter,
      brands: catalog.brands,
    );
    if (next != null && mounted) setState(() => _filter = next);
  }

  String _title(BuildContext context, Catalog? catalog) {
    final l10n = AppLocalizations.of(context);
    if (widget.scope == 'new') return l10n.homeNewArrivals;

    final categoryId = widget.categoryId;
    if (categoryId != null) {
      final name = catalog?.categoryById(categoryId)?.name;
      if (name != null) return name;
    }
    final brandId = widget.brandId;
    if (brandId != null) {
      final name = catalog?.brandById(brandId)?.name;
      if (name != null) return name;
    }
    return l10n.homeAllProducts;
  }
}
