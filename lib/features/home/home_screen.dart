import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/widgets/catalog_scaffold.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/catalog.dart';
import 'widgets/brand_strip.dart';
import 'widgets/category_strip.dart';
import 'widgets/home_hero.dart';
import 'widgets/product_rail.dart';

/// The storefront home screen: brand hero, categories, brands, new arrivals
/// and a rail per category — mirroring the live mobile storefront's layout.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: CatalogView(
        skeleton: (context) => <Widget>[
          const SliverToBoxAdapter(child: HomeHeroSkeleton()),
          SliverToBoxAdapter(
            child: Shimmer(
              child: Padding(
                padding: const EdgeInsets.all(RawnqSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const ShimmerBox(height: 18, width: 140),
                    const SizedBox(height: RawnqSpace.lg),
                    SizedBox(
                      height: 108,
                      child: Row(
                        children: List<Widget>.generate(
                          4,
                          (_) => const Padding(
                            padding: EdgeInsetsDirectional.only(
                              start: RawnqSpace.md,
                            ),
                            child: ShimmerBox(width: 88, height: 108),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const ProductRailSkeleton(),
        ],
        builder: (context, catalog) => _buildSections(context, catalog),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, Catalog catalog) {
    final l10n = AppLocalizations.of(context);
    final newArrivals = catalog.newArrivals;

    return <Widget>[
      SliverToBoxAdapter(
        child: HomeHero(
          store: catalog.store,
          onContactPressed: () => context.push(Routes.contact),
        ),
      ),
      if (catalog.categories.isNotEmpty) ...<Widget>[
        SliverToBoxAdapter(
          child: SectionHeader(
            title: l10n.homeShopByCategory,
            actionLabel: l10n.homeViewAll,
            onAction: () => context.push(Routes.categories),
          ),
        ),
        SliverToBoxAdapter(
          child: CategoryStrip(categories: catalog.categories),
        ),
      ],
      if (catalog.brands.isNotEmpty) ...<Widget>[
        SliverToBoxAdapter(child: SectionHeader(title: l10n.homeShopByBrand)),
        SliverToBoxAdapter(child: BrandStrip(brands: catalog.brands)),
      ],
      if (newArrivals.isNotEmpty) ...<Widget>[
        SliverToBoxAdapter(
          child: SectionHeader(
            title: l10n.homeNewArrivals,
            actionLabel: l10n.homeViewAll,
            onAction: () => context.push(Routes.newArrivalsPath),
          ),
        ),
        SliverToBoxAdapter(child: ProductRail(products: newArrivals)),
      ],
      // A rail per category, so the whole catalogue is reachable by scrolling
      // exactly as it is on the live site.
      for (final category in catalog.categories)
        ..._categorySection(context, catalog, category.id, category.name),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            RawnqSpace.lg,
            RawnqSpace.xl,
            RawnqSpace.lg,
            RawnqSpace.xxl,
          ),
          child: OutlinedButton.icon(
            onPressed: () => context.push(Routes.allProductsPath),
            icon: const Icon(Icons.storefront_outlined),
            label: Text(l10n.homeAllProducts),
          ),
        ),
      ),
      if (catalog.store.showBringusBranding)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: RawnqSpace.xl),
            child: Center(
              child: Text(
                l10n.poweredBy,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _categorySection(
    BuildContext context,
    Catalog catalog,
    String categoryId,
    String name,
  ) {
    final products = catalog.productsInCategory(categoryId);
    if (products.isEmpty) return const <Widget>[];
    final l10n = AppLocalizations.of(context);
    return <Widget>[
      SliverToBoxAdapter(
        child: SectionHeader(
          title: name,
          actionLabel: l10n.homeViewAll,
          onAction: () => context.push(Routes.categoryPath(categoryId)),
        ),
      ),
      SliverToBoxAdapter(child: ProductRail(products: products)),
    ];
  }
}
