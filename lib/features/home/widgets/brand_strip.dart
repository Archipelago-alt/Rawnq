import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/product_image.dart';
import '../../../shared/models/category.dart';

/// "تسوّقي حسب العلامة التجارية" — the brand rail the live storefront shows.
class BrandStrip extends StatelessWidget {
  const BrandStrip({super.key, required this.brands});

  final List<Brand> brands;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: RawnqSpace.lg),
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(width: RawnqSpace.md),
        itemBuilder: (context, index) {
          final brand = brands[index];
          return Semantics(
            button: true,
            label: brand.name,
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
              onTap: () => context.push(Routes.brandPath(brand.id)),
              child: Container(
                width: 132,
                padding: const EdgeInsets.all(RawnqSpace.md),
                decoration: BoxDecoration(
                  color: RawnqColors.surface,
                  borderRadius: BorderRadius.circular(RawnqSpace.radiusMd),
                  border: Border.all(color: RawnqColors.line),
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: ProductImage(
                        url: brand.logoUrl,
                        fit: BoxFit.contain,
                        decodeWidth: 120,
                        borderRadius: BorderRadius.circular(RawnqSpace.radiusSm),
                      ),
                    ),
                    const SizedBox(width: RawnqSpace.sm),
                    Expanded(
                      child: Text(
                        brand.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
