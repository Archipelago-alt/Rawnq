import 'package:flutter_test/flutter_test.dart';
import 'package:rawnq/features/products/product_filters.dart';

import '../support/fixtures.dart';

void main() {
  final products = Fixtures.catalog().products;

  test('no filter returns everything in the shop\'s own order', () {
    const filter = ProductFilter();

    final result = filter.apply(products);

    expect(result, hasLength(4));
    expect(result.first.id, Fixtures.shirtNoVariants.id); // sort_order 0
  });

  test('category narrows the list', () {
    final result = ProductFilter(categoryId: Fixtures.pyjamas.id).apply(products);

    expect(result.map((p) => p.id), <String>[Fixtures.pyjamaWithSizes.id]);
  });

  test('brand narrows the list', () {
    final result = ProductFilter(brandId: Fixtures.lubna.id).apply(products);

    expect(result.map((p) => p.id), <String>[Fixtures.pyjamaWithSizes.id]);
  });

  test('only-available hides sold-out products', () {
    const filter = ProductFilter(onlyAvailable: true);

    final result = filter.apply(products);

    expect(result.map((p) => p.id), isNot(contains(Fixtures.soldOut.id)));
    expect(result, hasLength(3));
  });

  test('only-new keeps products the shop labelled new', () {
    const filter = ProductFilter(onlyNew: true);

    expect(filter.apply(products).map((p) => p.id),
        <String>[Fixtures.pyjamaWithSizes.id]);
  });

  test('the query matches product names with Arabic normalisation', () {
    const filter = ProductFilter(query: 'بجامه');

    expect(filter.apply(products).map((p) => p.id),
        <String>[Fixtures.pyjamaWithSizes.id]);
  });

  test('the query also matches variant colour names', () {
    const filter = ProductFilter(query: 'sand');

    expect(filter.apply(products).map((p) => p.id),
        <String>[Fixtures.pyjamaWithSizes.id]);
  });

  test('price sorting works in both directions', () {
    expect(
      const ProductFilter(sort: ProductSort.priceAsc).apply(products).first.displayPrice,
      40,
    );
    expect(
      const ProductFilter(sort: ProductSort.priceDesc).apply(products).first.displayPrice,
      100,
    );
  });

  test('filters combine', () {
    const filter = ProductFilter(onlyAvailable: true, sort: ProductSort.priceAsc);

    final result = filter.apply(products);

    expect(result.first.displayPrice, 40);
    expect(result.map((p) => p.id), isNot(contains(Fixtures.soldOut.id)));
  });

  test('reset keeps the screen scope but drops refinements', () {
    const filter = ProductFilter(
      categoryId: 'cat-1',
      query: 'قميص',
      brandId: 'brand-1',
      onlyNew: true,
      sort: ProductSort.priceDesc,
    );

    final reset = filter.reset();

    expect(reset.categoryId, 'cat-1');
    expect(reset.query, 'قميص');
    expect(reset.brandId, isNull);
    expect(reset.onlyNew, isFalse);
    expect(reset.sort, ProductSort.defaultOrder);
    expect(reset.hasActiveRefinements, isFalse);
  });

  test('the refinement count drives the filter badge', () {
    expect(const ProductFilter().activeRefinementCount, 0);
    expect(
      const ProductFilter(onlyNew: true, sort: ProductSort.priceAsc)
          .activeRefinementCount,
      2,
    );
  });
}
