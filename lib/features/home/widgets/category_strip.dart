import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/product_image.dart';
import '../../../shared/models/category.dart';

/// Horizontal category picker on the home screen.
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({super.key, required this.categories});

  final List<ProductCategory> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: RawnqSpace.lg),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: RawnqSpace.md),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryChip(category: category);
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final ProductCategory category;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: category.name,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
        onTap: () => context.push(Routes.categoryPath(category.id)),
        child: SizedBox(
          width: 92,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 78,
                height: 78,
                decoration: const BoxDecoration(
                  color: RawnqColors.cream,
                  shape: BoxShape.circle,
                  boxShadow: kCardShadow,
                ),
                padding: const EdgeInsets.all(RawnqSpace.sm),
                child: ClipOval(
                  child: ProductImage(
                    url: category.imageUrl,
                    fit: BoxFit.contain,
                    decodeWidth: 160,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              const SizedBox(height: RawnqSpace.sm),
              Text(
                category.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
