import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/widgets/catalog_scaffold.dart';
import '../../core/widgets/product_image.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/category.dart';

/// The الفئات tab: one card per category with its Arabic description and
/// product count.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      body: CatalogView(
        skeleton: (context) => <Widget>[
          SliverPadding(
            padding: const EdgeInsets.all(RawnqSpace.lg),
            sliver: SliverList.separated(
              itemCount: 4,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: RawnqSpace.lg),
              itemBuilder: (_, __) => const Shimmer(
                child: ShimmerBox(
                  height: 116,
                  borderRadius: BorderRadius.all(
                    Radius.circular(RawnqSpace.radiusMd),
                  ),
                ),
              ),
            ),
          ),
        ],
        builder: (context, catalog) {
          if (catalog.categories.isEmpty) {
            return <Widget>[
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.grid_view_rounded,
                  title: l10n.stateEmptyProducts,
                  body: l10n.stateEmptyProductsHint,
                ),
              ),
            ];
          }

          return <Widget>[
            SliverPadding(
              padding: const EdgeInsets.all(RawnqSpace.lg),
              sliver: SliverList.separated(
                itemCount: catalog.categories.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: RawnqSpace.lg),
                itemBuilder: (context, index) {
                  final category = catalog.categories[index];
                  return _CategoryCard(
                    category: category,
                    productCount: catalog
                        .productsInCategory(category.id)
                        .length,
                  );
                },
              ),
            ),
          ];
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.productCount});

  final ProductCategory category;
  final int productCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: '${category.name}، ${l10n.homeProductCount(productCount)}',
      excludeSemantics: true,
      child: Material(
        color: RawnqColors.surface,
        borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
          onTap: () => context.push(Routes.categoryPath(category.id)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
              boxShadow: kCardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(RawnqSpace.md),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: RawnqColors.cream,
                      borderRadius: BorderRadius.circular(RawnqSpace.radiusSm),
                    ),
                    padding: const EdgeInsets.all(RawnqSpace.sm),
                    child: ProductImage(
                      url: category.imageUrl,
                      fit: BoxFit.contain,
                      decodeWidth: 200,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  const SizedBox(width: RawnqSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(category.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          l10n.homeProductCount(productCount),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: RawnqColors.brown,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (category.description != null) ...<Widget>[
                          const SizedBox(height: RawnqSpace.xs),
                          Text(
                            category.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_left_rounded,
                    color: RawnqColors.inkSoft,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
